module CloudServers
  class Connection
    
    attr_reader   :authuser
    attr_reader   :authkey
    attr_accessor :authtoken
    attr_accessor :authok
    attr_accessor :svrmgmthost
    attr_accessor :svrmgmtpath
    attr_accessor :svrmgmtport
    attr_accessor :svrmgmtscheme
    attr_reader   :proxy_host
    attr_reader   :proxy_port
    
    # Creates a new CloudServers::Connection object.  Uses CloudServers::Authentication to perform the login for the connection.
    #
    # Setting the retry_auth option to false will cause an exception to be thrown if your authorization token expires.
    # Otherwise, it will attempt to reauthenticate.
    #
    # This is useful if you are using the library on a Rackspace-hosted system, as it provides faster speeds, keeps traffic off of
    # the public network, and the bandwidth is not billed.
    #
    # This will likely be the base class for most operations.
    #
    # The constructor takes a hash of options, including:
    #
    #   :username - Your Rackspace Cloud username *required*
    #   :api_key - Your Rackspace Cloud API key *required*
    #   :retry_auth - Whether to retry if your auth token expires (defaults to true)
    #   :proxy_host - If you need to connect through a proxy, supply the hostname here
    #   :proxy_port - If you need to connect through a proxy, supply the port here
    #
    #   cf = CloudServers::Connection.new(:username => 'YOUR_USERNAME', :api_key => 'YOUR_API_KEY')
    def initialize(options = {:retry_auth => true}) 
      @authuser = options[:username] || (raise Exception::Authentication, "Must supply a :username")
      @authkey = options[:api_key] || (raise Exception::Authentication, "Must supply an :api_key")
      @retry_auth = options[:retry_auth]
      @proxy_host = options[:proxy_host]
      @proxy_port = options[:proxy_port]
      @authok = false
      @http = {}
      CloudServers::Authentication.new(self)
    end
    
    # Returns true if the authentication was successful and returns false otherwise.
    #
    #   cs.authok?
    #   => true
    def authok?
      @authok
    end
    
    # This method actually makes the HTTP REST calls out to the server
    def csreq(method,server,path,port,scheme,headers = {},data = nil,attempts = 0) # :nodoc:
      start = Time.now
      hdrhash = headerprep(headers)
      start_http(server,path,port,scheme,hdrhash)
      request = Net::HTTP.const_get(method.to_s.capitalize).new(path,hdrhash)
      request.body = data
      response = @http[server].request(request)
      raise CloudServers::Exception::ExpiredAuthToken if response.code == "401"
      response
    rescue Errno::EPIPE, Timeout::Error, Errno::EINVAL, EOFError
      # Server closed the connection, retry
      raise CloudServers::Exception::Connection, "Unable to reconnect to #{server} after #{attempts} attempts" if attempts >= 5
      attempts += 1
      @http[server].finish if @http[server].started?
      start_http(server,path,port,scheme,headers)
      retry
    rescue CloudServers::Exception::ExpiredAuthToken
      raise CloudServers::Exception::Connection, "Authentication token expired and you have requested not to retry" if @retry_auth == false
      CloudFiles::Authentication.new(self)
      retry
    end
    
    # Returns the CloudServers::Server object identified by the given id.
    #
    #   >> server = cs.get_server(110917)
    #   => #<CloudServers::Server:0x101407ae8 ...>
    #   >> server.name
    #   => "MyServer"
    def get_server(id)
      CloudServers::Server.new(self,id)
    end
    alias :server :get_server
    
    # Returns an array of hashes, one for each server that exists under this account.  The hash keys are :name and :id.
    #
    # You can also provide :limit and :offset parameters to handle pagination.
    #
    #   >> cs.list_servers
    #   => [{:name=>"MyServer", :id=>110917}]
    #
    #   >> cs.list_servers(:limit => 2, :offset => 3)
    #   => [{:name=>"demo-standingcloud-lts", :id=>168867}, 
    #       {:name=>"demo-aicache1", :id=>187853}]
    def list_servers(options = {})
      anti_cache_param="cacheid=#{Time.now.to_i}"
      path = CloudServers.paginate(options).empty? ? "#{svrmgmtpath}/servers?#{anti_cache_param}" : "#{svrmgmtpath}/servers?#{CloudServers.paginate(options)}&#{anti_cache_param}"
      response = csreq("GET",svrmgmthost,path,svrmgmtport,svrmgmtscheme)
      CloudServers::Exception.raise_exception(response) unless response.code.match(/^20.$/)
      CloudServers.symbolize_keys(JSON.parse(response.body)["servers"])
    end
    alias :servers :list_servers
    
    # Returns an array of hashes with more details about each server that exists under this account.  Additional information
    # includes public and private IP addresses, status, hostID, and more.  All hash keys are symbols except for the metadata
    # hash, which are verbatim strings.
    #
    # You can also provide :limit and :offset parameters to handle pagination.
    #   >> cs.list_servers_detail
    #   => [{:name=>"MyServer", :addresses=>{:public=>["67.23.42.37"], :private=>["10.176.241.237"]}, :metadata=>{"MyData" => "Valid"}, :imageId=>10, :progress=>100, :hostId=>"36143b12e9e48998c2aef79b50e144d2", :flavorId=>1, :id=>110917, :status=>"ACTIVE"}]
    #
    #   >> cs.list_servers_detail(:limit => 2, :offset => 3)
    #   => [{:status=>"ACTIVE", :imageId=>10, :progress=>100, :metadata=>{}, :addresses=>{:public=>["x.x.x.x"], :private=>["x.x.x.x"]}, :name=>"demo-standingcloud-lts", :id=>168867, :flavorId=>1, :hostId=>"xxxxxx"}, 
    #       {:status=>"ACTIVE", :imageId=>8, :progress=>100, :metadata=>{}, :addresses=>{:public=>["x.x.x.x"], :private=>["x.x.x.x"]}, :name=>"demo-aicache1", :id=>187853, :flavorId=>3, :hostId=>"xxxxxx"}]
    def list_servers_detail(options = {})
      path = CloudServers.paginate(options).empty? ? "#{svrmgmtpath}/servers/detail" : "#{svrmgmtpath}/servers/detail?#{CloudServers.paginate(options)}"
      response = csreq("GET",svrmgmthost,path,svrmgmtport,svrmgmtscheme)
      CloudServers::Exception.raise_exception(response) unless response.code.match(/^20.$/)
      CloudServers.symbolize_keys(JSON.parse(response.body)["servers"])
    end
    alias :servers_detail :list_servers_detail
    
    # Creates a new server instance on Cloud Servers
    # 
    # The argument is a hash of options.  The keys :name, :flavorId, and :imageId are required, :metadata and :personality are optional.
    #
    # :flavorId and :imageId are numbers identifying a particular server flavor and image to use when building the server.  The :imageId can either
    # be a stock Cloud Servers image, or one of your own created with the server.create_image method.
    #
    # The :metadata argument will take a hash of up to five key/value pairs.  This metadata will be applied to the server at the Cloud Servers
    # API level.
    #
    # The "Personality" option allows you to include up to five files, of 10Kb or less in size, that will be placed on the created server.
    # For :personality, pass a hash of the form {'local_path' => 'server_path'}.  The file located at local_path will be base64-encoded
    # and placed at the location identified by server_path on the new server.
    #
    # Returns a CloudServers::Server object.  The root password is available in the adminPass instance method.
    #
    #   >> server = cs.create_server(:name => "New Server", :imageId => 2, :flavorId => 2, :metadata => {'Racker' => 'Fanatical'}, :personality => {'/Users/me/Pictures/wedding.jpg' => '/root/me.jpg'})
    #   => #<CloudServers::Server:0x101229eb0 ...>
    #   >> server.name
    #   => "NewServer"
    #   >> server.status
    #   => "BUILD"
    #   >> server.adminPass
    #   => "NewServerSHMGpvI"
    def create_server(options)
      raise CloudServers::Exception::MissingArgument, "Server name, flavor ID, and image ID must be supplied" unless (options[:name] && options[:flavorId] && options[:imageId])
      options[:personality] = get_personality(options[:personality])
      raise TooManyMetadataItems, "Metadata is limited to a total of #{MAX_PERSONALITY_METADATA_ITEMS} key/value pairs" if options[:metadata].is_a?(Hash) && options[:metadata].keys.size > MAX_PERSONALITY_METADATA_ITEMS
      data = JSON.generate(:server => options)
      response = csreq("POST",svrmgmthost,"#{svrmgmtpath}/servers",svrmgmtport,svrmgmtscheme,{'content-type' => 'application/json'},data)
      CloudServers::Exception.raise_exception(response) unless response.code.match(/^20.$/)
      server_info = JSON.parse(response.body)['server']
      server = CloudServers::Server.new(self,server_info['id'])
      server.adminPass = server_info['adminPass']
      return server
    end
    
    # Returns an array of hashes listing available server images that you have access too, including stock Cloud Servers images and 
    # any that you have created.  The "id" key in the hash can be used where imageId is required.
    #
    # You can also provide :limit and :offset parameters to handle pagination.
    #
    #   >> cs.list_images
    #   => [{:name=>"CentOS 5.2", :id=>2, :updated=>"2009-07-20T09:16:57-05:00", :status=>"ACTIVE", :created=>"2009-07-20T09:16:57-05:00"}, 
    #       {:name=>"Gentoo 2008.0", :id=>3, :updated=>"2009-07-20T09:16:57-05:00", :status=>"ACTIVE", :created=>"2009-07-20T09:16:57-05:00"},...
    #
    #   >> cs.list_images(:limit => 3, :offset => 2) 
    #   => [{:status=>"ACTIVE", :name=>"Fedora 11 (Leonidas)", :updated=>"2009-12-08T13:50:45-06:00", :id=>13}, 
    #       {:status=>"ACTIVE", :name=>"CentOS 5.3", :updated=>"2009-08-26T14:59:52-05:00", :id=>7}, 
    #       {:status=>"ACTIVE", :name=>"CentOS 5.4", :updated=>"2009-12-16T01:02:17-06:00", :id=>187811}]
    def list_images(options = {})
      path = CloudServers.paginate(options).empty? ? "#{svrmgmtpath}/images/detail" : "#{svrmgmtpath}/images/detail?#{CloudServers.paginate(options)}"
      response = csreq("GET",svrmgmthost,path,svrmgmtport,svrmgmtscheme)
      CloudServers::Exception.raise_exception(response) unless response.code.match(/^20.$/)
      CloudServers.symbolize_keys(JSON.parse(response.body)['images'])
    end
    alias :images :list_images
    
    # Returns a CloudServers::Image object for the image identified by the provided id.
    #
    #   >> image = cs.get_image(8)
    #   => #<CloudServers::Image:0x101659698 ...>
    def get_image(id)
      CloudServers::Image.new(self,id)
    end
    alias :image :get_image
    
    # Returns an array of hashes listing all available server flavors.  The :id key in the hash can be used when flavorId is required.
    #
    # You can also provide :limit and :offset parameters to handle pagination.
    #
    #   >> cs.list_flavors
    #   => [{:name=>"256 server", :id=>1, :ram=>256, :disk=>10}, 
    #       {:name=>"512 server", :id=>2, :ram=>512, :disk=>20},...
    #
    #   >> cs.list_flavors(:limit => 3, :offset => 2)
    #   => [{:ram=>1024, :disk=>40, :name=>"1GB server", :id=>3}, 
    #       {:ram=>2048, :disk=>80, :name=>"2GB server", :id=>4}, 
    #       {:ram=>4096, :disk=>160, :name=>"4GB server", :id=>5}]       
    def list_flavors(options = {})
      path = CloudServers.paginate(options).empty? ? "#{svrmgmtpath}/flavors/detail" : "#{svrmgmtpath}/flavors/detail?#{CloudServers.paginate(options)}"
      response = csreq("GET",svrmgmthost,path,svrmgmtport,svrmgmtscheme)
      CloudServers::Exception.raise_exception(response) unless response.code.match(/^20.$/)
      CloudServers.symbolize_keys(JSON.parse(response.body)['flavors'])
    end
    alias :flavors :list_flavors
    
    # Returns a CloudServers::Flavor object for the flavor identified by the provided ID.
    #
    #   >> flavor = cs.flavor(1)
    #   => #<CloudServers::Flavor:0x10156dcc0 @name="256 server", @disk=10, @id=1, @ram=256>
    def get_flavor(id)
      CloudServers::Flavor.new(self,id)
    end
    alias :flavor :get_flavor
    
    # Returns an array of hashes for all Shared IP Groups that are available.  The :id key can be used to find that specific object.
    #
    # You can also provide :limit and :offset parameters to handle pagination.
    #
    #   >> cs.list_shared_ip_groups
    #   => [{:name=>"New Group", :id=>127}]
    def list_shared_ip_groups(options = {})
      path = CloudServers.paginate(options).empty? ? "#{svrmgmtpath}/shared_ip_groups/detail" : "#{svrmgmtpath}/shared_ip_groups/detail?#{CloudServers.paginate(options)}"
      response = csreq("GET",svrmgmthost,path,svrmgmtport,svrmgmtscheme)
      CloudServers::Exception.raise_exception(response) unless response.code.match(/^20.$/)
      CloudServers.symbolize_keys(JSON.parse(response.body)['sharedIpGroups'])
    end
    alias :shared_ip_groups :list_shared_ip_groups
    
    # Returns a CloudServers::SharedIPGroup object for the IP group identified by the provided ID.
    #
    #   >> sig = cs.get_shared_ip_group(127)
    #   => #<CloudServers::SharedIPGroup:0x10153ca30  ...>
    def get_shared_ip_group(id)
      CloudServers::SharedIPGroup.new(self,id)
    end
    alias :shared_ip_group :get_shared_ip_group
    
    # Creates a new Shared IP group.  Takes a hash as an argument.  
    #
    # Valid hash keys are :name (required) and :server (optional), which indicates the one server to place into this group by default.
    #
    #   >> sig = cs.create_shared_ip_group(:name => "Production Web", :server => 110917) 
    #   => #<CloudServers::SharedIPGroup:0x101501d18 ...>
    #   >> sig.name
    #   => "Production Web"
    #   >> sig.servers
    #   => [110917]
    def create_shared_ip_group(options)
      data = JSON.generate(:sharedIpGroup => options)
      response = csreq("POST",svrmgmthost,"#{svrmgmtpath}/shared_ip_groups",svrmgmtport,svrmgmtscheme,{'content-type' => 'application/json'},data)
      CloudServers::Exception.raise_exception(response) unless response.code.match(/^20.$/)
      ip_group = JSON.parse(response.body)['sharedIpGroup']
      CloudServers::SharedIPGroup.new(self,ip_group['id'])
    end
    
    # Returns the current state of the programatic API limits.  Each account has certain limits on the number of resources
    # allowed in the account, and a rate of API operations.
    #
    # The operation returns a hash.  The :absolute hash key reveals the account resource limits, including the maxmimum 
    # amount of total RAM that can be allocated (combined among all servers), the maximum members of an IP group, and the 
    # maximum number of IP groups that can be created.
    #
    # The :rate hash key returns an array of hashes indicating the limits on the number of operations that can be performed in a 
    # given amount of time.  An entry in this array looks like:
    #
    #   {:regex=>"^/servers", :value=>50, :verb=>"POST", :remaining=>50, :unit=>"DAY", :resetTime=>1272399820, :URI=>"/servers*"}
    #
    # This indicates that you can only run 50 POST operations against URLs in the /servers URI space per day, we have not run
    # any operations today (50 remaining), and gives the Unix time that the limits reset.
    #
    # Another example is:
    # 
    #   {:regex=>".*", :value=>10, :verb=>"PUT", :remaining=>10, :unit=>"MINUTE", :resetTime=>1272399820, :URI=>"*"}
    #
    # This says that you can run 10 PUT operations on all possible URLs per minute, and also gives the number remaining and the
    # time that the limit resets.
    #
    # Use this information as you're building your applications to put in relevant pauses if you approach your API limitations.
    def limits
      response = csreq("GET",svrmgmthost,"#{svrmgmtpath}/limits",svrmgmtport,svrmgmtscheme)
      CloudServers::Exception.raise_exception(response) unless response.code.match(/^20.$/)
      CloudServers.symbolize_keys(JSON.parse(response.body)['limits'])
    end
    
    private
    
    # Sets up standard HTTP headers
    def headerprep(headers = {}) # :nodoc:
      default_headers = {}
      default_headers["X-Auth-Token"] = @authtoken if (authok? && @account.nil?)
      default_headers["X-Storage-Token"] = @authtoken if (authok? && !@account.nil?)
      default_headers["Connection"] = "Keep-Alive"
      default_headers["User-Agent"] = "CloudServers Ruby API #{VERSION}"
      default_headers["Accept"] = "application/json"
      default_headers.merge(headers)
    end
    
    # Starts (or restarts) the HTTP connection
    def start_http(server,path,port,scheme,headers) # :nodoc:
      if (@http[server].nil?)
        begin
          @http[server] = Net::HTTP::Proxy(self.proxy_host, self.proxy_port).new(server,port)
          if scheme == "https"
            @http[server].use_ssl = true
            @http[server].verify_mode = OpenSSL::SSL::VERIFY_NONE
          end
          @http[server].start
        rescue
          raise ConnectionException, "Unable to connect to #{server}"
        end
      end
    end
    
    # Handles parsing the Personality hash to load it up with Base64-encoded data.
    def get_personality(options)
      return if options.nil?
      require 'base64'
      data = []
      itemcount = 0
      options.each do |localpath,svrpath|
        raise CloudServers::Exception::TooManyPersonalityItems, "Personality files are limited to a total of #{MAX_PERSONALITY_ITEMS} items" if itemcount >= MAX_PERSONALITY_ITEMS
        raise CloudServers::Exception::PersonalityFilePathTooLong, "Server-side path of #{svrpath} exceeds the maximum length of #{MAX_SERVER_PATH_LENGTH} characters" if svrpath.size > MAX_SERVER_PATH_LENGTH
        raise CloudServers::Exception::PersonalityFileTooLarge, "Local file #{localpath} exceeds the maximum size of #{MAX_PERSONALITY_FILE_SIZE} bytes" if File.size(localpath) > MAX_PERSONALITY_FILE_SIZE
        b64 = Base64.encode64(IO.read(localpath))
        data.push({:path => svrpath, :contents => b64})
        itemcount += 1
      end
      return data
    end
        
  end
end
