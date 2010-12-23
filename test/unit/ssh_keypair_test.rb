require 'test_helper'

class RootSshKeypairTest < ActiveSupport::TestCase

	fixtures :server_groups

	test "create ssh keypair" do

		keypair=SshKeypair.new(
			:public_key => "blah",
			:private_key => "blah"
		)
		server_groups(:one).ssh_keypair=keypair

		assert keypair.valid?, "Root ssh keypair should be valid."
		assert keypair.save, "Root ssh keypair should have been saved."

	end

	test "requires private key" do

		keypair=SshKeypair.new(
			:public_key => "blah"
		)

		assert_equal(false, keypair.valid?, "Root ssh keypair should be invalid.")
		assert_equal(false, keypair.save, "Root ssh keypair not save.")

	end

	test "requires public key" do

		keypair=SshKeypair.new(
			:private_key => "blah"
		)

		assert_equal(false, keypair.valid?, "Root ssh keypair should be invalid.")
		assert_equal(false, keypair.save, "Root ssh keypair not save.")

	end

end
