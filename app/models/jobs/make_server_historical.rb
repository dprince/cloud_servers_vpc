class MakeServerHistorical

  @queue=:linux

  def self.perform(id)
    server = Server.find(id)
    server.make_historical
  end

end
