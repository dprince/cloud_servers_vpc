class UpdateServers4 < ActiveRecord::Migration

    def self.up
        add_column :servers, :type, :string, :default => "LinuxServer"
        add_column :servers, :admin_password, :string
    end

    def self.down
        remove_column :servers, :type
        remove_column :servers, :admin_password
    end

end
