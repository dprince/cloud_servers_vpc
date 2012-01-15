require 'logger'
require 'async_exec'
require 'openvpn_config/server'
require 'openvpn_config/client'
require 'util/ssh'
require 'timeout'
require 'tempfile'

class LinuxServer < Server

	# Configure this cloud server as a VPN Server and schedule any client
	# instances to get created.
	def create_openvpn_server

		return if self.status == "Online"

		begin
			loop_until_server_online
		rescue Exception => e
			if self.retry_count <= 3 then
				self.retry_count += 1
				self.status = "Pending" # keep status set to pending
				save!
				# delete the existing cloud server instance
				if not self.cloud_server_id_number.nil? then
					delete_cloud_server(self.cloud_server_id_number)
				end
				sleep 10
				AsyncExec.run_job(CreateCloudServer, self.id, false)
				return
			end
		end

		vpn_server=OpenvpnConfig::Server.new(self.external_ip_addr, self.internal_ip_addr, self.server_group.domain_name, self.server_group.vpn_network, self.server_group.vpn_subnet, self.server_group.vpn_device, self.server_group.vpn_proto, "root", self.server_group.ssh_key_basepath)
		vpn_server.logger=Rails.logger
		vpn_server.install_openvpn
		if vpn_server.configure_vpn_server(self.name) then

			if self.server_command then
				if not Util::Ssh.run_cmd(self.external_ip_addr, self.server_command.command, "root", self.server_group.ssh_key_basepath)
					fail_and_raise "Failed to run post install command."
				end
			end

			self.status = "Online"
			save

			Server.find(:all, :conditions => ["server_group_id = ? AND openvpn_server = ?", self.server_group_id, false]).each do |server|
				Server.create_vpn_client_for_type(server)
			end
			Client.find(:all, :conditions => ["server_group_id = ?", self.server_group_id]).each do |client|
                AsyncExec.run_job(CreateClientVPNCredentials, client.id)
			end
		else
			fail_and_raise "Failed to install OpenVPN on the server."
		end

	end

	# Configure this cloud server as a VPN client
	def create_openvpn_client

		return if self.status == "Online"

		vpn_server=Server.find(:first, :conditions => ["server_group_id = ? AND openvpn_server = ?", self.server_group_id, true])

		begin
			loop_until_server_online

			# server is online but can't ping OpenVPN servers .10 IP
			if not ping_test(vpn_server.internal_ip_addr) then
				self.account_connection.reboot_server(self.cloud_server_id_number)
				self.add_error_message("Server failed ping test.")
				self.retry_count += 1
				self.save
				sleep 20
                Server.create_vpn_client_for_type(self)
				return
			end

		rescue Exception => e
			if self.retry_count <= 3 then
				self.retry_count += 1
				self.status = "Pending" # keep status set to pending
				save!
				# delete the existing cloud server instance
				if not self.cloud_server_id_number.nil? then
					delete_cloud_server(self.cloud_server_id_number)
					self.cloud_server_id_number=nil
					save!
				end
				sleep 10
				AsyncExec.run_job(CreateCloudServer, self.id, true)
				return
			end
		end

		vpn_server_config=OpenvpnConfig::Server.new(vpn_server.external_ip_addr, vpn_server.internal_ip_addr, self.server_group.domain_name, vpn_server.server_group.vpn_network, vpn_server.server_group.vpn_subnet, vpn_server.server_group.vpn_device, vpn_server.server_group.vpn_proto, "root", self.server_group.ssh_key_basepath)

		client=OpenvpnConfig::LinuxClient.new(vpn_server_config, self.external_ip_addr, "root", self.server_group.ssh_key_basepath)
		client.logger=Rails.logger
		client.install_openvpn
		self.vpn_network_interfaces.each_with_index do |vni, index|
			client_name = (index == 0) ? self.name : "#{self.name}-#{index.to_s}"
			if not client.configure_client_vpn(client_name, vni.vpn_ip_addr, vni.ptp_ip_addr) then
				fail_and_raise "Failed to configure OpenVPN on the client."
			end
		end

		if self.server_command then
			if not Util::Ssh.run_cmd(self.external_ip_addr, self.server_command.command, "root", self.server_group.ssh_key_basepath)
				fail_and_raise "Failed to run post install command."
			end
		end

		if not client.start_openvpn then
			fail_and_raise "Failed to configure OpenVPN on the client."
		end

		# mark the client as online
		self.status = "Online"
		save
		
	end

	# method to block until a server is online
	def loop_until_server_online(private_key = self.server_group.ssh_key_basepath)
		conn = self.account_connection

		error_message = "Failed to build server."

		timeout = self.server_online_timeout-(Time.now-self.updated_at).to_i
		timeout = 120 if timeout < 120

		begin
			Timeout::timeout(timeout) do

				# poll the server until progress is 100%
				server = conn.get_server(self.cloud_server_id_number)
				until server[:progress] == 100 and server[:status] == "ACTIVE" do
					server = conn.get_server(self.cloud_server_id_number)
					raise "Server in error state." if server[:status] == 'ERROR'
					sleep 1
				end

				error_message="Failed to ssh to the node."	
				if ! system(%{

						COUNT=0
						while ! ssh -o "StrictHostKeyChecking no" -T -i #{private_key} root@#{server[:public_ip]} /bin/true > /dev/null 2>&1; do
							if (($COUNT > 23)); then
								exit 1
							fi
							((COUNT++))
							sleep 15
						done
						exit 0

				}) then
					fail_and_raise error_message
				end

			end
		rescue Exception => e
			fail_and_raise error_message
		end

	end
	
	def ping_test(test_ip)

		begin
			Timeout::timeout(30) do

				if system(%{
						ssh -o "StrictHostKeyChecking no" -T -i #{self.server_group.ssh_key_basepath} root@#{self.external_ip_addr} ping -c 1 #{test_ip} > /dev/null 2>&1
				}) then
					return true
				end

			end
		rescue Exception => e
		end

		return false

	end

	def capture_reserve_server

        private_key = nil

		ReserveServer.transaction do
			reserve_server = ReserveServer.where('account_id = ? AND image_ref = ? AND flavor_ref = ? AND status = ? AND historical = ?', self.account_id, self.image_id, self.flavor_id, 'Online', 0).lock(true).first 
            if reserve_server then

				self.cloud_server_id_number = reserve_server.cloud_server_id
				self.external_ip_addr = reserve_server.external_ip_addr
				self.internal_ip_addr = reserve_server.internal_ip_addr
				self.save

				reserve_server.historical = true;
				reserve_server.save!

				private_key = Tempfile.new "reservation_priv_key"
				private_key.chmod(0600)
				private_key.write(reserve_server.private_key)
				private_key.flush

            else
				return false
            end
		end
        
		# inject personalities into the group
		bash_command = ""
			generate_personalities.each_pair do |local_file, remote_dest|
			bash_command += "echo '#{IO.read(local_file)}' >> #{remote_dest}\n"
			bash_command += "chmod 600 #{remote_dest}\n"
		end

		begin
			Timeout::timeout(60) do
data=%x{
ssh -o "StrictHostKeyChecking no" -T -i #{private_key.path} root@#{self.external_ip_addr} bash <<-"EOF_BASH"
#{bash_command}
EOF_BASH
}
				retval=$?
				if not retval.success? then
					fail_and_raise "Failed to inject personalities into captured server."
				end

			end
		rescue Exception => e
			fail_and_raise "Timeout injecting personalities into captured server."
		end

        private_key.close(true)
		return true

	end

	# Generates a personalities hash suitable for use with bindings
	private
	def generate_personalities

		# server group keys
		auth_key_set=Set.new(self.server_group.ssh_public_keys.collect { |x| x.public_key.chomp })
		# user keys
		auth_key_set.merge(self.server_group.user.ssh_public_keys.collect { |x| x.public_key.chomp })

		# new lines
		authorized_keys=auth_key_set.inject("") { |sum, key| sum + key + "\n"}

		# add any keys from the config files
		if not ENV['AUTHORIZED_KEYS'].blank? then
			authorized_keys += ENV['AUTHORIZED_KEYS']
		end

		# write keys to a file
		authorized_keys += IO.read(self.server_group.ssh_key_basepath+".pub")
		tmp_auth_keys=Tempfile.new "cs_auth_keys"
		tmp_auth_keys.chmod(0600)
		tmp_auth_keys.write(authorized_keys)
		tmp_auth_keys.flush
		@tmp_files << tmp_auth_keys

		personalities={}
		personalities.store(tmp_auth_keys.path, "/root/.ssh/authorized_keys")
		personalities.store(File.join(Rails.root, 'config', 'root_ssh_config'), "/root/.ssh/config")
		
		return personalities

	end

end
