require 'test_helper'

class ServerErrorsControllerTest < ActionController::TestCase

  include AuthTestHelper

  fixtures :server_errors
  fixtures :servers
  fixtures :users

  test "should not get index" do
    get :index
    assert_response 302
  end

  test "should get index as admin" do

	login_as(:admin)
    get :index
    assert_response :success
    assert_not_nil assigns(:server_errors)

  end

  test "should get index as user" do

	login_as(:bob)
    get :index, :server_id => servers(:one).id
    assert_response :success
    assert_not_nil assigns(:server_errors)

  end

  test "should not get other users index" do

	login_as(:jim)
    get :index, :server_id => servers(:one).id
    assert_response 401

  end

end
