require 'test_helper'

class ImageTest < ActiveSupport::TestCase

#	fixtures :images
	fixtures :users
	fixtures :accounts

	test "create new image" do

		image=Image.new
		assert !image.valid?, "Image should not be valid."
		assert !image.save, "Image should not have been saved."

	end

	test "create image" do

		user=users(:bob)
		image=Image.new(
			:name => "Image 1",
			:image_ref => "1",
			:os_type => "linux",
			:account_id => user.account.id
		)

		assert image.valid?, "Image should be valid."
		assert image.save, "Image should have been saved."

	end

end
