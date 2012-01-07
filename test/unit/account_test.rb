require 'test_helper'

class AccountTest < ActiveSupport::TestCase

	fixtures :accounts
	fixtures :users

	test "create empty account" do

		account=Account.new
		assert account.valid?, "Account should be valid."
		assert account.save, "Account should have been saved."

	end

	test "create account" do

		account=Account.new(
			:username => "blah",
			:api_key => "ABABABABABAB"
		)
		assert account.valid?, "Account should be valid."
		assert account.save, "Account should have been saved."

		user=users(:bob)
		user.account = account
		user.save!

		account=Account.find(account.id)
		assert_equal account.user.id, users(:bob).id

	end

end
