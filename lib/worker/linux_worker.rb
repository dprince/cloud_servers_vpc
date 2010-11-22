module Worker
  
  class LinuxWorker
  
    include Minion

	@logger

    def initialize(logger)
		@logger=logger
		logger do |msg|
			@logger.info("Worker(#{Process.pid}): "+msg)
		end
    end
      
    def start

      log "Starting worker!"

      job "create.cloud.server" do |args|
        log "Create Cloud Server: #{args.inspect}"
        begin
          server=Server.find(args["server_id"])
          server.create_cloud_server(args["schedule_client_openvpn"] == "true") 
        rescue Exception => e
          log "ERROR: Failed to create cloud server: #{e.message}"
        end
      end
      
      job "create.openvpn.client" do |args|
        log "Create OpenVPN Client: #{args.inspect}"
        begin
          server=Server.find(args["server_id"])
          server.create_openvpn_client
        rescue Exception => e
          log "ERROR: Failed to install openvpn client: #{e.message}"
        end
      end
      
      job "create.openvpn.server" do |args|
        log "Create OpenVPN Server: #{args.inspect}"
        begin
          server=Server.find(args["server_id"])
          server.create_openvpn_server
        rescue Exception => e
          log "ERROR: Failed to install openvpn server: #{e.message}"
        end
      end
      
      job "server.rebuild" do |args|
        log "Server Rebuild: #{args.inspect}"
        begin
          server=Server.find(args["server_id"])
          server.rebuild
        rescue Exception => e
          log "ERROR: Failed to rebuild server: #{e.message}"
        end
      end
      
      job "server_group.make_historical" do |args|
        log "Server Group Make Historical: #{args.inspect}"
        begin
          server_group=ServerGroup.find(args["server_group_id"])
          server_group.make_historical
        rescue Exception => e
          log "ERROR: Failed to make group historical: #{e.message}"
        end
      end
      
    end
      
  end
  
end
