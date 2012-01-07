require 'test_helper'

class ServerGroupsControllerTest < ActionController::TestCase

  fixtures :server_groups
  fixtures :accounts
  fixtures :users
  fixtures :images

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

  test "should create server_group with server and client" do
    http_basic_authorize
    assert_difference('Client.count') do
    assert_difference('Server.count') do
    assert_difference('ServerGroup.count') do
      post :create, :server_group => { :name => "test1", :owner_name => "dan.prince", :domain_name => "test.rsapps.net", :description => "test1", :vpn_network => "172.19.0.0", :vpn_subnet => "255.255.128.0", :servers_attributes => {"0" => { :name => "test1", :description => "test description", :flavor_id => 1, :image_id => 1 }}, :client_attributes => {"0" => {:name => "test2", :description => "blah blah"}} }
    end
    end
    end
    assert_response :success

  end

  test "should create server_group with image uuid" do

    image_id = '11b2a5bf-590c-4dd4-931f-a65751a4db0e'

    http_basic_authorize
    assert_difference('Client.count') do
    assert_difference('Server.count') do
    assert_difference('ServerGroup.count') do
      post :create, :server_group => { :name => "test1", :owner_name => "dan.prince", :domain_name => "test.rsapps.net", :description => "test1", :vpn_network => "172.19.0.0", :vpn_subnet => "255.255.128.0", :servers_attributes => {"0" => { :name => "test1", :description => "test description", :flavor_id => "2", :image_id => image_id }}, :client_attributes => {"0" => {:name => "test2", :description => "blah blah"}} }
    end
    end
    end
    assert_response :success

	assert_equal 1, Server.count(:conditions => ["image_id = ?", image_id])

  end

  test "should create server_group" do
    http_basic_authorize
    assert_difference('ServerGroup.count') do
      post :create, :server_group => { :name => "test1", :owner_name => "dan.prince", :domain_name => "test.rsapps.net", :description => "test1", :vpn_network => "172.19.0.0", :vpn_subnet => "255.255.128.0" }
    end
    assert_response :success

  end

  test "should not create server_group if not logged in" do
    assert_no_difference('ServerGroup.count') do
      post :create, :server_group => { :name => "test1", :owner_name => "dan.prince", :domain_name => "test.rsapps.net", :description => "test1", :vpn_network => "172.19.0.0", :vpn_subnet => "255.255.128.0" }
    end
  end

  test "should create server_group via XML request" do

    http_basic_authorize
    assert_difference('SshPublicKey.count') do
        assert_difference('Client.count') do
            assert_difference('Server.count') do
                assert_difference('ServerGroup.count') do

                    @request.env['RAW_POST_DATA'] = get_xml_request(1)

                    @request.accept = 'text/xml'
                    response=post :create
                    @request.env.delete('RAW_POST_DATA')

                end
            end
        end
    end

    assert_response :success

	server=Server.find(:first, :conditions => ["name = 'test1'"])
	assert_equal "echo hello > /tmp/test.txt", server.server_command.command
	assert_equal server.id, AsyncExec.jobs[CreateCloudServer][0]
	assert_nil AsyncExec.jobs[CreateCloudServer][1]

  end

  test "should create server_group via XML request with image uuid" do

    image_id = '22b2a5bf-590c-4dd4-931f-a65751a4db0c'

    http_basic_authorize
    assert_difference('SshPublicKey.count') do
        assert_difference('Client.count') do
            assert_difference('Server.count') do
                assert_difference('ServerGroup.count') do

                    @request.env['RAW_POST_DATA'] = get_xml_request(image_id)

                    @request.accept = 'text/xml'
                    response=post :create
                    @request.env.delete('RAW_POST_DATA')

                end
            end
        end
    end

    assert_response :success

	server=Server.find(:first, :conditions => ["image_id = ?", image_id])
	assert_equal server.id, AsyncExec.jobs[CreateCloudServer][0]

  end

  test "should not create server_group w/ Windows VPN server via XML request" do

    http_basic_authorize
    assert_no_difference('ServerGroup.count') do

        @request.env['RAW_POST_DATA'] = get_xml_request(28)

        @request.accept = 'text/xml'
        response=post :create
        @request.env.delete('RAW_POST_DATA')

    end

    assert_response 422

  end

  test "should create server_group via JSON request" do

    http_basic_authorize
    assert_difference('SshPublicKey.count') do
    assert_difference('Client.count') do
    assert_difference('Server.count') do
    assert_difference('ServerGroup.count') do

@request.env['RAW_POST_DATA'] = %{
{
    "name": "test",
    "domain_name": "b.c",
    "description": "test description",
    "vpn_network": "172.19.0.0",
    "vpn_subnet": "255.255.128.0",
    "vpn_device": "tap",
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
    "clients": [
		{
			"name": "test2",
			"description": "test2"
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
    end

    assert_response :success

	sg=ServerGroup.find(:first, :conditions => ["name = 'test'"])
	assert_equal "tap", sg.vpn_device
	assert_equal 1, sg.ssh_public_keys.size
	server=Server.find(:first, :conditions => ["name = ? AND server_group_id = ?", "test1", sg.id])
	assert_equal server.id, AsyncExec.jobs[CreateCloudServer][0]
	assert_nil AsyncExec.jobs[CreateCloudServer][1]

  end

  test "groups cannot have multiple VPN servers via JSON request" do

    http_basic_authorize
    assert_no_difference('ServerGroup.count') do

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
        },
		{
			"name": "test2",
			"description": "test2",
            "flavor_id": 4,
            "image_id": 14,
            "openvpn_server": "true"
        }
    ]
}
}

@request.accept = 'application/json'
response=post :create
@request.env.delete('RAW_POST_DATA')

    end

    assert_response 422

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

	assert_equal server_group.id, AsyncExec.jobs[MakeGroupHistorical][0]

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

  def get_xml_request(image_id)
return %{
<server-group>
  <name>Group 1</name>
  <description>Group 1 Description</description>
  <owner_name>dan.prince</owner_name>
  <domain-name>test.rsapps.net</domain-name>
  <vpn-network>172.19.0.0</vpn-network>
  <vpn-subnet>255.255.128.0</vpn-subnet>
  <vpn-device>tap</vpn-device>
    <servers type="array">
    <server>
      <name>test1</name>
      <description>test1</description>
      <flavor-id>1</flavor-id>
      <image-id>#{image_id}</image-id>
      <openvpn-server type="boolean">true</openvpn-server>
      <base64-command>#{Base64.encode64("echo hello > /tmp/test.txt")}</base64-command>
    </server>
    </servers>
    <clients type="array">
    <client>
      <name>test2</name>
      <description>test2</description>
    </client>
    </clients>
    <ssh-public-keys type="array">
    <ssh-public-key>
      <description>Dan's Key</description>
      <public-key>ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA+yNMzUrQXa0EOfv+WJtfmLO1WdoOaD47G9qwllSUaaGPRkYzkTNdxcEPrR3XBR94ctOeWOHZ/w7ymhvwK5LLsoNBK+WgRz/mg8oHcii2GoL0fNojdwUMyFMIJxJT+iwjF/omyhyrWaaLAztAKRO7BdOkNlXMAAcMeKzQtFqdZm09ghoemu3BPYUTyDKHMp+t0P1d7mkHdd719oDfMf+5miixQeJZJCWAsGwroN7k8a46rvezDHEygBsDAF2ZpS2iGMABos/vTp1oyHkCgCqc3rM0OoKqcKB5iQ9Qaqi5ung08BXP/PHfVynXzdGMjTh4w+6jiMw7Dx2GrQIJsDolKQ== dan.prince@dovetail</public-key>
    </ssh-public-key>
    </ssh-public-keys>
</server-group>
}
  end

end
