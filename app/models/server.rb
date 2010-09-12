require 'logger'
require 'cloud_servers_util'
require 'openvpn_config/server'
require 'openvpn_config/client'
require 'util/ssh'
require 'timeout'
require 'tempfile'

class Server < ActiveRecord::Base

    cattr_accessor :server_online_timeout
	self.server_online_timeout = 360

	attr_accessor :num_vpn_network_interfaces

	belongs_to :server_group
	belongs_to :account
	validates_presence_of :name, :description, :flavor_id, :image_id, :server_group_id, :account_id
	validates_numericality_of :flavor_id, :image_id, :server_group_id
	validates_numericality_of :cloud_server_id_number, :if => :cloud_server_id_number
	validates_uniqueness_of :name, :scope => :server_group_id
	has_many :vpn_network_interfaces, :dependent => :destroy
	has_many :server_errors
	validates_format_of :name, :with => /^[A-Za-z0-9-]+$/, :message => "Server name must use valid hostname characters (A-Z, a-z, 0-9, dash)."
	validates_length_of :name, :maximum => 255
	validates_length_of :description, :maximum => 255

    def after_initialize
        if new_record? then
            self.historical = false
        end
		@tmp_files=[]
    end

	def after_create

		if self.openvpn_server then
			self.num_vpn_network_interfaces=0
		elsif self.num_vpn_network_interfaces.nil?
			self.num_vpn_network_interfaces=1
		end

		self.num_vpn_network_interfaces.to_i.times do |i|
			VpnNetworkInterface.create(
				:vpn_ip_addr => self.server_group.save_next_ip,
				:ptp_ip_addr => self.server_group.save_next_ip,
				:server_id => self.id
			)
		end

		create_cloud_server

	end

	def make_historical
		if not self.cloud_server_id_number.nil? then
			delete_cloud_server(self.cloud_server_id_number)
		end
		update_attribute(:historical, true)
	end

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
				create_cloud_server
				return
			end
		end

		vpn_server=OpenvpnConfig::Server.new(self.external_ip_addr, self.internal_ip_addr, self.server_group.domain_name, self.server_group.vpn_network, self.server_group.vpn_subnet, "root", self.server_group.ssh_key_basepath)
		vpn_server.logger=Logger.new(STDOUT)
		vpn_server.install_openvpn
		if vpn_server.configure_vpn_server(self.name) then
			self.status = "Online"
			save

			ovpn_server_val=0
			# use 'f' on SQLite
			if Server.connection.adapter_name =~ /SQLite/ then
				ovpn_server_val="f"
			end
			Server.find(:all, :conditions => ["server_group_id = ? AND openvpn_server = ?", self.server_group_id, ovpn_server_val]).each do |vpn_client|
				vpn_client.create_openvpn_client
			end
		else
			fail_and_raise "Failed to install OpenVPN on the server."
		end

	end
	handle_asynchronously :create_openvpn_server

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
				create_openvpn_client
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
				create_cloud_server(true)
				return
			end
		end

		vpn_server_config=OpenvpnConfig::Server.new(vpn_server.external_ip_addr, vpn_server.internal_ip_addr, self.server_group.domain_name, vpn_server.server_group.vpn_network, vpn_server.server_group.vpn_subnet, "root", self.server_group.ssh_key_basepath)

		client=OpenvpnConfig::Client.new(vpn_server_config, self.external_ip_addr, "root", self.server_group.ssh_key_basepath)
		client.logger=Logger.new(STDOUT)
		client.install_openvpn
		self.vpn_network_interfaces.each_with_index do |vni, index|
			client_name = (index == 0) ? self.name : "#{self.name}-#{index.to_s}"
			if not client.configure_client_vpn(client_name, vni.vpn_ip_addr, vni.ptp_ip_addr) then
				fail_and_raise "Failed to configure OpenVPN on the client."
			end
		end
		if not client.start_openvpn then
			fail_and_raise "Failed to configure OpenVPN on the client."
		end

		# mark the client as online
		self.status = "Online"
		save
		
	end
	handle_asynchronously :create_openvpn_client

	def create_cloud_server(schedule_client_openvpn=false)

		return if self.status == "Online"
		if self.retry_count >= 3 then
			self.status = "Failed"
			save
			return
		end

		begin
			server_name_prefix=""
			if not ENV['RACKSPACE_CLOUD_SERVER_NAME_PREFIX'].blank? then
				server_name_prefix=ENV['RACKSPACE_CLOUD_SERVER_NAME_PREFIX']
			end
			
			cs_conn=self.cloud_server_init

			retry_suffix=self.retry_count > 0 ? "#{rand(10)}-#{self.retry_count}" : "#{rand(10)}"
			cs=cs_conn.create_cloud_server("#{server_name_prefix}#{self.name}-#{self.server_group_id}-#{retry_suffix}", self.image_id, self.flavor_id, generate_personalities(self.openvpn_server))
			@tmp_files.each {|f| f.close(true)} #Remove tmp personalities files
			#harvest server ID and IP information
			self.cloud_server_id_number = cs.id
			self.external_ip_addr = cs.addresses[:public][0]
			self.internal_ip_addr = cs.addresses[:private][0]
			save!
	
			# if this server is an OpenVPN server create it now
			if self.openvpn_server then
				create_openvpn_server
			else
				if schedule_client_openvpn then
					create_openvpn_client
				end
			end

		rescue Exception => e
			self.retry_count += 1
			self.status = "Pending" # keep status set to pending

			long_error_message=nil
			begin
				long_error_message="#{e.inspect}: #{e.http_body}"
			rescue
			end

			if e and e.message and long_error_message then
				self.add_error_message("Failed to create cloud server: #{e.message}", long_error_message)
			elsif e and e.message then
				self.add_error_message("Failed to create cloud server: #{e.message}")
			else
				self.add_error_message("Failed to create cloud server.")
			end
			save!
			sleep 10
			create_cloud_server
		end

	end
	handle_asynchronously :create_cloud_server

	# class level function to delete cloud servers by their cloud_server ID's
	def delete_cloud_server(cloud_server_id)
		deleted=false
		retry_count=0
		until deleted or retry_count >= 3 do
			begin
				retry_count += 1
				cs_conn=self.cloud_server_init
				cs_conn.destroy_server(cloud_server_id)
				deleted = true
			rescue
				# ignore all exceptions on delete
			end
		end
	end

	# method to block until a server is online
	def loop_until_server_online
		cs_conn=self.cloud_server_init

		error_message="Failed to build server."

		timeout=self.server_online_timeout-(Time.now-self.updated_at).to_i
		timeout = 120 if timeout < 120

		begin
			Timeout::timeout(timeout) do

				# poll the server until progress is 100%
				cs=cs_conn.find_server("#{self.cloud_server_id_number}")
				until cs.progress == 100 do
					cs=cs_conn.find_server("#{self.cloud_server_id_number}")
					sleep 1
				end

				error_message="Failed to ssh to the node."	

				if ! system(%{

						COUNT=0
						while ! ssh -i #{self.server_group.ssh_key_basepath} root@#{cs.addresses[:public][0]} /bin/true > /dev/null 2>&1; do
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
	
	def rebuild
		begin

			Timeout::timeout(30) do
				ovpn_server_val=1
				# use 't' on SQLite
				if Server.connection.adapter_name =~ /SQLite/ then
					ovpn_server_val="t"
				end
				vpn_server=Server.find(:first, :conditions => ["server_group_id = ? AND openvpn_server = ?", self.server_group_id, ovpn_server_val])
				%x{
					ssh -i #{self.server_group.ssh_key_basepath} root@#{vpn_server.external_ip_addr} sed "/^#{self.name}.*/d" -i .ssh/known_hosts
				}
			end

			# NOTE: Cloud Servers rebuild doesn't support personalities so
			# we do a delete and create instead.
			if not self.cloud_server_id_number.nil? then
				delete_cloud_server(self.cloud_server_id_number)
			end
			sleep 10
			create_cloud_server(true)
		rescue Exception => e
			fail_and_raise "Failed to rebuild cloud server.", e
		end
	end
	handle_asynchronously :rebuild

	def ping_test(test_ip)

		begin
			Timeout::timeout(30) do

				if system(%{
						ssh -i #{self.server_group.ssh_key_basepath} root@#{self.external_ip_addr} ping -c 1 #{test_ip} > /dev/null 2>&1
				}) then
					return true
				end

			end
		rescue Exception => e
		end

		return false

	end

	def add_error_message(message, long_error_message=message)
		self.error_message=message
		self.server_errors << ServerError.new(:error_message => long_error_message, :cloud_server_id_number => self.cloud_server_id_number)
	end

	def cloud_server_init
		acct=Account.find(self.account_id)
		CloudServersUtil.new(acct.cloud_servers_username, acct.cloud_servers_api_key)
	end

	# Generates a personalities hash (See Cloud Servers API docs for details)
	# By default only the authorized keys files is written.
	# For open_vpn servers we also write the id_rsa from the Server Group
	# so that it can access the other nodes.
	private
	def generate_personalities(include_ssh_private_key=false)

		# add keys from the Server Group (added via XML API)
		authorized_keys=self.server_group.ssh_public_keys.inject("") { |sum, k| sum + k.public_key + "\n"}

		# add any keys from the config files	
		if not ENV['CC_AUTHORIZED_KEYS'].blank? then
			authorized_keys += ENV['CC_AUTHORIZED_KEYS']
		end

		# append the public key from the ServerGroup
		authorized_keys += IO.read(self.server_group.ssh_key_basepath+".pub")
		tmp_auth_keys=Tempfile.new "cs_auth_keys"
		tmp_auth_keys.write(authorized_keys)
		tmp_auth_keys.flush
		@tmp_files << tmp_auth_keys

		personalities={}
		personalities.store(tmp_auth_keys.path, "/root/.ssh/authorized_keys")
		personalities.store(File.join(RAILS_ROOT, 'config', 'root_ssh_config'), "/root/.ssh/config")
		
		# create a .rackspace_cloud file with username/password info
		cloud_key_config=%{
userid: #{ENV['RACKSPACE_CLOUD_USERNAME']}
api_key: #{ENV['RACKSPACE_CLOUD_API_KEY']}
		}
		tmp_cloud_key=Tempfile.new "cs_auth_keys"
		tmp_cloud_key.write(cloud_key_config)
		tmp_cloud_key.flush
		@tmp_files << tmp_auth_keys
		personalities.store(tmp_cloud_key.path, "/root/.rackspace_cloud")

		if include_ssh_private_key then
			personalities.store(self.server_group.ssh_key_basepath,"/root/.ssh/id_rsa")
		end

		return personalities

	end

	# private function used to set failure status, record error message
	# and then raise an exception
	private
	def fail_and_raise(message, exception=nil)
		self.status = "Failed"
		if exception.nil? then
			self.add_error_message(message)
			save
			raise message
		else
			begin
				self.add_error_message("#{message}: #{exception.message}")
				save
			rescue
				self.add_error_message(message)
				save
			end
			raise exception
		end
	end

end
