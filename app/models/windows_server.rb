require 'logger'
require 'cloud_servers_util'
require 'openvpn_config/server'
require 'openvpn_config/client'
require 'util/ssh'
require 'timeout'

class WindowsServer < Server

	validates_inclusion_of :flavor_id, :in => 3..7, :message => "Windows servers must use a flavor of 1 Gig or greater."

	def validate

		if openvpn_server then
			errors.add_to_base("Windows is not currently supported as an OpenVPN server.")
		end

	end

	def create_openvpn_server
		fail_and_raise "Windows is not currently supported as an OpenVPN server."
	end

	# Configure this cloud server as a VPN client
	def create_openvpn_client

		return if self.status == "Online"

		ovpn_server_val=1
		# use 't' on SQLite
		if Server.connection.adapter_name =~ /SQLite/ then
			ovpn_server_val="t"
		end
		vpn_server=Server.find(:first, :conditions => ["server_group_id = ? AND openvpn_server = ?", self.server_group_id, ovpn_server_val])

		begin
			loop_until_server_online

			# server is online but can't ping OpenVPN servers .10 IP
			if not ping_test(vpn_server.internal_ip_addr) then
				cs_conn=self.cloud_server_init
				cs_conn.reboot_server(self.cloud_server_id_number)
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
				Resque.enqueue(CreateCloudServer, self.id, true)
				return
			end
		end

		Resque.enqueue(CreateVPNCredentials, self.id)

	end

	# this method currently requires Unix
	# TODO: support running this on Windows w/ Putty.exe
	def create_vpn_credentials

		vpn_server=Server.find(:first, :conditions => ["server_group_id = ? AND openvpn_server = ?", self.server_group_id, 1])

		vpn_server_config=OpenvpnConfig::Server.new(vpn_server.external_ip_addr, vpn_server.internal_ip_addr, self.server_group.domain_name, vpn_server.server_group.vpn_network, vpn_server.server_group.vpn_subnet, "root", self.server_group.ssh_key_basepath)

		client=OpenvpnConfig::Client.new(vpn_server_config, self.external_ip_addr, "root", self.server_group.ssh_key_basepath)
		vpn_creds=nil
		self.vpn_network_interfaces.each_with_index do |vni, index|
			client_name = (index == 0) ? self.name : "#{self.name}-#{index.to_s}"
			vpn_creds=client.create_client_credentials(client_name, vni.vpn_ip_addr, vni.ptp_ip_addr)
		end

		return [vpn_creds[0], tail_cert(vpn_creds[1]), vpn_creds[2]]

	end

	def configure_openvpn_client(client_key, client_cert, ca_cert)

		ovpn_server_val=1
		# use 't' on SQLite
		if Server.connection.adapter_name =~ /SQLite/ then
			ovpn_server_val="t"
		end
		vpn_server=Server.find(:first, :conditions => ["server_group_id = ? AND openvpn_server = ?", self.server_group_id, ovpn_server_val])
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

			script += IO.read(File.join(RAILS_ROOT, 'lib', 'openvpn_config', 'windows_download.bat'))

			script += %{
			cd c:\\

			certutil -addstore "TrustedPublisher" c:\\openvpn.cer
			openvpn-install.exe /S

			ECHO client > c:\\client.ovpn
			ECHO dev tun >> c:\\client.ovpn
			ECHO proto tcp >> c:\\client.ovpn
			ECHO remote #{vpn_server.internal_ip_addr} 1194 >> c:\\client.ovpn
			ECHO resolv-retry ininite >> c:\\client.ovpn
			ECHO nobind >> c:\\client.ovpn
			ECHO persist-key >> c:\\client.ovpn
			ECHO persist-tun >> c:\\client.ovpn
			ECHO ca ca.crt >> c:\\client.ovpn
			ECHO cert client.crt >> c:\\client.ovpn
			ECHO key client.key >> c:\\client.ovpn
			ECHO ns-cert-type server >> c:\\client.ovpn
			ECHO comp-lzo >> c:\\client.ovpn
			ECHO verb 3 >> c:\\client.ovpn

			IF EXIST c:\\progra~1\\openvpn move client.key c:\\progra~1\\openvpn\\config
			IF EXIST c:\\progra~2\\openvpn move client.key c:\\progra~2\\openvpn\\config

			IF EXIST c:\\progra~1\\openvpn move client.crt c:\\progra~1\\openvpn\\config
			IF EXIST c:\\progra~2\\openvpn move client.crt c:\\progra~2\\openvpn\\config

			IF EXIST c:\\progra~1\\openvpn move ca.crt c:\\progra~1\\openvpn\\config
			IF EXIST c:\\progra~2\\openvpn move ca.crt c:\\progra~2\\openvpn\\config
			IF EXIST c:\\progra~1\\openvpn move client.ovpn c:\\progra~1\\openvpn\\config
			IF EXIST c:\\progra~2\\openvpn move client.ovpn c:\\progra~2\\openvpn\\config
			net start OpenVPNService
			REM FIXME netssh interface SET interface "Local Area Connection" DISABLED
			sc config OpenVPNService start= auto
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
				Resque.enqueue(ConfigureWindowsVPNClient, self.id, client_key, client_cert, ca_cert)
			end
		end
	
	end

	# method to block until a server is online
	def loop_until_server_online
		cs_conn=self.cloud_server_init

		error_message="Failed to build server."

		timeout=self.windows_server_online_timeout-(Time.now-self.updated_at).to_i
		timeout = 120 if timeout < 120

		begin
			Timeout::timeout(timeout) do

				# poll the server until progress is 100%
				cs=cs_conn.find_server("#{self.cloud_server_id_number}")
				until cs.progress == 100 and cs.status == "ACTIVE" do
					cs=cs_conn.find_server("#{self.cloud_server_id_number}")
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

	private
	def tail_cert(raw_cert)
		new_cert=""
		begin_cert=false
		raw_cert.each_line do |line|
			begin_cert = true if line =~ /-----BEGIN CERTIFICATE-----/
			new_cert += "#{line}\n" if begin_cert
		end
	end

	private
	def generate_personalities
		{}
	end

end
