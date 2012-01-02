require 'ipaddr'

module Util

	module IpIncrementer

		attr_reader :ip_inc_last_used_ip_address

		@ip_inc_last_used_ip_address=nil

		# initialize the starting IP address
		# defaults to class B private address range
		def init_ip(ip_address="172.16.0.0")
			@ip_inc_last_used_ip_address=IPAddr.new(ip_address, Socket::AF_INET)
			return true
		end
	
		# increment the existing IP Address and return a printable
		# string of the next IP
		def next_ip
			init_ip if @ip_inc_last_used_ip_address.nil?
			ip=IPAddr.new(@ip_inc_last_used_ip_address.to_i + 1, Socket::AF_INET)
			@ip_inc_last_used_ip_address=ip
			ip.to_s
		end

	end

end
