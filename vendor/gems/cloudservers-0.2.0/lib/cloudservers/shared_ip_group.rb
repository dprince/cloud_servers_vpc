module CloudServers
  class SharedIPGroup
    
    attr_reader :id
    attr_reader :name
    attr_reader :servers
    
    # Creates a new Shared IP Group object, with information on the group identified by the ID number.  Will most likely be called 
    # by the get_shared_ip_group method on a CloudServers::Connection object.
    #
    #   >> sig = cs.get_shared_ip_group(127)
    #   => #<CloudServers::SharedIPGroup:0x101513798 ...>
    #   >> sig.name
    #   => "New Group"
    def initialize(connection,id)
      @connection = connection
      @id = id
      populate
    end
    
    # Makes the API call that populates the CloudServers::SharedIPGroup object with information on the group.  Can also be called directly on
    # an existing object to update its information.
    # 
    # Returns true if the API call succeeds.
    #
    #   >> sig.populate
    #   => true
    def populate
      response = @connection.csreq("GET",@connection.svrmgmthost,"#{@connection.svrmgmtpath}/shared_ip_groups/#{URI.escape(self.id.to_s)}",@connection.svrmgmtport,@connection.svrmgmtscheme)
      CloudServers::Exception.raise_exception(response) unless response.code.match(/^20.$/)
      data = JSON.parse(response.body)['sharedIpGroup']
      @id = data['id']
      @name = data['name']
      @servers = data['servers']
      true
    end
    alias :refresh :populate
    
    # Deletes the Shared IP Group identified by the current object.
    #
    # Returns true if the API call succeeds.
    #
    #   >> sig.delete!
    #   => true
    def delete!
      response = @connection.csreq("DELETE",@connection.svrmgmthost,"#{@connection.svrmgmtpath}/shared_ip_groups/#{URI.escape(self.id.to_s)}",@connection.svrmgmtport,@connection.svrmgmtscheme)
      CloudServers::Exception.raise_exception(response) unless response.code.match(/^20.$/)
      true
    end
    
  end
end