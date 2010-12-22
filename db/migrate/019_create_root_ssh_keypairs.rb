class CreateRootSshKeypairs < ActiveRecord::Migration
  def self.up
    create_table :root_ssh_keypairs do |t|
      t.text :public_key, :null => false
      t.text :private_key, :null => false
      t.timestamps
    end
  end

  def self.down
    drop_table :root_ssh_keypairs
  end
end
