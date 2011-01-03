require 'test_helper'

class ServerGroupTest < ActiveSupport::TestCase

	fixtures :ssh_keypairs
	fixtures :server_groups
	fixtures :servers
	fixtures :users
	fixtures :accounts

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

		assert_not_nil sg.ssh_keypair.public_key, "Server group has a keypair public key."
		assert_not_nil sg.ssh_keypair.private_key, "Server group has a keypair private key."

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

	test "create with a single server" do

		sg=ServerGroup.create(
			:name => "test1",
			:user_id => users(:admin).id,
			:owner_name => "dan",
			:domain_name => "test.rsapps.net",
			:description => "test1",
			:vpn_network => "172.19.0.0",
			:vpn_subnet => "255.255.128.0"
		)
		sg.update_attributes(
			:servers_attributes => [{
				:name => "test1",
				:description => "test description",
				:flavor_id => 1,
				:image_id => 1,
				:account_id => users(:bob).account.id
			}]
		)
		assert sg.valid?, "Server group should be valid."
		assert sg.save!, "Server group should have saved."
		assert_equal 1, sg.servers.size

	end

	test "writes ssh keypair from DB" do

		sg=server_groups(:one)
		path=sg.ssh_key_basepath
		assert File.delete(path), "Failed to delete private key."
		assert File.delete(path+".pub"), "Failed to delete public key."

		# another call to ssh_key_basepath should write out the keys again
		sg.ssh_key_basepath
		private_key = IO.read(path)
		public_key = IO.read(path+".pub")

		assert_equal sg.ssh_keypair.private_key, private_key, "Private keys don't match."
		assert_equal sg.ssh_keypair.public_key, public_key, "Public keys don't match."

	end

end
