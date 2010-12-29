class UpdateVpnNetworkInterfaces < ActiveRecord::Migration

    def self.up
        #add_column :vpn_network_interfaces, :client_id, :integer, :null => true
        change_column :vpn_network_interfaces, :server_id, :integer, :null => true
        rename_column :vpn_network_interfaces, :server_id, :interfacable_id
        add_column :vpn_network_interfaces, :interfacable_type, :string
    end

    def self.down
        rename_column :vpn_network_interfaces, :interfacable_id, :server_id
        change_column :vpn_network_interfaces, :server_id, :integer, :null => false
        remove_column :vpn_network_interfaces, :interfacable_type
    end

end
