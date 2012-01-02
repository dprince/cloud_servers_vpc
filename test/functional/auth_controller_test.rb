require 'test_helper'

class AuthControllerTest < ActionController::TestCase

  include AuthTestHelper

  test "should get login page" do
    post :index
    assert_response :success
  end

  test "should login" do
    post :login, :username => "admin", :password => "cloud"
    assert_redirected_to "/main#index"
  end

  test "failed login" do
    post :login, :username => "admin", :password => "zz"
    assert_response 401
  end

  test "attempt to login an inactive user" do
    post :login, :username => "john", :password => "cloud"
    assert_response 401
  end

  test "should logout" do
    login_as(:admin)
    post :logout
    assert_response :success
  end

  test "unauthorized logout" do
    post :logout
    assert_redirected_to "/"
  end

end
