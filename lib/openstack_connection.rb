require 'rubygems'
require 'openstack/compute'

# wrapper around all OpenStack Compute API calls
class OpenstackConnection

  @os_conn=nil

  def initialize(username, api_key, auth_url)
    @os_conn = OpenStack::Compute::Connection.new(:username => username, :api_key => api_key, :auth_url => auth_url, :retry_auth => true)
  end

  #return an array containing the server id and admin password
  def create_server(name, image_ref, flavor_ref, personalities={})
    server = @os_conn.create_server(
      :name => name,
      :imageRef => image_ref,
      :flavorRef => flavor_ref,
      :personality => personalities)
    [server.id, server.adminPass]
  end

  # returns a hash containing detailed server info
  def get_server(id)
    server = @os_conn.server(id)
    server_data = {
     :id => server.id,
     :progress => server.progress,
     :status => server.status
    }
    begin
      if server.addresses.size > 0 and server.addresses[:public] and server.addresses[:private] then

        pubs = server.addresses[:public].reject {|addr| addr.version != 4}
        privs = server.addresses[:private].reject {|addr| addr.version != 4}

        server_data.store(:public_ip, pubs[0].address)
        server_data.store(:private_ip, privs[0].address)
      end
    rescue Exception => e
      #puts "Failed to get address info: " + e.message
    end
    server_data
  end

  def update_server(id, data)
    server = @os_conn.server(id)
    server.update(data)
  end

  def destroy_server(id)
    server = @os_conn.server(id)
    server.delete!
  end

  def reboot_server(id)
    server = @os_conn.server(id)
    server.reboot!
  end

  # returns an array of :id, :name hashes
  def all_servers

    if block_given? then
      @os_conn.servers.each do |server|
        yield server
      end
    else
      @os_conn.servers
    end

  end

  # returns an array of :id, :name hashes
  def all_images

    if block_given? then
      @os_conn.images.each do |image|
        yield image
      end
    else
      @os_conn.images
    end

  end

  def account_limits
    @os_conn.limits
  end

end
