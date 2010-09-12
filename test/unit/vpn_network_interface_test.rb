require 'test_helper'

class VpnNetworkInterfaceTest < ActiveSupport::TestCase

	fixtures :servers
	fixtures :server_groups
	fixtures :vpn_network_interfaces

	test "create a VPN network interface" do

		interface=VpnNetworkInterface.new(
			:vpn_ip_addr => "172.19.0.8",
			:ptp_ip_addr => "172.19.0.9"
		)

		server=servers(:one)
		server.vpn_network_interfaces << interface

		assert interface.valid?, "VPN network interface should be valid."
		assert interface.save!, "VPN network interface should be saved."

	end

	test "missing vpn ip" do

		interface=VpnNetworkInterface.new(
			:ptp_ip_addr => "172.19.0.9"
		)

		server=servers(:one)
		server.vpn_network_interfaces << interface

		assert !interface.valid?, "VPN network interface should not be valid."
		assert !interface.save, "VPN network interface should not be saved."

	end

end
