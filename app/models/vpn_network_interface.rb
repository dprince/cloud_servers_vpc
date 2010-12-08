require 'util/ip_validator'

class VpnNetworkInterface < ActiveRecord::Base

	validates_presence_of :vpn_ip_addr, :ptp_ip_addr
	validates_numericality_of :server_id
	belongs_to :server

    include Util::IpValidator

	def validate

		if not vpn_ip_addr.nil? and not is_valid_ip(vpn_ip_addr) then
			errors.add_to_base("Please specify a valid VPN IP address.")
		end

		if not ptp_ip_addr.nil? and not is_valid_ip(ptp_ip_addr) then
			errors.add_to_base("Please specify a valid PTP IP address.")
		end

		# This is a requirement of the Windows TAP driver
		# It doesn't hurt to do it for Linux machines as well
		if self.server.type == "WindowsServer" then
			if not subnets_match?(vpn_ip_addr, ptp_ip_addr, "255.255.255.252") then
				errors.add_to_base("VPN IP address must be in the same /30 subnet.")
			end

            if range_endpoint?(vpn_ip_addr, "/30") or range_endpoint?(ptp_ip_addr, "/30") then
                errors.add_to_base("VPN IP addresses cannot be /30 endpoints.")
            end

		end

	end

end
