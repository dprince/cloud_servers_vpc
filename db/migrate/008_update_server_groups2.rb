class UpdateServerGroups2 < ActiveRecord::Migration

    def self.up
        add_column :server_groups, :owner_name, :string
    end

    def self.down
        remove_column :server_groups, :owner_name
    end

end
