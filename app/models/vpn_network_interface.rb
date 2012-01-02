require 'util/ip_validator'

class VpnNetworkInterface < ActiveRecord::Base

	validates_presence_of :vpn_ip_addr, :ptp_ip_addr
	validates_numericality_of :interfacable_id
	belongs_to :interfacable, :polymorphic => true

    include Util::IpValidator

	validate :handle_validate
	def handle_validate

		if not vpn_ip_addr.nil? and not is_valid_ip(vpn_ip_addr) then
			errors[:base] << "Please specify a valid VPN IP address."
		end

		if not ptp_ip_addr.nil? and not is_valid_ip(ptp_ip_addr) then
			errors[:base] << "Please specify a valid PTP IP address."
		end

		# This is a requirement of the Windows TAP driver
		if self.interfacable and self.interfacable.is_windows then
			if not subnets_match?(vpn_ip_addr, ptp_ip_addr, "255.255.255.252") then
				errors[:base] << "VPN IP address must be in the same /30 subnet."
			end

            if range_endpoint?(vpn_ip_addr, "/30") or range_endpoint?(ptp_ip_addr, "/30") then
                errors[:base] << "VPN IP addresses cannot be /30 endpoints."
            end

		end

	end

end
