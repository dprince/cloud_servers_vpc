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
	def loop_until_server_online
		conn = self.account_connection

		error_message = "Failed to build server."

		timeout = self.server_online_timeout-(Time.now-self.updated_at).to_i
		timeout = 120 if timeout < 120

		begin
			Timeout::timeout(timeout) do

				# poll the server until progress is 100%
				cs = conn.get_server(self.cloud_server_id_number)
				until cs[:progress] == 100 and cs[:status] == "ACTIVE" do
					cs = conn.get_server(self.cloud_server_id_number)
					sleep 1
				end

				error_message="Failed to ssh to the node."	

				if ! system(%{

						COUNT=0
						while ! ssh -o "StrictHostKeyChecking no" -T -i #{self.server_group.ssh_key_basepath} root@#{cs[:public_ip]} /bin/true > /dev/null 2>&1; do
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

	# Generates a personalities hash (See Cloud Servers API docs for details)
	private
	def generate_personalities

		auth_key_set=Set.new(self.server_group.ssh_public_keys.collect { |x| x.public_key.chomp })
		auth_key_set.merge(self.server_group.user.ssh_public_keys.collect { |x| x.public_key.chomp })

		# add keys from the Server Group (added via XML API)
		authorized_keys=auth_key_set.inject("") { |sum, key| sum + key + "\n"}

		# add any keys from the config files	
		if not ENV['CC_AUTHORIZED_KEYS'].blank? then
			authorized_keys += ENV['CC_AUTHORIZED_KEYS']
		end

		# append the public key from the ServerGroup
		authorized_keys += IO.read(self.server_group.ssh_key_basepath+".pub")
		tmp_auth_keys=Tempfile.new "cs_auth_keys"
		tmp_auth_keys.chmod(0600)
		tmp_auth_keys.write(authorized_keys)
		tmp_auth_keys.flush
		@tmp_files << tmp_auth_keys

		personalities={}
		personalities.store(tmp_auth_keys.path, "/root/.ssh/authorized_keys")
		personalities.store(File.join(Rails.root, 'config', 'root_ssh_config'), "/root/.ssh/config")
		
		# create a .rackspace_cloud file with username/password info
		cloud_key_config=%{
userid: #{ENV['RACKSPACE_CLOUD_USERNAME']}
api_key: #{ENV['RACKSPACE_CLOUD_API_KEY']}
		}
		tmp_cloud_key=Tempfile.new "cs_cloud_keys"
		tmp_cloud_key.chmod(0600)
		tmp_cloud_key.write(cloud_key_config)
		tmp_cloud_key.flush
		@tmp_files << tmp_cloud_key
		personalities.store(tmp_cloud_key.path, "/root/.rackspace_cloud")

		return personalities

	end

end
