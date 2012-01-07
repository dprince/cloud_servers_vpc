class UpdateAccounts2 < ActiveRecord::Migration

    def self.up
		add_column :accounts, :connection_type, :string, :default => "rackspace"
		add_column :accounts, :auth_url, :string, :default => ""
		rename_column :accounts, :cloud_servers_username, :username
		rename_column :accounts, :cloud_servers_api_key, :api_key
    end

    def self.down
        remove_column :accounts, :connection_type
        remove_column :accounts, :auth_url
		rename_column :accounts, :username, :cloud_servers_username
		rename_column :accounts, :api_key, :cloud_servers_api_key
    end

end
