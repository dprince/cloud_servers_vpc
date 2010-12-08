require 'test_helper'

class ServerTest < ActiveSupport::TestCase

	fixtures :server_groups
	fixtures :servers
	fixtures :users

	test "create server" do

		server=Server.new(
			:name => "test1",
			:description => "test description",
			:flavor_id => 1,
			:image_id => 1,
			:account_id => users(:bob).account_id
		)

		group=server_groups(:one)
		group.servers << server

		assert server.valid?, "Server should be valid."
		assert server.save, "Server should have been saved."

		server=Server.find(server.id)

		assert_equal users(:bob).account, server.account

	end

	test "create server with dash and dot" do

		server=Server.new(
			:name => "test1-.",
			:description => "test description",
			:flavor_id => 1,
			:image_id => 1,
			:account_id => users(:bob).account_id
		)

		group=server_groups(:one)
		group.servers << server

		assert server.valid?, "Server should be valid."
		assert server.save, "Server should have been saved."

		server=Server.find(server.id)

		assert_equal users(:bob).account, server.account

	end

	test "missing name" do

		server=Server.new(
			:description => "test description",
			:flavor_id => 1,
			:image_id => 1,
			:account_id => users(:bob).account_id
		)

		group=server_groups(:one)
		group.servers << server

		assert !server.valid?, "Server should not be valid."
		assert !server.save, "Server should not be saved."

	end

	test "missing description" do

		server=Server.new(
			:name => "test1",
			:flavor_id => 1,
			:image_id => 1,
			:account_id => users(:bob).account_id
		)

		group=server_groups(:one)
		group.servers << server

		assert !server.valid?, "Server should not be valid."
		assert !server.save, "Server should not be saved."

	end

	test "missing group" do

		server=Server.new(
			:name => "test1",
			:description => "test description",
			:flavor_id => 1,
			:image_id => 1,
			:account_id => users(:bob).account_id
		)

		assert !server.valid?, "Server should not be valid."
		assert !server.save, "Server should not be saved."

	end

	test "create server with VPN network interfaces" do

		server=Server.new(
			:name => "test1",
			:description => "test description",
			:flavor_id => 1,
			:image_id => 1,
			:num_vpn_network_interfaces => 3,
			:account_id => users(:bob).account_id
		)

		group=server_groups(:one)
		group.servers << server

		assert server.valid?, "Server should be valid."
		assert server.save, "Server should have been saved."

		assert_equal 3, server.vpn_network_interfaces.size, "3 VPN network interfaces should have been created."

		# Group :one's last used IP address is 172.19.0.2.
		# This is the IP of the OpenVPN server itself.
		# One IP address is popped to ensure they are on the same /30 subnets.
		# We created a server with 3 VPN interfaces each of which use
		# two IP's. If 172.19.0.9 exists then we should be good.
		vpn_ip_count=VpnNetworkInterface.count(:conditions => "ptp_ip_addr = '172.19.0.9'")
		assert_equal 1, vpn_ip_count, "VPN interface IP are not getting properly incremented."

	end

	test "verify server names are unique within a group" do

		server=Server.new(
			:name => servers(:one).name,
			:description => "test description",
			:flavor_id => 1,
			:image_id => 1,
			:num_vpn_network_interfaces => 3,
			:account_id => users(:bob).account_id
		)
		group=server_groups(:one)
		group.servers << server

		assert !server.valid?, "Server should be allowed to have duplicate names."
		assert !server.save, "Server should be allowed to have duplicate names."

	end

	test "create server with invalid name" do

		server=Server.new(
			:name => "test 1_*",
			:description => "test description",
			:flavor_id => 1,
			:image_id => 1,
			:account_id => users(:bob).account_id
		)

		group=server_groups(:one)
		group.servers << server

		assert !server.valid?, "Server should be not be valid. (invalid hostname)"
		assert !server.save, "Server not should have been saved. (invalid hostname)"

	end

end
