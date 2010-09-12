class UpdateServerGroups3 < ActiveRecord::Migration

    def self.up

        add_column :server_groups, :historical, :boolean, :default => false
		add_index :server_groups, :historical

        remove_column :server_groups, :delete_pending

    end

    def self.down

        remove_column :server_groups, :historical
		add_column :server_groups, :delete_pending, :boolnean, :null => false, :default => false

    end

end
