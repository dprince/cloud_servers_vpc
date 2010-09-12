module CloudServers
  class Server
    
    attr_reader   :id
    attr_reader   :name
    attr_reader   :status
    attr_reader   :progress
    attr_reader   :addresses
    attr_reader   :metadata
    attr_reader   :hostId
    attr_reader   :imageId
    attr_reader   :flavorId
    attr_reader   :metadata
    attr_accessor :adminPass
    
    # This class is the representation of a single Cloud Server object.  The constructor finds the server identified by the specified
    # ID number, accesses the API via the populate method to get information about that server, and returns the object.
    #
    # Will be called via the get_server or create_server methods on the CloudServers::Connection object, and will likely not be called directly.
    #
    #   >> server = cs.get_server(110917)
    #   => #<CloudServers::Server:0x1014e5438 ....>
    #   >> server.name
    #   => "RenamedRubyTest"
    def initialize(connection,id)
      @connection    = connection
      @id            = id
      @svrmgmthost   = connection.svrmgmthost
      @svrmgmtpath   = connection.svrmgmtpath
      @svrmgmtport   = connection.svrmgmtport
      @svrmgmtscheme = connection.svrmgmtscheme
      populate
      return self
    end
    
    # Makes the actual API call to get information about the given server object.  If you are attempting to track the status or project of
    # a server object (for example, when rebuilding, creating, or resizing a server), you will likely call this method within a loop until 
    # the status becomes "ACTIVE" or other conditions are met.
    #
    # Returns true if the API call succeeds.
    #
    #  >> server.refresh
    #  => true
    def populate
      response = @connection.csreq("GET",@svrmgmthost,"#{@svrmgmtpath}/servers/#{URI.encode(@id.to_s)}",@svrmgmtport,@svrmgmtscheme)
      CloudServers::Exception.raise_exception(response) unless response.code.match(/^20.$/)
      data = JSON.parse(response.body)["server"]
      @id        = data["id"]
      @name      = data["name"]
      @status    = data["status"]
      @progress  = data["progress"]
      @addresses = CloudServers.symbolize_keys(data["addresses"])
      @metadata  = data["metadata"]
      @hostId    = data["hostId"]
      @imageId   = data["imageId"]
      @flavorId  = data["flavorId"]
      @metadata  = data["metadata"]
      true
    end
    alias :refresh :populate
    
    # Returns a new CloudServers::Flavor object for the flavor assigned to this server.
    #
    #   >> flavor = server.flavor
    #   => #<CloudServers::Flavor:0x1014aac20 @name="256 server", @disk=10, @id=1, @ram=256>
    #   >> flavor.name
    #   => "256 server"
    def flavor
      CloudServers::Flavor.new(@connection,self.flavorId)
    end
    
    # Returns a new CloudServers::Image object for the image assigned to this server.
    #
    #   >> image = server.image
    #   => #<CloudServers::Image:0x10149a960 ...>
    #   >> image.name
    #   => "Ubuntu 8.04.2 LTS (hardy)"
    def image
      CloudServers::Image.new(@connection,self.imageId)
    end
    
    # Sends an API request to reboot this server.  Takes an optional argument for the type of reboot, which can be "SOFT" (graceful shutdown)
    # or "HARD" (power cycle).  The hard reboot is also triggered by server.reboot!, so that may be a better way to call it.
    #
    # Returns true if the API call succeeds.
    #
    #   >> server.reboot
    #   => true
    def reboot(type="SOFT")
      data = JSON.generate(:reboot => {:type => type})
      response = @connection.csreq("POST",@svrmgmthost,"#{@svrmgmtpath}/servers/#{URI.encode(self.id.to_s)}/action",@svrmgmtport,@svrmgmtscheme,{'content-type' => 'application/json'},data)
      CloudServers::Exception.raise_exception(response) unless response.code.match(/^20.$/)
      true
    end
    
    # Sends an API request to hard-reboot (power cycle) the server.  See the reboot method for more information.
    #
    # Returns true if the API call succeeds.
    #
    #   >> server.reboot!
    #   => true
    def reboot!
      self.reboot("HARD")
    end
    
    # Updates various parameters about the server.  Currently, the only operations supported are changing the server name (not the actual hostname
    # on the server, but simply the label in the Cloud Servers API) and the administrator password (note: changing the admin password will trigger
    # a reboot of the server).  Other options are ignored.  One or both key/value pairs may be provided.  Keys are case-sensitive.
    #
    # Input hash key values are :name and :adminPass.  Returns true if the API call succeeds.
    #
    #   >> server.update(:name => "MyServer", :adminPass => "12345")
    #   => true
    #   >> server.name
    #   => "MyServer"
    def update(options)
      data = JSON.generate(:server => options)
      response = @connection.csreq("PUT",@svrmgmthost,"#{@svrmgmtpath}/servers/#{URI.encode(self.id.to_s)}",@svrmgmtport,@svrmgmtscheme,{'content-type' => 'application/json'},data)
      CloudServers::Exception.raise_exception(response) unless response.code.match(/^20.$/)
      # If we rename the instance, repopulate the object
      self.populate if options[:name]
      true
    end
    
    # Deletes the server from Cloud Servers.  The server will be shut down, data deleted, and billing stopped.
    #
    # Returns true if the API call succeeds.
    #
    #   >> server.delete!
    #   => true
    def delete!
      response = @connection.csreq("DELETE",@svrmgmthost,"#{@svrmgmtpath}/servers/#{URI.encode(self.id.to_s)}",@svrmgmtport,@svrmgmtscheme)
      CloudServers::Exception.raise_exception(response) unless response.code.match(/^20.$/)
      true
    end
    
    # Takes the existing server and rebuilds it with the image identified by the imageId argument.  If no imageId is provided, the current image
    # will be used.
    #
    # This will wipe and rebuild the server, but keep the server ID number, name, and IP addresses the same.
    #
    # Returns true if the API call succeeds.
    #
    #   >> server.rebuild!
    #   => true
    def rebuild!(imageId = self.imageId)
      data = JSON.generate(:rebuild => {:imageId => imageId})
      response = @connection.csreq("POST",@svrmgmthost,"#{@svrmgmtpath}/servers/#{URI.encode(self.id.to_s)}/action",@svrmgmtport,@svrmgmtscheme,{'content-type' => 'application/json'},data)
      CloudServers::Exception.raise_exception(response) unless response.code.match(/^20.$/)
      self.populate
      true
    end
    
    # Takes a snapshot of the server and creates a server image from it.  That image can then be used to build new servers.  The
    # snapshot is saved asynchronously.  Check the image status to make sure that it is ACTIVE before attempting to perform operations
    # on it.
    # 
    # A name string for the saved image must be provided.  A new CloudServers::Image object for the saved image is returned.
    #
    # The image is saved as a backup, of which there are only three available slots.  If there are no backup slots available, 
    # A CloudServers::Exception::CloudServersFault will be raised.
    #
    #   >> image = server.create_image("My Rails Server")
    #   => 
    def create_image(name)
      data = JSON.generate(:image => {:serverId => self.id, :name => name})
      response = @connection.csreq("POST",@svrmgmthost,"#{@svrmgmtpath}/images",@svrmgmtport,@svrmgmtscheme,{'content-type' => 'application/json'},data)
      CloudServers::Exception.raise_exception(response) unless response.code.match(/^20.$/)
      CloudServers::Image.new(@connection,JSON.parse(response.body)['image']['id'])
    end
    
    # Resizes the server to the size contained in the server flavor found at ID flavorId.  The server name, ID number, and IP addresses 
    # will remain the same.  After the resize is done, the server.status will be set to "VERIFY_RESIZE" until the resize is confirmed or reverted.
    #
    # Refreshes the CloudServers::Server object, and returns true if the API call succeeds.
    # 
    #   >> server.resize!(1)
    #   => true
    def resize!(flavorId)
      data = JSON.generate(:resize => {:flavorId => flavorId})
      response = @connection.csreq("POST",@svrmgmthost,"#{@svrmgmtpath}/servers/#{URI.encode(self.id.to_s)}/action",@svrmgmtport,@svrmgmtscheme,{'content-type' => 'application/json'},data)
      CloudServers::Exception.raise_exception(response) unless response.code.match(/^20.$/)
      self.populate
      true
    end
    
    # After a server resize is complete, calling this method will confirm the resize with the Cloud Servers API, and discard the fallback/original image.
    #
    # Returns true if the API call succeeds.
    #
    #   >> server.confirm_resize!
    #   => true
    def confirm_resize!
      # If the resize bug gets figured out, should put a check here to make sure that it's in the proper state for this.
      data = JSON.generate(:confirmResize => nil)
      response = @connection.csreq("POST",@svrmgmthost,"#{@svrmgmtpath}/servers/#{URI.encode(self.id.to_s)}/action",@svrmgmtport,@svrmgmtscheme,{'content-type' => 'application/json'},data)
      CloudServers::Exception.raise_exception(response) unless response.code.match(/^20.$/)
      self.populate
      true
    end
    
    # After a server resize is complete, calling this method will reject the resized server with the Cloud Servers API, destroying
    # the new image and replacing it with the pre-resize fallback image.
    #
    # Returns true if the API call succeeds.
    #
    #   >> server.confirm_resize!
    #   => true
    def revert_resize!
      # If the resize bug gets figured out, should put a check here to make sure that it's in the proper state for this.
      data = JSON.generate(:revertResize => nil)
      response = @connection.csreq("POST",@svrmgmthost,"#{@svrmgmtpath}/servers/#{URI.encode(self.id.to_s)}/action",@svrmgmtport,@svrmgmtscheme,{'content-type' => 'application/json'},data)
      CloudServers::Exception.raise_exception(response) unless response.code.match(/^20.$/)
      self.populate
      true
    end
    
    # Provides information about the backup schedule for this server.  Returns a hash of the form 
    # {"weekly" => state, "daily" => state, "enabled" => boolean}
    #
    #   >> server.backup_schedule
    #   => {"weekly"=>"THURSDAY", "daily"=>"H_0400_0600", "enabled"=>true}
    def backup_schedule
      response = @connection.csreq("GET",@svrmgmthost,"#{@svrmgmtpath}/servers/#{URI.encode(@id.to_s)}/backup_schedule",@svrmgmtport,@svrmgmtscheme)
      CloudServers::Exception.raise_exception(response) unless response.code.match(/^20.$/)
      JSON.parse(response.body)['backupSchedule']
    end
    
    # Updates the backup schedule for the server.  Takes a hash of the form: {:weekly => state, :daily => state, :enabled => boolean} as an argument.
    # All three keys (:weekly, :daily, :enabled) must be provided or an exception will get raised.
    #
    #   >> server.backup_schedule=({:weekly=>"THURSDAY", :daily=>"H_0400_0600", :enabled=>true})
    #   => {:weekly=>"THURSDAY", :daily=>"H_0400_0600", :enabled=>true}
    def backup_schedule=(options)
      data = JSON.generate('backupSchedule' => options)
      response = @connection.csreq("POST",@svrmgmthost,"#{@svrmgmtpath}/servers/#{URI.encode(self.id.to_s)}/backup_schedule",@svrmgmtport,@svrmgmtscheme,{'content-type' => 'application/json'},data)
      CloudServers::Exception.raise_exception(response) unless response.code.match(/^20.$/)
      true
    end
    
    # Removes the existing backup schedule for the server, setting the backups to disabled.
    #
    # Returns true if the API call succeeds.
    #
    #   >> server.disable_backup_schedule!
    #   => true
    def disable_backup_schedule!
      response = @connection.csreq("DELETE",@svrmgmthost,"#{@svrmgmtpath}/servers/#{URI.encode(self.id.to_s)}/backup_schedule",@svrmgmtport,@svrmgmtscheme)
      CloudServers::Exception.raise_exception(response) unless response.code.match(/^20.$/)
      true
    end
    
  end
end