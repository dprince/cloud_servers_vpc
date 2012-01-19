class CreateWindowsVPNClient

  @queue=:windows

  def self.perform(id)
    JobHelper.handle_retry do
      server = WindowsServer.find(id)
      server.create_openvpn_client
    end
  end

end
