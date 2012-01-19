class CreateLinuxVPNClient

  @queue=:linux

  def self.perform(id)
    JobHelper.handle_retry do
      server = LinuxServer.find(id)
      server.create_openvpn_client
    end
  end

end
