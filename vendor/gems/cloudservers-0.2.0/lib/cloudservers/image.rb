module CloudServers
  class Image

    attr_reader :id
    attr_reader :name
    attr_reader :serverId
    attr_reader :updated
    attr_reader :created
    attr_reader :status
    attr_reader :progress
    
    # This class provides an object for the "Image" of a server.  The Image refers to the Operating System type and version.
    #
    # Returns the Image object identifed by the supplied ID number.  Called from the get_image instance method of CloudServers::Connection,
    # it will likely not be called directly from user code.
    #
    #   >> cs = CloudServers::Connection.new(USERNAME,API_KEY)
    #   >> image = cs.get_image(2)
    #   => #<CloudServers::Image:0x1015371c0 ...>
    #   >> image.name
    #   => "CentOS 5.2"    
    def initialize(connection,id)
      @id = id
      @connection = connection
      populate
    end
    
    # Makes the HTTP call to load information about the provided image.  Can also be called directly on the Image object to refresh data.
    # Returns true if the refresh call succeeds.
    #
    #   >> image.populate
    #   => true
    def populate
      response = @connection.csreq("GET",@connection.svrmgmthost,"#{@connection.svrmgmtpath}/images/#{URI.escape(self.id.to_s)}",@connection.svrmgmtport,@connection.svrmgmtscheme)
      CloudServers::Exception.raise_exception(response) unless response.code.match(/^20.$/)
      data = JSON.parse(response.body)['image']
      @id = data['id']
      @name = data['name']
      @serverId = data['serverId']
      @updated = DateTime.parse(data['updated'])
      @created = DateTime.parse(data['created'])
      @status = data['status']
      @progress = data['progress']
      return true
    end
    alias :refresh :populate
    
    # Delete an image.  This should be returning invalid permissions when attempting to delete system images, but it's not.
    # Returns true if the deletion succeeds.
    #
    #   >> image.delete!
    #   => true
    def delete!
      response = @connection.csreq("DELETE",@connection.svrmgmthost,"#{@connection.svrmgmtpath}/images/#{URI.escape(self.id.to_s)}",@connection.svrmgmtport,@connection.svrmgmtscheme)
      CloudServers::Exception.raise_exception(response) unless response.code.match(/^20.$/)
      true
    end
    
  end
end