class CreateSshKeypairs < ActiveRecord::Migration
  def self.up
    create_table :ssh_keypairs do |t|
      t.integer :server_group_id, :null => false
      t.text :public_key, :null => false
      t.text :private_key, :null => false
      t.timestamps
    end

	add_index :ssh_keypairs, :server_group_id

  end

  def self.down
    drop_table :ssh_keypairs
  end

end
