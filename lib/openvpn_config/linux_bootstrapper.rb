module OpenvpnConfig

require 'util/ssh'
require 'openvpn_config/bootstrap'

class LinuxBootstrapper

	attr_accessor :external_ip_addr
	@ssh_as_user=""
	@ssh_identity_file="" #defaults to ~/.ssh/id_rsa

	include OpenvpnConfig::Bootstrap

	def initialize(external_ip_addr, ssh_as_user="root", ssh_identity_file="#{ENV['HOME']}/.ssh/id_rsa")
		@external_ip_addr=external_ip_addr
		@ssh_as_user=ssh_as_user
		@ssh_identity_file=ssh_identity_file
	end

end

end
