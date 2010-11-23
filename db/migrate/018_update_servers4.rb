class UpdateServers4 < ActiveRecord::Migration

    def self.up
        add_column :servers, :type, :string, :default => "LinuxServer"
    end

    def self.down
        remove_column :servers, :type
    end

end
