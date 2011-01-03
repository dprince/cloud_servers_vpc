require 'test_helper'

class ServerErrorTest < ActiveSupport::TestCase

	fixtures :server_groups
	fixtures :servers
	fixtures :accounts
	fixtures :users

	test "create server error" do

		server=Server.new(
			:name => "test1",
			:description => "test description",
			:flavor_id => 1,
			:image_id => 1,
            :account_id => users(:bob).account.id
		)

		server.server_errors << ServerError.new(:error_message => "test")

		group=server_groups(:one)
		group.servers << server

		assert server.valid?, "Server should be valid."
		assert server.save, "Server should have been saved."

		assert_equal 1, server.server_errors.size, "Server errors count should be 1."

	end

end
