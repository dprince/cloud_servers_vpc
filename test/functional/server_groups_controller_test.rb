require 'test_helper'

class ServerGroupsControllerTest < ActionController::TestCase

  include AuthTestHelper

  test "should not get index" do
    get :index
    assert_response 302
  end

  test "should get index" do
	login_as(:bob)
    get :index
    assert_response :success
    assert_not_nil assigns(:server_groups)
  end

  test "should get index as admin" do
	login_as(:admin)
    get :index
    assert_response :success
    assert_not_nil assigns(:server_groups)
  end

=begin
  test "should get new" do
    get :new
    assert_response :success
  end
=end

  test "should create server_group with server" do
    http_basic_authorize
    assert_difference('Server.count') do
    assert_difference('ServerGroup.count') do
      post :create, :server_group => { :name => "test1", :owner_name => "dan.prince", :domain_name => "test.rsapps.net", :description => "test1", :vpn_network => "172.19.0.0", :vpn_subnet => "255.255.128.0", :servers_attributes => {"0" => { :name => "test1", :description => "test description", :flavor_id => 1, :image_id => 1, :account_id => users(:bob).account_id }} }
    end
    end
    assert_response :success

  end

  test "should create server_group" do
    http_basic_authorize
    assert_difference('ServerGroup.count') do
      post :create, :server_group => { :name => "test1", :owner_name => "dan.prince", :domain_name => "test.rsapps.net", :description => "test1", :vpn_network => "172.19.0.0", :vpn_subnet => "255.255.128.0" }
    end
    assert_response :success
    #assert_redirected_to server_group_path(assigns(:server_group))

  end

  test "should not create server_group" do
    assert_no_difference('ServerGroup.count') do
      post :create, :server_group => { :name => "test1", :owner_name => "dan.prince", :domain_name => "test.rsapps.net", :description => "test1", :vpn_network => "172.19.0.0", :vpn_subnet => "255.255.128.0" }
    end
  end

  test "should create server_group via XML request" do

    http_basic_authorize
    assert_difference('SshPublicKey.count') do
    assert_difference('Server.count') do
    assert_difference('ServerGroup.count') do

@request.env['RAW_POST_DATA'] = %{
<server-group>
  <name>Group 1</name>
  <description>Group 1 Description</description>
  <owner_name>dan.prince</owner_name>
  <domain-name>test.rsapps.net</domain-name>
  <vpn-network>172.19.0.0</vpn-network>
  <vpn-subnet>255.255.128.0</vpn-subnet>
    <servers type="array">
    <server>
      <name>test1</name>
      <description>test1</description>
      <flavor-id type="integer">1</flavor-id>
      <image-id type="integer">1</image-id>
      <openvpn-server type="boolean">true</openvpn-server>
    </server>
    </servers>
    <ssh-public-keys type="array">
    <ssh-public-key>
      <description>Dan's Key</description>
      <public-key>ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA+yNMzUrQXa0EOfv+WJtfmLO1WdoOaD47G9qwllSUaaGPRkYzkTNdxcEPrR3XBR94ctOeWOHZ/w7ymhvwK5LLsoNBK+WgRz/mg8oHcii2GoL0fNojdwUMyFMIJxJT+iwjF/omyhyrWaaLAztAKRO7BdOkNlXMAAcMeKzQtFqdZm09ghoemu3BPYUTyDKHMp+t0P1d7mkHdd719oDfMf+5miixQeJZJCWAsGwroN7k8a46rvezDHEygBsDAF2ZpS2iGMABos/vTp1oyHkCgCqc3rM0OoKqcKB5iQ9Qaqi5ung08BXP/PHfVynXzdGMjTh4w+6jiMw7Dx2GrQIJsDolKQ== dan.prince@dovetail</public-key>
    </ssh-public-key>
    </ssh-public-keys>
</server-group>
}

@request.accept = 'text/xml'
response=post :create
@request.env.delete('RAW_POST_DATA')

    end
    end
    end

    assert_response :success

  end

  test "should create server_group via JSON request" do

    http_basic_authorize
    assert_difference('SshPublicKey.count') do
    assert_difference('Server.count') do
    assert_difference('ServerGroup.count') do

@request.env['RAW_POST_DATA'] = %{
{
    "name": "test",
    "domain_name": "b.c",
    "description": "test description",
    "vpn_network": "172.19.0.0",
    "vpn_subnet": "255.255.128.0",
    "owner_name": "dan.prince",
    "servers": [
		{
			"name": "test1",
			"description": "test1",
            "flavor_id": 4,
            "image_id": 14,
            "openvpn_server": "true"
        }
    ],
	"ssh_public_keys": [
		{
			"description": "Dan's Key",
			"public_key": "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA+yNMzUrQXa0EOfv+WJtfmLO1WdoOaD47G9qwllSUaaGPRkYzkTNdxcEPrR3XBR94ctOeWOHZ/w7ymhvwK5LLsoNBK+WgRz/mg8oHcii2GoL0fNojdwUMyFMIJxJT+iwjF/omyhyrWaaLAztAKRO7BdOkNlXMAAcMeKzQtFqdZm09ghoemu3BPYUTyDKHMp+t0P1d7mkHdd719oDfMf+5miixQeJZJCWAsGwroN7k8a46rvezDHEygBsDAF2ZpS2iGMABos/vTp1oyHkCgCqc3rM0OoKqcKB5iQ9Qaqi5ung08BXP/PHfVynXzdGMjTh4w+6jiMw7Dx2GrQIJsDolKQ== dan.prince@dovetail"
		}
	]
}
}

@request.accept = 'application/json'
response=post :create
@request.env.delete('RAW_POST_DATA')

    end
    end
    end

    assert_response :success

  end

  test "should show bobs server_group" do
	login_as(:bob)
    get :show, :id => server_groups(:one).to_param
    assert_response :success
  end

  test "should not show bobs server_group to jim" do
	login_as(:jim)
    get :show, :id => server_groups(:one).to_param
    assert_response 401
  end

=begin
  test "should get edit" do
    get :edit, :id => server_groups(:one).to_param
    assert_response :success
  end

  test "should update server_group" do
    put :update, :id => server_groups(:one).to_param, :server_group => {
            :name => "test1",
            :description => "test1",
            :vpn_network => "172.19.0.0",
            :vpn_subnet => "255.255.128.0"
    }
    assert_redirected_to server_group_path(assigns(:server_group))
  end
=end

  test "should destroy server_group" do
    http_basic_authorize
	delete :destroy, :id => server_groups(:one).to_param

	server_group=ServerGroup.find(server_groups(:one).id)
	assert_equal true, server_group.historical

    assert_redirected_to server_groups_path
  end

  test "bob should not destroy jims server_group" do
	login_as(:bob)
	delete :destroy, :id => server_groups(:two).to_param
	server_group=ServerGroup.find(server_groups(:two).id)
	assert_equal false, server_group.historical
  end

  test "should not destroy server_group" do
	delete :destroy, :id => server_groups(:one).to_param

	server_group=ServerGroup.find(server_groups(:one).id)
	assert_equal false, server_group.historical
  end

end
