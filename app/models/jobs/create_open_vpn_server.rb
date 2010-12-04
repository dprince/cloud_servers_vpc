class CreateOpenVPNServer

  @queue=:linux

  def self.perform(id)
    server = LinuxServer.find(id)
    server.create_openvpn_server
  end

end
