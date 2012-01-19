class RebuildServer

  @queue=:linux

  def self.perform(id)
    JobHelper.handle_retry do
      server = Server.find(id)
      server.rebuild
    end
  end

end
