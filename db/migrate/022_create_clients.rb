class CreateClients < ActiveRecord::Migration
  def self.up
    create_table :clients do |t|
      t.string :name, :null => false
      t.string :description, :null => false
      t.boolean :is_windows, :null => false, :default => false
      t.integer :server_group_id, :null => false
      t.string :status, :null => false, :default => "Pending"
      t.timestamps
    end
  end

  def self.down
    drop_table :clients
  end
end
