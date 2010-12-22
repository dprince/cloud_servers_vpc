class UpdateServerGroups5 < ActiveRecord::Migration

    def self.up
        add_column :server_groups, :root_ssh_keypair_id, :integer
    end

    def self.down
        remove_column :server_groups, :root_ssh_keypair_id
    end

end
