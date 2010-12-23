class SshKeypair < ActiveRecord::Base

	validates_presence_of :public_key, :private_key
	belongs_to :server_group

end
