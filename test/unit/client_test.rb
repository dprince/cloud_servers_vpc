require 'test_helper'

class ClientTest < ActiveSupport::TestCase

    fixtures :server_groups
    fixtures :servers
    fixtures :users
    fixtures :clients

    test "create client" do

        client=Client.new(
            :name => "test1",
            :description => "test description"
        )

        group=server_groups(:two)
        group.clients << client

        assert client.valid?, "Client should be valid."
        assert client.save, "Client should have been saved."
        assert_equal false, client.is_windows, "Is windows should default to false."
        assert_equal "Pending", client.status, "Status should default to 'Pending'."
        client=Client.find(client.id)

    end

    test "create client with VPN network interfaces" do

        client=Client.new(
            :name => "test1",
            :description => "test description",
            :num_vpn_network_interfaces => 3
        )

        group=server_groups(:one)
        group.clients << client

        assert client.valid?, "Client should be valid."
        assert client.save, "Client should have been saved."

        assert_equal 3, client.vpn_network_interfaces.size, "3 VPN network interfaces should have been created."

        # Group :one's last used IP address is 172.19.0.2.
        # This is the IP of the OpenVPN server itself.
        # We created a client with 3 VPN interfaces each of which use
        # two IP's. If 172.19.0.8 exists then we should be good.
        vpn_ip_count=VpnNetworkInterface.count(:conditions => "ptp_ip_addr = '172.19.0.8'")
        assert_equal 1, vpn_ip_count, "VPN interface IP are not getting properly incremented."

    end

    test "verify client names are unique within a group" do

        client=Client.new(
            :name => clients(:one).name,
            :description => "test description"
        )
        group=server_groups(:one)
        group.clients << client

        assert !client.valid?, "Client must have unique names."
        assert !client.save, "Client must have unique names."

    end

    test "verify client names are unique among servers within a group" do

        client=Client.new(
            :name => servers(:one).name,
            :description => "test description"
        )
        group=server_groups(:one)
        group.clients << client

        assert !client.valid?, "Client must have unique names."
        assert !client.save, "Client must have unique names."

    end

    test "create client with invalid name" do

        client=Client.new(
            :name => "test 1_*",
            :description => "test description"
        )

        group=server_groups(:two)
        group.clients << client

        assert !client.valid?, "Client should be not be valid. (invalid hostname)"
        assert !client.save, "Client not should have been saved. (invalid hostname)"
    end

end
