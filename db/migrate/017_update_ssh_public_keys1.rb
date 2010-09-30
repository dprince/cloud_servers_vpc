class UpdateSshPublicKeys1 < ActiveRecord::Migration

    def self.up
        change_column_null :ssh_public_keys, :server_group_id, true
        add_column :ssh_public_keys, :user_id, :integer
    end

    def self.down
        change_column_null :ssh_public_keys, :server_group_id, false
        remove_column :ssh_public_keys, :user_id
    end

end
