module OpenvpnConfig

require 'ipaddr'
require 'tempfile'
require 'util/ssh'
require 'openvpn_config/bootstrap'

class Server

	@client_num=nil
	@ssh_as_user="" #defaults to root
	@ssh_identity_file="" #defaults to ~/.ssh/id_rsa
	@logger=nil

	attr_accessor :external_ip_addr #cloud servers eth0 external IP
	attr_accessor :internal_ip_addr #cloud servers eth1 10. IP (internal)
	attr_accessor :vpn_network
	attr_accessor :vpn_subnet
	attr_accessor :vpn_device
	attr_accessor :vpn_proto
	attr_accessor :domain_name

	include OpenvpnConfig::Bootstrap

	def logger=(logger)
		@logger=logger
	end

	def initialize(external_ip_addr, internal_ip_addr, domain_name="vpc", vpn_network="172.19.0.0", vpn_subnet="255.255.128.0", vpn_device="tun", vpn_proto="tcp", ssh_as_user="root", ssh_identity_file="#{ENV['HOME']}/.ssh/id_rsa")
		@external_ip_addr=external_ip_addr
		@internal_ip_addr=internal_ip_addr
		@domain_name=domain_name
		@vpn_network=vpn_network
		@vpn_subnet=vpn_subnet
		@vpn_device=vpn_device
		@vpn_proto=vpn_proto
		@ssh_as_user=ssh_as_user
		@ssh_identity_file=ssh_identity_file

	end

	def vpn_ipaddr
		
		#server itself will take the  ".1" on the vpn_network
		return vpn_network.chomp("0")+"1"

	end

	def init_client_num(client_num=0)
		@client_num=client_num
	end

	def next_client_num
		init_client_num if @client_num.nil?
		return (@client_num+=1)
	end

	def configure_vpn_server(hostname)

		script=<<-SCRIPT_EOF
			OPENVPN_DEVICE=#{@vpn_device}
			OPENVPN_PROTO=#{@vpn_proto}
			#{IO.read(File.join(File.dirname(__FILE__), "server_functions.bash"))}
			cat > /root/.ssh/id_rsa <<-"EOF_CAT"
			#{IO.read(@ssh_identity_file)}
			EOF_CAT
			chmod 600 /root/.ssh/id_rsa
			/etc/init.d/openvpn stop || systemctl stop openvpn@server.service
			clean
			create_ca '#{hostname}'
			create_server_key '#{hostname}'
			create_server_config '#{hostname}' '#{@vpn_network}' '#{@vpn_subnet}'
			init_server_etc_hosts '#{hostname}' '#{@domain_name}' '#{self.vpn_ipaddr}'
			configure_iptables
			start_dns_server
			/etc/init.d/openvpn start || systemctl restart openvpn@server.service
			/sbin/chkconfig openvpn on

			if [ -f /etc/redhat-release ]; then
				/sbin/service iptables restart
			elif [ -f /etc/debian_version ]; then
				/sbin/iptables-restore < /etc/iptables.rules
				cat > /etc/network/if-pre-up.d/iptables <<-"EOF_CAT"
					/sbin/iptables-restore < /etc/iptables.rules
				EOF_CAT
				chmod 755 /etc/network/if-pre-up.d/iptables
			else
				echo "Failed to start iptables."
				exit 1
			fi

		SCRIPT_EOF
		return Util::Ssh.run_cmd(@external_ip_addr, script, @ssh_as_user, @ssh_identity_file, @logger)

	end

	def add_vpn_client(client_hostname, client_ip, client_ptp_ip, type="linux")

		script = "OPENVPN_DEVICE=#{@vpn_device}\n"
		script += "OPENVPN_PROTO=#{@vpn_proto}\n"
		script += IO.read(File.join(File.dirname(__FILE__), "server_functions.bash"))
		script += "create_client_key '#{client_hostname}' '#{@domain_name}' '#{client_ip}' '#{client_ptp_ip}' '#{type}' '#{self.vpn_ipaddr}' '#{self.vpn_subnet}'\n"
		Util::Ssh.run_cmd(@external_ip_addr, script, @ssh_as_user, @ssh_identity_file, @logger)
		#Copy the client cert to a local temp file and return its location
		return download_client_cert(client_hostname)

	end

	def if_down_eth0_client(client_hostname)

		script = "ssh #{client_hostname} /sbin/ifconfig eth0 down"
		Util::Ssh.run_cmd(@external_ip_addr, script, @ssh_as_user, @ssh_identity_file, @logger)

	end

	private
	#create a temp file on the local system and download the client cert
	def download_client_cert(client_name)

		tmp_file=Tempfile.new "cert"
		path="#{tmp_file.path}.tar.gz"
		tmp_file.close(true)
		%x{scp -o "StrictHostKeyChecking no" -i \"#{@ssh_identity_file}\" #{@ssh_as_user}@#{@external_ip_addr}:/etc/openvpn/keys/#{client_name}.tar.gz #{path}}
		return path

	end

end

end
