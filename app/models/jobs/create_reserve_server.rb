class CreateReserveServer

  @queue=:linux

  def self.perform(id)
    JobHelper.handle_retry do
      reserve_server = ReserveServer.find(id)
      reserve_server.create_reserve_server
    end
  end

end
