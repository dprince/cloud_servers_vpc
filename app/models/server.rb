require 'logger'
require 'cloud_servers_util'
require 'timeout'
require 'util/ip_validator'

class Server < ActiveRecord::Base

	include Util::IpValidator

	cattr_accessor :server_online_timeout
	cattr_accessor :windows_server_online_timeout
	self.server_online_timeout = 360
	self.windows_server_online_timeout = 720

	attr_accessor :num_vpn_network_interfaces

	belongs_to :server_group
	belongs_to :account
	validates_presence_of :name, :description, :flavor_id, :image_id, :server_group_id, :account_id
	validates_numericality_of :flavor_id, :image_id, :server_group_id
	validates_numericality_of :cloud_server_id_number, :if => :cloud_server_id_number
	validates_uniqueness_of :name, :scope => :server_group_id
	has_many :vpn_network_interfaces, :dependent => :destroy
	has_many :server_errors
	validates_format_of :name, :with => /^[A-Za-z0-9\-\.]+$/, :message => "Server name must use valid hostname characters (A-Z, a-z, 0-9, dash)."
	validates_length_of :name, :maximum => 255
	validates_length_of :description, :maximum => 255

    def self.new_for_type(params)

		if ["28","31","24","23","29"].include?(params[:image_id].to_s) then
			WindowsServer.new(params)
		else
			LinuxServer.new(params)
		end

    end

    def Server.create_vpn_client_for_type(server)

		if ["28","31","24","23","29"].include?(server.image_id.to_s) then
			Resque.enqueue(CreateWindowsVPNClient, server.id)
		else
			Resque.enqueue(CreateLinuxVPNClient, server.id)
		end

    end

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
			transaction do
				sg=self.server_group
				ips=[sg.next_ip, sg.next_ip]
				if not subnets_match?(ips[0], ips[1], "255.255.255.252") then
					ips=[ips[1], sg.next_ip]
				end
				sg.last_used_ip_address = IPAddr.new(sg.ip_inc_last_used_ip_address.to_i, Socket::AF_INET).to_s
				sg.save!
				VpnNetworkInterface.create(
					:vpn_ip_addr => ips[0],
					:ptp_ip_addr => ips[1],
					:server_id => self.attributes["id"]
				)
			end
		end

	end

	def make_historical
		if not self.cloud_server_id_number.nil? then
			delete_cloud_server(self.cloud_server_id_number)
		end
		update_attribute(:historical, true)
	end

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
			cs=cs_conn.create_cloud_server("#{server_name_prefix}#{self.name}-#{self.server_group_id}-#{retry_suffix}", self.image_id, self.flavor_id, generate_personalities)
			@tmp_files.each {|f| f.close(true)} #Remove tmp personalities files
			#harvest server ID and IP information
			self.cloud_server_id_number = cs.id
			self.external_ip_addr = cs.addresses[:public][0]
			self.internal_ip_addr = cs.addresses[:private][0]
			self.admin_password = cs.adminPass
			save!
	
			# if this server is an OpenVPN server create it now
			if self.openvpn_server then
				Resque.enqueue(CreateOpenVPNServer, self.id)
			else
				if schedule_client_openvpn then
					Server.create_vpn_client_for_type(self)
				end
			end

		rescue Exception => e
			self.retry_count += 1
			self.status = "Pending" # keep status set to pending

			long_error_message=nil
			begin
				long_error_message="#{e.message}: #{e.response_body}"
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
			Resque.enqueue(CreateCloudServer, self.id, false)
		end

	end

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
			Resque.enqueue(CreateCloudServer, self.id, true)
		rescue Exception => e
			fail_and_raise "Failed to rebuild cloud server.", e
		end
	end

	def cloud_server_init
		acct=Account.find(self.account_id)
		CloudServersUtil.new(acct.cloud_servers_username, acct.cloud_servers_api_key)
	end

	def add_error_message(message, long_error_message=message)
		self.error_message=message
		self.server_errors << ServerError.new(:error_message => long_error_message, :cloud_server_id_number => self.cloud_server_id_number)
	end

	# set failure status, record error message and then raise an exception
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
