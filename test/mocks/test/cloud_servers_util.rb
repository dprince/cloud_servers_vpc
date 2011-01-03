class CloudServersUtil

	class TestCloudServer
		attr_accessor :name, :imageId, :flavorId, :hostId, :status, :progress, :addresses, :metadata, :personality, :adminPass
	end

	def initialize(username, api_key)
		if ENV['CLOUD_SERVERS_UTIL_INIT_MOCK_FAIL'] then
			ENV.delete('CLOUD_SERVERS_UTIL_INIT_MOCK_FAIL')
			raise "Invalid account specified"
		else
			return true
		end
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

	def all_servers
		return []
	end

	def account_limits
		return %{{"absolute":{"maxIPGroups":25,"maxIPGroupMembers":25,"maxTotalRAMSize":51200},"rate":[{"remaining":10,"URI":"*","unit":"MINUTE","resetTime":1287082645,"value":10,"regex":".*","verb":"PUT"},{"remaining":3,"URI":"*changes-since*","unit":"MINUTE","resetTime":1287082645,"value":3,"regex":"changes-since","verb":"GET"},{"remaining":600,"URI":"*","unit":"MINUTE","resetTime":1287082645,"value":600,"regex":".*","verb":"DELETE"},{"remaining":58,"URI":"/servers*","unit":"HOUR","resetTime":1287083964,"value":60,"regex":"^/servers","verb":"POST"}]}
}
	end

end
