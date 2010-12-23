require 'test_helper'

class ServerCommandTest < ActiveSupport::TestCase

	fixtures :servers
	fixtures :server_commands

	# this is normal done automatically when the server is initialized
	test "create server command" do

		command=ServerCommand.new(
			:command => "/bin/true"
		)

		server=servers(:one)
		server.server_command = command

		assert command.valid?, "ServerCommand should be valid."
		assert command.save, "ServerCommand should have been saved."

		assert_not_nil server.server_command, "Server.server_command was nil."

	end

	test "server command is deleted with server" do

		server=servers(:one)
		assert server.destroy

		assert_raise ActiveRecord::RecordNotFound do	
			server_commands(:one)
		end

	end

end
