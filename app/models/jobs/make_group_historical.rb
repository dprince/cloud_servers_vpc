class MakeGroupHistorical

  @queue=:linux

  def self.perform(id)
    JobHelper.handle_retry do
      server = ServerGroup.find(id)
      server.make_historical
    end
  end

end
