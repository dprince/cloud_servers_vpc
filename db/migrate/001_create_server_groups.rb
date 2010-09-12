class CreateServerGroups < ActiveRecord::Migration
  def self.up
    create_table :server_groups do |t|
      t.string :name, :null => false
      t.string :description, :null => false
      t.string :vpn_network, :null => false
      t.string :vpn_subnet, :null => false
      t.string :last_used_ip_address, :null => false
      t.boolean :delete_pending, :null => false, :default => false
      t.timestamps
    end
  end

  def self.down
    drop_table :server_groups
  end
end
