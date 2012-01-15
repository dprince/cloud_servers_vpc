class RackspaceConnection

  class TestCloudServer
    attr_accessor :id, :name, :imageId, :flavorId, :hostId, :status, :progress, :addresses, :metadata, :personality, :adminPass
  end

  def initialize(username, api_key, auth_url)
    if ENV['CLOUD_SERVERS_UTIL_INIT_MOCK_FAIL'] then
      ENV.delete('CLOUD_SERVERS_UTIL_INIT_MOCK_FAIL')
      raise "Invalid account specified"
    else
      return true
    end
  end

  def create_server(name, image_id, flavor_id, personalities={})
    server=TestCloudServer.new
    server.name = name
    server.imageId = image_id
    server.flavorId = flavor_id
    server.progress = 100
    return server.id
  end

  def get_server(id)
    server=TestCloudServer.new
    server.name = 'TEST'
    server.imageId = 1
    server.flavorId = 2
    server.status = 'ACTIVE'
    server.progress = '100'
    return {
      :id => server.id,
      :progress => server.progress,
      :status => server.status,
      :public_ip => '1.2.3.4',
      :private_ip => '5.6.7.8',
      :admin_password => server.adminPass
    }
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

  def all_images
    return []
  end

  def account_limits
    return %{{"absolute":{"maxIPGroups":25,"maxIPGroupMembers":25,"maxTotalRAMSize":51200},"rate":[{"remaining":10,"URI":"*","unit":"MINUTE","resetTime":1287082645,"value":10,"regex":".*","verb":"PUT"},{"remaining":3,"URI":"*changes-since*","unit":"MINUTE","resetTime":1287082645,"value":3,"regex":"changes-since","verb":"GET"},{"remaining":600,"URI":"*","unit":"MINUTE","resetTime":1287082645,"value":600,"regex":".*","verb":"DELETE"},{"remaining":58,"URI":"/servers*","unit":"HOUR","resetTime":1287083964,"value":60,"regex":"^/servers","verb":"POST"}]}
}
  end

end
