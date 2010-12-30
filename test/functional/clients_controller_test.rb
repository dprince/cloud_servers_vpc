require 'test_helper'
require 'async_exec'

class ClientsControllerTest < ActionController::TestCase

  include AuthTestHelper

  fixtures :clients
  fixtures :server_groups
  fixtures :users

  test "should not get index" do
    get :index
    assert_response 302
  end

  test "should get index as user" do

    login_as(:bob)
    @request.env['HTTP_ACCEPT'] = 'application/xml'
    get :index
    assert_response :success
    assert_not_nil assigns(:clients)

    assert_select "clients client name", "client-one"

  end

  test "should get index as admin" do

    login_as(:admin)
    @request.env['HTTP_ACCEPT'] = 'application/xml'
    get :index
    assert_response :success
    assert_not_nil assigns(:clients)

    assert_select "clients client name", "client-one"

  end

  test "should get index as admin for bob" do

    login_as(:admin)
    @request.env['HTTP_ACCEPT'] = 'application/xml'
    get :index, :server_group_id => server_groups(:one)
    assert_response :success
    assert_not_nil assigns(:clients)

  end

  test "jim should not get index for bob" do

    login_as(:jim)
    @request.env['HTTP_ACCEPT'] = 'application/xml'
    get :index, :server_group_id => server_groups(:one)
    assert_response 401

  end

  test "should show server" do
    login_as(:bob)
    get :show, :id => clients(:one).to_param
    assert_response :success
  end

  test "should show XML server" do

	assert VpnNetworkInterface.create(
		:vpn_ip_addr => "172.19.0.5",
		:ptp_ip_addr => "172.19.0.6",
		:interfacable_id => clients(:one).id,
		:interfacable_type => 'Client'
	)

    login_as(:bob)
    @request.env['HTTP_ACCEPT'] = 'application/xml'
    get :show, :id => clients(:one).to_param
    assert_response :success
    assert_select "client vpn-network-interfaces vpn-network-interface ca-cert", ""
  end

  test "should show server as admin" do
    login_as(:admin)
    get :show, :id => clients(:one).to_param
    assert_response :success
  end

  test "should not show server other users server" do
    login_as(:jim)
    get :show, :id => clients(:one).to_param
    assert_response 401
  end

  test "should create client" do
    http_basic_authorize
    assert_difference('Client.count') do
      post :create, :client => {:name => "test1", :description => "test description", :server_group_id => server_groups(:one).id}
    end
    assert_response :success
  end

  test "unauthorized create fails" do
    post :create, :client => {:name => "test1", :description => "test description", :server_group_id => server_groups(:one).id}
    assert_response 302
  end

  test "should create client via XML request" do

    http_basic_authorize
    assert_difference('Client.count') do

@request.env['RAW_POST_DATA'] = %{
<client>
  <name>test1</name>
  <description>test1</description>
  <server-group-id type="integer">#{server_groups(:one).id}</server-group-id>
</client>
}

@request.accept = 'text/xml'
response=post :create
@request.env.delete('RAW_POST_DATA')

    end

    assert_response :success

  end

  test "should create client where VPN server is online via JSON request" do

    http_basic_authorize
    assert_difference('Client.count') do

@request.env['RAW_POST_DATA'] = %{
	{
		"name": "test1",
		"description": "test1",
		"server_group_id": #{server_groups(:one).id}
	}
}

@request.accept = 'application/json'
response=post :create
@request.env.delete('RAW_POST_DATA')

      assert_response :success

    end

    client=Client.find(:first, :conditions => ["name = 'test1'"])

    assert_not_nil AsyncExec.jobs[CreateClientVPNCredentials]
    assert_equal client.id, AsyncExec.jobs[CreateClientVPNCredentials][0]

  end

  test "should create client via JSON request" do

    AsyncExec.jobs.clear
    http_basic_authorize
    assert_difference('Client.count') do

@request.env['RAW_POST_DATA'] = %{
	{
		"name": "test1",
		"description": "test1",
		"server_group_id": #{server_groups(:two).id}
	}
}

@request.accept = 'application/json'
response=post :create
@request.env.delete('RAW_POST_DATA')

      assert_response :success

    end

    client=Client.find(:first, :conditions => ["name = 'test1'"])

    assert_nil AsyncExec.jobs[CreateClientVPNCredentials]

  end

  test "jim should not destroy bobs client" do
    login_as(:jim)
    delete :destroy, :id => clients(:two).to_param
    assert_response 401
  end

  test "should not destroy client" do
    delete :destroy, :id => clients(:one).to_param
    assert_response 302
  end

  test "should destroy client" do
    login_as(:bob)
    delete :destroy, :id => clients(:one).to_param
    assert_response :success
  end

  test "should destroy client as admin" do
    login_as(:admin)
    delete :destroy, :id => clients(:one).to_param
    assert_response :success
  end

end
