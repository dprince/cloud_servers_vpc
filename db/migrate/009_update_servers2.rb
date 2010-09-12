class UpdateServers2 < ActiveRecord::Migration

    def self.up
        add_column :servers, :historical, :boolean, :default => false
		add_index :servers, :historical
    end

    def self.down
        remove_column :servers, :historical
    end

end
