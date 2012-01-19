class MakeReserveServerHistorical

  @queue=:linux

  def self.perform(id)
    JobHelper.handle_retry do
      reserve_server = ReserveServer.find(id)
      reserve_server.make_historical
    end
  end

end
