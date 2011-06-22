class UpdateServerGroups6 < ActiveRecord::Migration

    def self.up
        add_column :server_groups, :vpn_proto, :string, :default => "tcp"
    end

    def self.down
        remove_column :server_groups, :vpn_proto
    end

end
