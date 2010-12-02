module Worker
  
  class WindowsWorker
  
    include Minion

	@logger

    def initialize(logger)
		@logger=logger
		logger do |msg|
			puts("Worker(#{Process.pid}): "+msg)
			@logger.info("Worker(#{Process.pid}): "+msg)
		end
    end
      
    def start

      log "Starting worker!"

      job "create.windows.openvpn.client" do |args|
        log "Create Windows OpenVPN Client: #{args.inspect}"
        begin
          windows_server=Server.find(args["server_id"])
          windows_server.create_openvpn_client
        rescue Exception => e
          log "ERROR: Failed to install windows openvpn client: #{e.message}"
        end
      end

      job "configure.windows.vpn.credentials" do |args|
        log "Create Windows VPN Credentials."
        begin
          Minion.enqueue([ "configure.windows.vpn.credentials" ], {"server_id" => args["server_id"], "client_key" => args["client_key"], "client_cert" => args["client_cert"], "ca_cert" => args["ca_cert"]})

          windows_server=Server.find(args["server_id"])
          windows_server.configure_openvpn_client(args["client_key"], args["client_cert"], args["ca_cert"])
        rescue Exception => e
          log "ERROR: Failed to configure windows VPN credentials: #{e.message}"
        end
      end
      
    end
      
  end
  
end
