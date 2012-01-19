class CreateClientVPNCredentials

  @queue=:linux

  def self.perform(id)
    JobHelper.handle_retry do
      client = Client.find(id)
      client.create_vpn_credentials
    end
  end

end
