class CreateCloudServer

  @queue=:linux

  def self.perform(id, schedule_client_openvpn=false)
    JobHelper.handle_retry do
      server = Server.find(id)
      server.create_cloud_server(schedule_client_openvpn)
    end
  end

end
