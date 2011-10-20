class SyncImages

  @queue=:linux

  def self.perform(id)
    user = User.find(id)
    Image.sync(user)
  end

end
