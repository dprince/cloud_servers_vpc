class SshPublicKey < ActiveRecord::Base

	validates_presence_of :description, :public_key
	belongs_to :server_group
	belongs_to :user

end
