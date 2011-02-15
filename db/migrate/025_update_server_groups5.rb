class UpdateServerGroups5 < ActiveRecord::Migration

    def self.up
        add_column :server_groups, :vpn_device, :string, :default => "tun"
    end

    def self.down
        remove_column :server_groups, :vpn_device
    end

end
