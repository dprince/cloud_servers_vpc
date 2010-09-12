class UpdateServerGroups1 < ActiveRecord::Migration

    def self.up
        add_column :server_groups, :domain_name, :string
    end

    def self.down
        remove_column :server_groups, :domain_name
    end

end
