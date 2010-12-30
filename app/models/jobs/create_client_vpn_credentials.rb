class CreateClientVPNCredentials

  @queue=:linux

  def self.perform(id)
    client = Client.find(id)
    client.create_vpn_credentials
  end

end
