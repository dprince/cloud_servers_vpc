require 'test_helper'

class ServerTest < ActiveSupport::TestCase

	fixtures :users

	test "create user" do

		user=User.new(
			:username => "test1",
			:first_name => "Mr.",
			:last_name => "Big",
			:password => "test123",
			:account_attributes => {:username => "test", :api_key => "AABBCCDD"}
		)
		assert user.valid?, "User should be valid."
		assert user.save, "User should have been saved."

	end

	test "create user fails with invalid account" do

		ENV['CLOUD_SERVERS_UTIL_INIT_MOCK_FAIL']="true"
		user=User.new(
			:username => "test1",
			:first_name => "Mr.",
			:last_name => "Big",
			:password => "test123",
			:account_attributes => {:username => "test", :api_key => "AABBCCDD"}
		)
		assert_equal false, user.valid?, "User should not be valid."

	end

	test "create duplicate username" do

		user=User.new(
			:username => "admin",
			:first_name => "Mr.",
			:last_name => "Big",
			:password => "test123",
			:account_attributes => {:username => "test", :api_key => "AABBCCDD"}
		)
		assert_equal false, user.valid?, "User should not be valid."
		assert_equal false, user.save, "User should not save."

	end

	test "username with space" do

		user=User.new(
			:username => "mr big",
			:first_name => "Mr.",
			:last_name => "Big",
			:password => "test123",
			:account_attributes => {:username => "test", :api_key => "AABBCCDD"}
		)
		assert_equal false, user.valid?, "User should not be valid."
		assert_equal false, user.save, "User should not save."

	end

	test "user with ssh keys" do

		user=User.new(
			:username => "testsshkey",
			:first_name => "Test",
			:last_name => "SshKey",
			:password => "test123",
			:account_attributes => {:username => "test", :api_key => "AABBCCDD"}
		)
		assert_equal true, user.save, "User should save."

		user.ssh_public_keys << SshPublicKey.create(:description => "Work", :public_key => "AABBCCDD112233")

		assert_equal true, user.save, "User should save."

		assert_equal "Work", user.ssh_public_keys[0].description
		assert_equal "AABBCCDD112233", user.ssh_public_keys[0].public_key

		user.ssh_public_keys << SshPublicKey.create(:description => "Home", :public_key => "AABBCCDD11223344")

		assert_equal true, user.save, "User should save."

		assert_equal 2, user.ssh_public_keys.size, "User should have two keys."


	end

	test "user authenticate" do
		assert User.authenticate(users(:admin).username, "cloud")
	end

end
