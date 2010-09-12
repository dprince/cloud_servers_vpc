class ServerError < ActiveRecord::Base

	validates_presence_of :error_message
	belongs_to :server

end
