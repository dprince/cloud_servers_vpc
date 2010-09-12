class UpdateServerGroups4 < ActiveRecord::Migration

    def self.up
        add_column :server_groups, :user_id, :integer
    end

    def self.down
        remove_column :server_groups, :user_id
    end

end
