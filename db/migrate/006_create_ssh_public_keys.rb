class CreateSshPublicKeys < ActiveRecord::Migration
  def self.up
    create_table :ssh_public_keys do |t|
      t.string :description, :null => false
      t.text :public_key, :null => false
      t.integer :server_group_id, :null => false
      t.timestamps
    end
  end

  def self.down
    drop_table :ssh_public_keys
  end
end
