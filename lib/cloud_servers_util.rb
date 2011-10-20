require 'rubygems'
require 'cloudservers'

# wrapper around all Cloud Server API calls
class CloudServersUtil

	@cs_conn=nil

	def initialize(username, api_key)
		@cs_conn = CloudServers::Connection.new(:username => username, :api_key => api_key, :retry_auth => true)
	end

	# Create a cloud server instance with root ssh access
	# This function requires that a $HOME/.ssh/id_rsa.pub key
	# exist for the process running this web application
	def create_cloud_server(name, image_id, flavor_id, personalities={})

		@cs_conn.create_server(
			:name => name,
			:imageId => image_id,
			:flavorId => flavor_id,
			:personality => personalities)

	end

	def find_server(id)
		@cs_conn.server(id)
	end

	def destroy_server(id)
		server=@cs_conn.server(id)
		server.delete!
	end

	def reboot_server(id)
		server=@cs_conn.server(id)
		server.reboot!
	end

	def all_servers

		if block_given? then
			@cs_conn.servers.each do |server|
				yield server
			end
		else
			@cs_conn.servers
		end

	end

	def all_images

		if block_given? then
			@cs_conn.images.each do |image|
				yield image
			end
		else
			@cs_conn.images
		end

	end

	def account_limits
		@cs_conn.limits
	end

end
