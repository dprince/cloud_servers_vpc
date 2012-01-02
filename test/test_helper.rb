ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require File.expand_path(File.dirname(__FILE__) + "/mocks/test/async_exec")
require File.expand_path(File.dirname(__FILE__) + "/mocks/test/cloud_servers_util")

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.(yml|csv) for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  fixtures :all

  # Add more helper methods to be used by all tests here...
end

module AuthTestHelper

  def login_as(user_sym)
    @request.session[:user_id] = user_sym ? users(user_sym).id : nil
  end

  def http_basic_authorize(user_sym = :admin)
    @request.env["HTTP_AUTHORIZATION"] = ActionController::HttpAuthentication::Basic.encode_credentials(users(user_sym).username, 'cloud')
  end

end
