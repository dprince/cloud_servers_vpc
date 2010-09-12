require 'test_helper'

class ServersControllerTest < ActionController::TestCase

  include AuthTestHelper

  fixtures :server_groups
  fixtures :accounts
  fixtures :users

  test "should not get index" do
    get :index
    assert_response 302
  end

  test "should get index as user" do

	login_as(:bob)
    get :index
    assert_response :success
    assert_not_nil assigns(:servers)

    assert_select "table tr:nth-child(2) td:nth-child(4)", "server-one"

  end

  test "should get index as admin" do

	login_as(:admin)
    get :index
    assert_response :success
    assert_not_nil assigns(:servers)

    assert_select "table tr:nth-child(2) td:nth-child(4)", "server-one"

  end

  test "should not get index for historical records" do

    get :index, :historical => "1"
    assert_response 302

  end

  test "should get index for historical records as admin" do

	login_as(:admin)
    get :index, :historical => "1"
    assert_response :success
    assert_not_nil assigns(:servers)

    assert_select "table tr:nth-child(2) td:nth-child(4)", "server-historical"

  end

  test "should get index for historical records as user" do

	login_as(:bob)
    get :index, :historical => "1"
    assert_response :success
    assert_not_nil assigns(:servers)

  end

  test "should show server as admin" do
	login_as(:admin)
    get :show, :id => servers(:one).to_param
    assert_response :success
  end

  test "should not show server other users server" do
	login_as(:jim)
    get :show, :id => servers(:one).to_param
    assert_response 401
  end

  test "should not rebuild openvpn server" do
    http_basic_authorize
    post :rebuild, :id => servers(:one).to_param
    assert_response 400
  end

  test "should rebuild server as admin" do
    http_basic_authorize
    post :rebuild, :id => servers(:two).to_param
    assert_response :success
	server=Server.find(servers(:two).id)
	assert_equal "Rebuilding", server.status
  end

  test "should not rebuild other users server" do
    http_basic_authorize(:jim)
    post :rebuild, :id => servers(:one).to_param
    assert_response 401
  end

end
