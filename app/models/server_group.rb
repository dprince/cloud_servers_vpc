require 'util/ip_validator'
require 'util/ip_incrementer'

class ServerGroup < ActiveRecord::Base

	include Util::IpValidator
	include Util::IpIncrementer
	include Util::SshKeygen

	validates_presence_of :name, :domain_name, :description, :vpn_network, :vpn_subnet, :last_used_ip_address, :owner_name, :user_id
	validates_length_of :name, :maximum => 255
	validates_length_of :description, :maximum => 255
	validates_length_of :owner_name, :maximum => 255
	validates_length_of :domain_name, :maximum => 255
	has_many :servers
    accepts_nested_attributes_for :servers, :update_only => true
	has_many :ssh_public_keys, :dependent => :destroy
	belongs_to :user

	validates_associated :servers
	validates_associated :ssh_public_keys

	def after_initialize
		if not self.last_used_ip_address.nil? then
			init_ip(self.last_used_ip_address)
		end

		if new_record? then
			self.historical = false
		end
	end

	def after_create
		generate_ssh_keypair(ssh_key_basepath)
	end

	def before_destroy
		FileUtils.rm_rf(self.ssh_key_basepath)
		FileUtils.rm_rf(self.ssh_key_basepath+".pub")
	end

	def before_validation_on_create
		if not vpn_network.nil? and is_valid_ip(vpn_network) then
			self.last_used_ip_address = self.vpn_network.chomp("0")+"2"
			init_ip(self.last_used_ip_address)
		end
	end

	def validate

		if not vpn_network.nil? and not is_valid_ip(vpn_network) then
			errors.add_to_base("Please specify a valid VPN network.")
		end

		if not vpn_subnet.nil? and not is_valid_ip(vpn_subnet) then
			errors.add_to_base("Please specify a valid VPN subnet.")
		end

		if not last_used_ip_address.nil? and not is_valid_ip(last_used_ip_address) then
			errors.add_to_base("Please specify a valid last used IP address.")
		end

		openvpn_server_count=0
		self.servers.each do |server|
			openvpn_server_count += 1 if server.openvpn_server
		end
		if openvpn_server_count > 1 then
			errors.add_to_base("Each server group cannot have more than one VPN Server.")
		end

	end

	def save_next_ip
		self.last_used_ip_address = next_ip
		save
		return self.last_used_ip_address
	end

	def ssh_key_basepath
		RAILS_ROOT+File::SEPARATOR+'tmp'+File::SEPARATOR+'ssh_keys'+File::SEPARATOR+RAILS_ENV+File::SEPARATOR+self.id.to_s
	end

	def make_historical
		self.servers.each do |server|
			server.make_historical
		end
	end

end
