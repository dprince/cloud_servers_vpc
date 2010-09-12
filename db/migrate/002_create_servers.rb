class CreateServers < ActiveRecord::Migration
  def self.up
    create_table :servers do |t|
      t.string :name, :null => false
      t.string :description, :null => false
      t.string :external_ip_addr #set later from Cloud Server API
      t.string :internal_ip_addr #set later from Cloud Server API
      t.integer :cloud_server_id_number # set later from Cloud Server API 
      t.integer :flavor_id, :null => false # corresponds to Cloud Server API
      t.integer :image_id, :null => false # corresponds to Cloud Server API
      t.integer :server_group_id, :null => false
      t.boolean :openvpn_server, :null => false, :default => false
      t.string :status, :null => false, :default => "Pending"
      t.integer :retry_count, :null => false, :default => 0
      t.timestamps
    end
  end

  def self.down
    drop_table :servers
  end
end
