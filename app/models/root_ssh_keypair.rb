class RootSshKeypair < ActiveRecord::Base

	validates_presence_of :public_key, :private_key
	has_one :server_group

end
