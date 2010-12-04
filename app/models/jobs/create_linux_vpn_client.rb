class CreateLinuxVPNClient

  @queue=:linux

  def self.perform(id)
    server = LinuxServer.find(id)
    server.create_openvpn_client
  end

end
