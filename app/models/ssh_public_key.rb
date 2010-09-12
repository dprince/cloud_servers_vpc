class SshPublicKey < ActiveRecord::Base

	validates_presence_of :description, :public_key
	belongs_to :server_groups

end
