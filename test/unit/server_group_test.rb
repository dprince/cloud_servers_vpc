require 'test_helper'

class ServerGroupTest < ActiveSupport::TestCase

	fixtures :server_groups
	fixtures :servers
	fixtures :users

	test "create" do

		sg=ServerGroup.new(
			:name => "test1",
			:user_id => users(:admin).id,
			:owner_name => "dan",
			:domain_name => "test.rsapps.net",
			:description => "test1",
			:vpn_network => "172.19.0.0",
			:vpn_subnet => "255.255.128.0"
		)
		assert sg.valid?, "Server group should be valid."
		assert sg.save!, "Server group should have saved."

	end

	test "invalid vpn network" do

		sg=ServerGroup.new(
			:name => "test1",
			:owner_name => "dan",
			:domain_name => "test.rsapps.net",
			:description => "test1",
			:vpn_network => "172.19.0",
			:vpn_subnet => "255.255.128.0"
		)
		assert !sg.valid?, "Server group is invalid (incorrect VPN network)."
		assert !sg.save, "Server group should not have saved."

	end

	test "invalid vpn subnet" do

		sg=ServerGroup.new(
			:name => "test1",
			:owner_name => "dan",
			:domain_name => "test.rsapps.net",
			:description => "test1",
			:vpn_network => "172.19.0.0",
			:vpn_subnet => "255.255.128.300"
		)
		assert !sg.valid?, "Server group is invalid (incorrect VPN subnet)."
		assert !sg.save, "Server group should not have saved."

	end

	test "missing name" do

		sg=ServerGroup.new(
			:owner_name => "dan",
			:description => "test1",
			:domain_name => "test.rsapps.net",
			:vpn_network => "172.19.0.0",
			:vpn_subnet => "255.255.128.1"
		)
		assert !sg.valid?, "Server group is invalid (missing name)."
		assert !sg.save, "Server group should not have saved."

	end

	test "missing description" do

		sg=ServerGroup.new(
			:name => "test",
			:owner_name => "dan",
			:domain_name => "test.rsapps.net",
			:vpn_network => "172.19.0.0",
			:vpn_subnet => "255.255.128.1"
		)
		assert !sg.valid?, "Server group is invalid (missing description)."
		assert !sg.save, "Server group should not have saved."

	end

	test "missing owner" do

		sg=ServerGroup.new(
			:name => "test",
			:description => "test1",
			:domain_name => "test.rsapps.net",
			:vpn_network => "172.19.0.0",
			:vpn_subnet => "255.255.128.1"
		)
		assert !sg.valid?, "Server group is invalid (missing owner)."
		assert !sg.save, "Server group should not have saved."

	end

	test "do not allow more than one OpenVPN server" do

		server=Server.new(
			:name => "test1",
			:description => "test description",
			:flavor_id => 1,
			:image_id => 1,
			:openvpn_server => true
		)

		group=server_groups(:one)
		group.servers << server

		assert !group.valid?, "Server groups cannot have more than one VPN server."
		assert !group.save, "Server groups cannot have more than one VPN server."
	end

end
