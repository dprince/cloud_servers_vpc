class UpdateServers5 < ActiveRecord::Migration

    def self.up
        change_column :servers, :cloud_server_id_number, :string
        change_column :servers, :image_id, :string
        change_column :servers, :flavor_id, :string
    end

    def self.down
        change_column :servers, :cloud_server_id_number, :integer
        change_column :servers, :image_id, :integer
        change_column :servers, :flavor_id, :integer
    end

end
