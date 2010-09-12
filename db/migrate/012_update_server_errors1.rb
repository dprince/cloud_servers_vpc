class UpdateServerErrors1 < ActiveRecord::Migration

    def self.up
        add_column :server_errors, :cloud_server_id_number, :integer
		add_index :server_errors, :cloud_server_id_number
		add_index :servers, :cloud_server_id_number
    end

    def self.down
        remove_column :server_errors, :cloud_server_id_number
    end

end
