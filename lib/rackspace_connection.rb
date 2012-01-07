require 'rubygems'
require 'cloudservers'

# wrapper around all Rackspace Cloud Servers API calls
class RackspaceConnection

  @cs_conn=nil

  def initialize(username, api_key, auth_url)
    if auth_url.blank? then
      @cs_conn = CloudServers::Connection.new(:username => username, :api_key => api_key, :retry_auth => true)
    else
      @cs_conn = CloudServers::Connection.new(:username => username, :api_key => api_key, :retry_auth => true, :auth_url => auth_url)
    end
  end

  #return an array containing the server id and admin password
  def create_server(name, image_id, flavor_id, personalities={})
    server = @cs_conn.create_server(
      :name => name,
      :imageId => image_id.to_i,
      :flavorId => flavor_id.to_i,
      :personality => personalities)
    [server.id, server.adminPass]
  end

  # returns a hash containing detailed server info
  def get_server(id)
    server = @cs_conn.server(id.to_i)
    {
     :id => server.id,
     :progress => server.progress,
     :status => server.status,
     :public_ip => server.addresses[:public][0],
     :private_ip => server.addresses[:private][0]
    }
  end

  def update_server(id, data)
    server = @cs_conn.server(id.to_i)
    server.update(data)
  end

  def destroy_server(id)
    server = @cs_conn.server(id.to_i)
    server.delete!
  end

  def reboot_server(id)
    server = @cs_conn.server(id.to_i)
    server.reboot!
  end

  # returns an array of :id, :name hashes
  def all_servers

    if block_given? then
      @cs_conn.servers.each do |server|
        yield server
      end
    else
      @cs_conn.servers
    end

  end

  # returns an array of :id, :name hashes
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
