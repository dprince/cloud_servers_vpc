class CloudServersUtil

	class TestCloudServer
		attr_accessor :name, :imageId, :flavorId, :hostId, :status, :progress, :addresses, :metadata, :personality, :adminPass
	end

	def initialize(username, api_key)
		return true
	end

	def create_cloud_server(name, image_id, flavor_id, personalities={})
		server=TestCloudServer.new
		server.name = name
		server.imageId = image_id
		server.flavorId = flavor_id
		server.progress = 100
		return server
	end

	def find_server(id)
		server=TestCloudServer.new
		server.name = name
		server.imageId = image_id
		server.flavorId = flavor_id
		return server
	end

	def destroy_server(id)
		return true
	end

	def reboot_server(id)
		return true
	end

end
