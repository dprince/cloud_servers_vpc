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

	def subnets_match?(addr1, addr2, mask)
		return false if addr1.nil? or addr2.nil? or mask.nil?
		ip1=IPAddr.new(addr1)
		ip2=IPAddr.new(addr2)
		return ip1.mask(mask) == ip2.mask(mask)
	end

end

end
