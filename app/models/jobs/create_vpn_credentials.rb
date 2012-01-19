class CreateVPNCredentials

  @queue=:linux

  def self.perform(id)
    JobHelper.handle_retry do
      server = WindowsServer.find(id)
      creds=server.create_vpn_credentials
      Resque.enqueue(ConfigureWindowsVPNClient, server.id, creds[0], creds[1], creds[2])
    end
  end

end
