class ReserveServer < ActiveRecord::Base
  validates_presence_of :flavor_ref, :image_ref, :reservation_id, :cloud_server_id, :status
end
