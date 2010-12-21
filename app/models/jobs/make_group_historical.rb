class MakeGroupHistorical

  @queue=:linux

  def self.perform(id)
    server = ServerGroup.find(id)
    server.make_historical
  end

end
