module OpenvpnConfig

require 'util/ssh'
require 'openvpn_config/bootstrap'

class LinuxClient

	attr_accessor :external_ip_addr
	@server=nil
	@ssh_as_user=""
	@ssh_identity_file="" #defaults to ~/.ssh/id_rsa
	@logger=nil
	@hostname=nil

	include OpenvpnConfig::Bootstrap

	def initialize(server, external_ip_addr, ssh_as_user="root", ssh_identity_file="#{ENV['HOME']}/.ssh/id_rsa")
		@server=server	
		@external_ip_addr=external_ip_addr
		@ssh_as_user=ssh_as_user
		@ssh_identity_file=ssh_identity_file
	end

	def logger=(logger)
		@logger=logger
	end

	# It is the job of the caller to track and ensure unique IP's get
	# used for the internal_vpn_ip and pptp_vpn_ip options.
	def configure_client_vpn(client_hostname, internal_vpn_ip, pptp_vpn_ip, client_type="linux")
		@hostname=client_hostname

		# on the server we'll generate a new client cert
		tmp_cert=@server.add_vpn_client(client_hostname, internal_vpn_ip, pptp_vpn_ip, client_type)
		# scp the client cert to the client machine	
		retval=system("scp -o 'StrictHostKeyChecking no' -i \"#{@ssh_identity_file}\" #{tmp_cert} #{@ssh_as_user}@#{@external_ip_addr}:/etc/openvpn/cert.tar.gz")
		File.delete(tmp_cert) if File.exists?(tmp_cert)

		if not retval then

			@logger.error("Failed to copy cert to client.")
			return false

		end

		script = <<-SCRIPT_EOF
			mkdir -p /etc/openvpn/
			cd /etc/openvpn/
			tar xzf /etc/openvpn/cert.tar.gz
			OPENVPN_DEVICE=#{@server.vpn_device}
			OPENVPN_PROTO=#{@server.vpn_proto}
			#{IO.read(File.join(File.dirname(__FILE__), "client_functions.bash"))}
			init_client_etc_hosts '#{client_hostname}' '#{@server.domain_name}' '#{internal_vpn_ip}'
			create_client_config #{@server.internal_ip_addr} #{@server.vpn_ipaddr} #{client_hostname} #{@server.domain_name}
		SCRIPT_EOF
		return Util::Ssh.run_cmd(@external_ip_addr, script, @ssh_as_user, @ssh_identity_file, @logger)

	end

	def create_client_credentials(client_hostname, internal_vpn_ip, pptp_vpn_ip, client_type="linux")

		@hostname=client_hostname

		# on the server we'll generate a new client cert
		tmp_cert=@server.add_vpn_client(client_hostname, internal_vpn_ip, pptp_vpn_ip, client_type)
		tmp_dir=Util::TmpDir.tmp_dir

		system("cd #{tmp_dir}; tar xf #{tmp_cert}") or return false

		client_key=%x{cat #{tmp_dir}/#{client_hostname}.key}
		client_crt=%x{cat #{tmp_dir}/#{client_hostname}.crt}
		ca_crt=%x{cat #{tmp_dir}/ca.crt}

		if block_given? then
			yield client_key, client_crt, ca_crt
		else
			return [client_key, client_crt, ca_crt]
		end

	end

	def start_openvpn

		script = "/sbin/chkconfig openvpn on\n/etc/init.d/openvpn start || systemctl start openvpn@#{@hostname}.service\n"
		if Util::Ssh.run_cmd(@external_ip_addr, script, @ssh_as_user, @ssh_identity_file, @logger) then
			if_down_count=0
			1.upto(5) do
				break if @server.if_down_eth0_client(@hostname)
				if_down_count+=1
			end
			return true if if_down_count < 5
		end
		return false

	end

end

end
