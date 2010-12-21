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

	def range_endpoint?(ip_addr, cidr="/30")
		return if ip_addr.nil? or cidr.nil?
		range=IPAddr.new("#{ip_addr}#{cidr}").to_range.to_a
		return true if ip_addr == range.first.to_s or ip_addr == range.last.to_s
	end

end

end
