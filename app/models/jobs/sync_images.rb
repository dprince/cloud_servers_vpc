class SyncImages

  @queue=:linux

  def self.perform(id)
    JobHelper.handle_retry do
      user = User.find(id)
      Image.sync(user)
    end
  end

end
