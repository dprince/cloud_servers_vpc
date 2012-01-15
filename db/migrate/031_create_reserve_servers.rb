class CreateReserveServers < ActiveRecord::Migration
  def self.up

    create_table :reserve_servers do |t|
      t.integer :reservation_id
      t.integer :account_id
      t.string :flavor_ref, :null => false
      t.string :image_ref, :null => false
      t.string :external_ip_addr
      t.string :internal_ip_addr
      t.string :cloud_server_id
      t.string :status, :default => "Pending", :null => false
      t.string :error_message
      t.boolean :historical, :default => false
      t.text :private_key
      t.timestamps
    end

    add_index :reserve_servers, :cloud_server_id
    add_index :reserve_servers, :historical

  end

  def self.down
    drop_table :reserve_servers
  end
end
