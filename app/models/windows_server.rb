require 'logger'
require 'async_exec'
require 'openvpn_config/server'
require 'openvpn_config/client'
require 'util/ssh'
require 'util/cert_util'
require 'timeout'

class WindowsServer < Server

	validates_inclusion_of :flavor_id, :in => 3..7, :message => "Windows servers must use a flavor of 1 Gig or greater."

	include Util::CertUtil

	validate :handle_validate
	def handle_validate

		if openvpn_server then
			errors[:base] << "Windows is not currently supported as an OpenVPN server."
		end

	end

	def create_openvpn_server
		fail_and_raise "Windows is not currently supported as an OpenVPN server."
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

		AsyncExec.run_job(CreateVPNCredentials, self.id)

	end

	# this method currently requires Unix
	# TODO: support running this on Windows w/ Putty.exe
	def create_vpn_credentials

		vpn_server=Server.find(:first, :conditions => ["server_group_id = ? AND openvpn_server = ?", self.server_group_id, 1])

		vpn_server_config=OpenvpnConfig::Server.new(vpn_server.external_ip_addr, vpn_server.internal_ip_addr, self.server_group.domain_name, vpn_server.server_group.vpn_network, vpn_server.server_group.vpn_subnet, vpn_server.server_group.vpn_device, vpn_server.server_group.vpn_proto, "root", self.server_group.ssh_key_basepath)

		client=OpenvpnConfig::Client.new(vpn_server_config)
		vpn_creds=nil
		self.vpn_network_interfaces.each_with_index do |vni, index|
			client_name = (index == 0) ? self.name : "#{self.name}-#{index.to_s}"
			vpn_creds=client.create_client_credentials(client_name, vni.vpn_ip_addr, vni.ptp_ip_addr, "windows")
		end

		return [vpn_creds[0], tail_cert(vpn_creds[1]), vpn_creds[2]]

	end

	def configure_openvpn_client(client_key, client_cert, ca_cert)

		vpn_server=Server.find(:first, :conditions => ["server_group_id = ? AND openvpn_server = ?", self.server_group_id, true])
		begin

			script = ("cd c:\\ \n")

			# client key
			client_key.each_line do |line|	
				script += ("ECHO #{line.chomp} >> client.key\n")
			end

			# client cert
			script += ("\n")
			client_cert.each_line do |line|	
				script += ("ECHO #{line.chomp} >> client.crt\n")
			end

			# cat cert
			script += ("\n")
			ca_cert.each_line do |line|	
				script += ("ECHO #{line.chomp} >> ca.crt\n")
			end

			post_install_cmd = ""
			if self.server_command then
				post_install_cmd = self.server_command.command
			end

			script += IO.read(File.join(Rails.root, 'lib', 'openvpn_config', 'windows_download.bat'))

			script += %{
			cd c:\\

			certutil -addstore "TrustedPublisher" c:\\openvpn.cer
			openvpn-install.exe /S

			del c:\\openvpn.cer
			del c:\\openvpn-install.exe

			ECHO client > c:\\client.ovpn
			ECHO dev #{vpn_server.server_group.vpn_device} >> c:\\client.ovpn
			ECHO proto #{vpn_server.server_group.vpn_proto} >> c:\\client.ovpn
			ECHO remote #{vpn_server.internal_ip_addr} 1194 >> c:\\client.ovpn
			ECHO resolv-retry infinite >> c:\\client.ovpn
			ECHO nobind >> c:\\client.ovpn
			ECHO persist-key >> c:\\client.ovpn
			ECHO persist-tun >> c:\\client.ovpn
			ECHO ca ca.crt >> c:\\client.ovpn
			ECHO cert client.crt >> c:\\client.ovpn
			ECHO key client.key >> c:\\client.ovpn
			ECHO ns-cert-type server >> c:\\client.ovpn
			ECHO comp-lzo >> c:\\client.ovpn
			ECHO verb 3 >> c:\\client.ovpn
			ECHO up up.bat >> c:\\client.ovpn
			ECHO up-delay >> c:\\client.ovpn
			ECHO script-security 2 >> c:\\client.ovpn

			ECHO c:\\windows\\System32\\netsh.exe interface SET interface "public" DISABLED > c:\\up.bat
			ECHO IF ERRORLEVEL 1 c:\\windows\\System32\\netsh.exe interface SET interface "Local Area Connection" DISABLED >> c:\\up.bat

			IF EXIST c:\\progra~2\\openvpn move client.key c:\\progra~2\\openvpn\\config

			IF EXIST c:\\progra~2\\openvpn move client.crt c:\\progra~2\\openvpn\\config

			IF EXIST c:\\progra~2\\openvpn move ca.crt c:\\progra~2\\openvpn\\config

			IF EXIST c:\\progra~2\\openvpn move client.ovpn c:\\progra~2\\openvpn\\config

			IF EXIST c:\\progra~2\\openvpn move up.bat c:\\progra~2\\openvpn\\config
			sc config OpenVPNService start= auto

			netdom COMPUTERNAME localhost /Add:#{self.name}.#{self.server_group.domain_name}
			netdom COMPUTERNAME localhost /MakePrimary:#{self.name}.#{self.server_group.domain_name}

			#{post_install_cmd}

			netdom RENAMECOMPUTER localhost /NewName: #{self.name} /Force /Reboot 5
			}

			if Util::Psexec.run_bat_script(:script => script, :password => self.admin_password, :ip => self.external_ip_addr, :flags => "-s -c -f -i 1") then
				self.status = "Online"
				save
			else
				fail_and_raise "Failed to install OpenVPN."
			end

		rescue Exception => e
			if self.retry_count <= 3 then
				self.status = "Pending"
				self.retry_count += 1
				self.save
				AsyncExec.run_job(ConfigureWindowsVPNClient, self.id, client_key, client_cert, ca_cert)
			end
		end
	
	end

	# method to block until a server is online
	def loop_until_server_online
		conn = self.account_connection

		error_message = "Failed to build server."

		timeout = self.windows_server_online_timeout-(Time.now-self.updated_at).to_i
		timeout = 2000 if self.image_id == 58 # FIXME remove this when image customization support and settings are added
		timeout = 120 if timeout < 120

		begin
			Timeout::timeout(timeout) do

				# poll the server until progress is 100%
				cs = conn.get_server(self.cloud_server_id_number)
				until cs[:progress] == 100 and cs[:status] == "ACTIVE" do
					cs = conn.get_server(self.cloud_server_id_number)
					sleep 1
				end

				error_message="Failed to psexec to the node."	

				count=0

				while not Util::Psexec.run_bat_script(:script => "cmd /c echo yo", :password => self.admin_password, :ip => self.external_ip_addr) do
					count+=1
					sleep 15
					if count > 23 then
						fail_and_raise error_message
					end
				end

			end
		rescue Exception => e
			fail_and_raise error_message
		end

	end
	
	def ping_test(test_ip)

		begin
			Timeout::timeout(30) do

				if Util::Psexec.run_bat_script(:script => "ping -n 1 #{test_ip}", :password => self.admin_password, :ip => self.external_ip_addr, :flags => "-i -h -c -f") then
					return true
				end

			end
		rescue Exception => e
		end

		return false

	end

    def capture_reserve_server
		return false
	end

	private
	def generate_personalities
		{}
	end

end
