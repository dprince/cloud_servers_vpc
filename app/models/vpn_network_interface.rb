require 'util/ip_validator'

class VpnNetworkInterface < ActiveRecord::Base

	validates_presence_of :vpn_ip_addr, :ptp_ip_addr
	validates_numericality_of :server_id
	belongs_to :server

    include Util::IpValidator

	def validate

		if not vpn_ip_addr.nil? and not is_valid_ip(vpn_ip_addr) then
			errors.add_to_base("Please specify a valid VPN ip address.")
		end

		if not ptp_ip_addr.nil? and not is_valid_ip(ptp_ip_addr) then
			errors.add_to_base("Please specify a valid PTP ip address.")
		end

	end

end
