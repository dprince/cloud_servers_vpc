class RebuildServer

  @queue=:linux

  def self.perform(id)
    server = Server.find(id)
    server.rebuild
  end

end
