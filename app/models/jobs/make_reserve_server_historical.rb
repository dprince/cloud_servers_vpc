class MakeReserveServerHistorical

  @queue=:linux

  def self.perform(id)
    reserve_server = ReserveServer.find(id)
    reserve_server.make_historical
  end

end
