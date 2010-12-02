require 'test_helper'

class ServerTest < ActiveSupport::TestCase

	fixtures :server_groups
	fixtures :servers
	fixtures :users

	#Hard coded windows types: "28","31","24","23","29"
	# FIXME: create images lookup table
	test "create windows server" do

		server=Server.new_for_type(
			:name => "test1",
			:image_id => "28",
			:description => "test description",
			:flavor_id => 1,
			:account_id => users(:bob).account_id
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
			:flavor_id => 1,
			:openvpn_server => true,
			:account_id => users(:bob).account_id
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
			:flavor_id => 1,
			:account_id => users(:bob).account_id
		)

		group=server_groups(:one)
		group.servers << server

		assert server.save, "Server should have been saved."
		assert server.configure_openvpn_client("xx\nxx","yy\nyy","zz\nzz"), "Failed to stage VPN client configuration."

	end

end
