class Reservation < ActiveRecord::Base
  belongs_to :user
  belongs_to :image, :primary_key => "image_ref", :foreign_key => "image_ref"
  validates_numericality_of :size
end
