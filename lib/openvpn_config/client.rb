module OpenvpnConfig

require 'util/ssh'
require 'openvpn_config/bootstrap'

class Client

	@server=nil
	@logger=nil
	@hostname=nil

	include OpenvpnConfig::Bootstrap

	def initialize(server)
		@server=server	
	end

	def logger=(logger)
		@logger=logger
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

end

end
