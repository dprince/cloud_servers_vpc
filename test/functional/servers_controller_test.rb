require 'test_helper'

class ServersControllerTest < ActionController::TestCase

  include AuthTestHelper

  fixtures :server_groups
  fixtures :accounts
  fixtures :users
  fixtures :images

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

  test "should get index as admin for bob" do

    login_as(:admin)
    get :index, :server_group_id => server_groups(:one)
    assert_response :success
    assert_not_nil assigns(:servers)

  end

  test "jim should not get index for bob" do

    login_as(:jim)
    get :index, :server_group_id => server_groups(:one)
    assert_response 401

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

  test "should get JSON index for historical records as user" do

    login_as(:bob)
    get :index, :historical => "1", :format => "json"
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
    assert_equal server.id, AsyncExec.jobs[RebuildServer][0]
  end

  test "should not rebuild other users server" do
    http_basic_authorize(:jim)
    post :rebuild, :id => servers(:one).to_param
    assert_response 401
  end

  test "should create server as admin" do
    http_basic_authorize
    assert_difference('Server.count') do
      post :create, :server => {:name => "test1", :description => "test description", :flavor_id => 1, :image_id => 1, :server_group_id => server_groups(:one).id}
    end
    assert_response :success
  end

  test "should create server" do
    http_basic_authorize(:bob)
    assert_difference('Server.count') do
      post :create, :server => {:name => "test1", :description => "test description", :flavor_id => 1, :image_id => 1, :server_group_id => server_groups(:one).id}
    end
    assert_response :success
  end

  test "should not create server in another users group" do
    http_basic_authorize(:jim)
    assert_no_difference('Server.count') do
      post :create, :server => {:name => "test1", :description => "test description", :flavor_id => 1, :image_id => 1, :server_group_id => server_groups(:one).id}
    end
    assert_response 401
  end

  test "unauthorized create fails" do
    post :create, :server => {:name => "test1", :description => "test description", :flavor_id => 1, :image_id => 1, :server_group_id => server_groups(:one).id}
    assert_response 302
  end

  test "should create server via XML request" do

    http_basic_authorize(:bob)
    assert_difference('Server.count') do

@request.env['RAW_POST_DATA'] = %{
<server>
  <name>test1</name>
  <description>test1</description>
  <flavor-id type="integer">1</flavor-id>
  <image-id type="integer">1</image-id>
  <server-group-id type="integer">#{server_groups(:one).id}</server-group-id>
  <base64-command>#{Base64.encode64("echo hello > /tmp/test.txt")}</base64-command>
</server>
}

@request.accept = 'text/xml'
response=post :create
@request.env.delete('RAW_POST_DATA')

    end

    assert_response :success

    server=Server.find(:first, :conditions => ["name = 'test1'"])
    assert_equal "echo hello > /tmp/test.txt", server.server_command.command

  end

  test "should create server where VPN server is online via JSON request" do

    http_basic_authorize(:bob)
    assert_difference('Server.count') do

@request.env['RAW_POST_DATA'] = %{
	{
		"name": "test1",
		"description": "test1",
		"flavor_id": 4,
		"image_id": 14,
		"server_group_id": #{server_groups(:one).id}
	}
}

@request.accept = 'application/json'
response=post :create
@request.env.delete('RAW_POST_DATA')

      assert_response :success

    end

    server=Server.find(:first, :conditions => ["name = 'test1'"])

    assert_not_nil AsyncExec.jobs[CreateCloudServer]
    assert_equal server.id, AsyncExec.jobs[CreateCloudServer][0]
    assert_equal true, AsyncExec.jobs[CreateCloudServer][1]

  end

  test "should create server via JSON request" do

    http_basic_authorize(:jim)
    assert_difference('Server.count') do

@request.env['RAW_POST_DATA'] = %{
	{
		"name": "test1",
		"description": "test1",
		"flavor_id": 4,
		"image_id": 14,
		"server_group_id": #{server_groups(:two).id}
	}
}

@request.accept = 'application/json'
response=post :create
@request.env.delete('RAW_POST_DATA')

      assert_response :success

    end

    server=Server.find(:first, :conditions => ["name = 'test1'"])

    assert_not_nil AsyncExec.jobs[CreateCloudServer]
    assert_equal server.id, AsyncExec.jobs[CreateCloudServer][0]
    assert_nil AsyncExec.jobs[CreateCloudServer][1]

  end

  test "should create openvpn server via JSON request" do

    http_basic_authorize(:jim)
    assert_difference('Server.count') do

@request.env['RAW_POST_DATA'] = %{
	{
		"name": "test1",
		"description": "test1",
		"flavor_id": 4,
		"image_id": 14,
		"openvpn_server": true,
		"server_group_id": #{server_groups(:two).id}
	}
}

@request.accept = 'application/json'
response=post :create
@request.env.delete('RAW_POST_DATA')

      assert_response :success

    end

    server=Server.find(:first, :conditions => ["name = 'test1'"])
    assert_not_nil AsyncExec.jobs[CreateCloudServer]
    assert_equal server.id, AsyncExec.jobs[CreateCloudServer][0]
    assert_nil AsyncExec.jobs[CreateCloudServer][1]

  end

  test "should destroy server" do
    http_basic_authorize(:bob)
    delete :destroy, :id => servers(:one).to_param

    server=Server.find(servers(:one).id)
    assert_equal true, server.historical

    assert_equal server.id, AsyncExec.jobs[MakeServerHistorical][0]

  end

  test "jim should not destroy bobs server" do
    login_as(:jim)
    delete :destroy, :id => servers(:two).to_param
    server=Server.find(servers(:two).id)
    assert_equal false, server.historical
  end

  test "should not destroy server if not authenticated" do
    delete :destroy, :id => servers(:one).to_param
    server=Server.find(servers(:one).id)
    assert_equal false, server.historical
  end

end
