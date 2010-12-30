class UpdateVpnNetworkInterfaces < ActiveRecord::Migration

    def self.up
        change_column :vpn_network_interfaces, :server_id, :integer, :null => true
        rename_column :vpn_network_interfaces, :server_id, :interfacable_id
        add_column :vpn_network_interfaces, :interfacable_type, :string
        add_column :vpn_network_interfaces, :client_key, :text
        add_column :vpn_network_interfaces, :client_cert, :text
        add_column :vpn_network_interfaces, :ca_cert, :text

		add_index :vpn_network_interfaces, [:interfacable_id, :interfacable_type]

    end

    def self.down
        rename_column :vpn_network_interfaces, :interfacable_id, :server_id
        change_column :vpn_network_interfaces, :server_id, :integer, :null => false
        remove_column :vpn_network_interfaces, :interfacable_type
        remove_column :vpn_network_interfaces, :client_key
        remove_column :vpn_network_interfaces, :client_cert
        remove_column :vpn_network_interfaces, :ca_cert
		remove_index :vpn_network_interfaces, [:interfacable_id, :interfacable_type]
    end

end
