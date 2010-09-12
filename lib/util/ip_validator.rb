require 'ipaddr'

module Util

module IpValidator

	def is_valid_ip(ip_string)

		begin
			IPAddr.new(ip_string)
			return true
		rescue
			return false
		end

	end

end

end
