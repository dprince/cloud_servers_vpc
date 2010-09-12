class UpdateServers3 < ActiveRecord::Migration

    def self.up
        add_column :servers, :account_id, :integer
		execute "UPDATE servers SET account_id = 1 WHERE account_id IS NULL"
    end

    def self.down
        remove_column :servers, :account_id
    end

end
