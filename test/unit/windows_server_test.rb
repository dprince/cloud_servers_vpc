require 'test_helper'

class ServerTest < ActiveSupport::TestCase

	fixtures :server_groups
	fixtures :servers
	fixtures :users
	fixtures :accounts

	#Hard coded windows types: "28","31","24","23","29"
	# FIXME: create images lookup table
	test "create windows server" do

		server=Server.new_for_type(
			:name => "test1",
			:image_id => "28",
			:description => "test description",
			:flavor_id => 3,
			:account_id => users(:bob).account.id
		)

		group=server_groups(:one)
		group.servers << server

		assert server.valid?, "Server should be valid."
		assert server.save, "Server should have been saved."

		server=Server.find(server.id)

		assert_equal users(:bob).account, server.account
		assert_equal "WindowsServer", server.type

	end

	test "validate windows cannot be an openvpn server" do

		server=Server.new_for_type(
			:name => "test1",
			:image_id => "28",
			:description => "test description",
			:flavor_id => 3,
			:openvpn_server => true,
			:account_id => users(:bob).account.id
		)

		group=server_groups(:one)
		group.servers << server

		assert !server.valid?, "Server should not be valid."
		assert !server.save, "Server should not have been saved."

	end

	test "configure VPN" do

		server=Server.new_for_type(
			:name => "test1",
			:image_id => "28",
			:description => "test description",
			:flavor_id => 3,
			:account_id => users(:bob).account.id
		)

		group=server_groups(:one)
		group.servers << server

		assert server.save, "Server should have been saved."
		assert server.configure_openvpn_client("xx\nxx","yy\nyy","zz\nzz"), "Failed to stage VPN client configuration."

	end

	test "windows flavor less than 1G invalid" do

		server=Server.new_for_type(
			:name => "test1",
			:image_id => "28",
			:description => "test description",
			:flavor_id => 2,
			:account_id => users(:bob).account.id
		)

		group=server_groups(:one)
		group.servers << server

		assert !server.valid?, "Server should not be valid."
		assert !server.save, "Server should not have been saved."

	end

    test "create windows server with 2 VPN network interfaces" do

        server=Server.new(
            :name => "test1",
            :description => "test description",
            :flavor_id => 3,
            :image_id => 28,
            :num_vpn_network_interfaces => 2,
            :account_id => users(:bob).account.id
        )   
            
        group=server_groups(:one)
        group.servers << server

        assert server.valid?, "Server should be valid."
        assert server.save, "Server should have been saved."

        assert_equal 2, server.vpn_network_interfaces.size, "3 VPN network interfaces should have been created."

        # If 172.19.0.10 exists then we should be good.
        vpn_ip_count=VpnNetworkInterface.count(:conditions => "ptp_ip_addr = '172.19.0.10'")
        assert_equal 1, vpn_ip_count, "VPN interface IP are not getting properly incremented for Windows."

    end

end
