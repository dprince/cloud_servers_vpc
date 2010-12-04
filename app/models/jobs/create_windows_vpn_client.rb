class CreateWindowsVPNClient

  @queue=:windows

  def self.perform(id)
    server = WindowsServer.find(id)
    server.create_openvpn_client
  end

end
