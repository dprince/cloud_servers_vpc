class MakeServerHistorical

  @queue=:linux

  def self.perform(id)
    JobHelper.handle_retry do
      server = Server.find(id)
      server.make_historical
    end
  end

end
