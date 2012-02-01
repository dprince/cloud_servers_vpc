class Reservation < ActiveRecord::Base
  has_many :reserve_servers, :conditions => "historical = 0"
  belongs_to :user
  belongs_to :image, :primary_key => "image_ref", :foreign_key => "image_ref"
  validates_numericality_of :size
  validates_presence_of :flavor_ref, :image_ref, :user_id, :size

  after_create :handle_after_create
  def handle_after_create
    self.size.times do
      make_reserve_server
    end
  end

  def sync

    # if there are too many servers delete some
    server_count = 0
    if self.reserve_servers.size > self.size then
      (self.reserve_servers.size - self.size).times do |i|
        AsyncExec.run_job(MakeReserveServerHistorical, self.reserve_servers[i-1].id)
      end
    end

    # make the servers match the reservation
    server_count = 0
    self.reserve_servers.each do |reserve_server|
      server_count += 1
      if reserve_server.flavor_ref != self.flavor_ref or
         reserve_server.image_ref != self.image_ref then
        AsyncExec.run_job(MakeReserveServerHistorical, reserve_server.id)
        make_reserve_server
      end
      if reserve_server.created_at < 1.day.ago and reserve_server.status == 'Pending' then
        AsyncExec.run_job(MakeReserveServerHistorical, reserve_server.id)
      end
    end

    # add extras
    (self.size - server_count).times do
      make_reserve_server
    end

  end

  def make_reserve_server
   reserve_server = ReserveServer.create(
      :reservation_id => self.id,
      :flavor_ref => self.flavor_ref,
      :image_ref => self.image_ref,
      :account_id => self.user.account.id
    )
    AsyncExec.run_job(CreateReserveServer, reserve_server.id)
  end

  def make_historical
    update_attribute(:historical, true)
    self.reserve_servers.each do |reserve_server|
      AsyncExec.run_job(MakeReserveServerHistorical, reserve_server.id)
    end
  end

end
