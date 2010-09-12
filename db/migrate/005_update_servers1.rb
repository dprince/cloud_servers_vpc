class UpdateServers1 < ActiveRecord::Migration

    def self.up
        add_column :servers, :error_message, :string
    end

    def self.down
        remove_column :servers, :error_message
    end

end
