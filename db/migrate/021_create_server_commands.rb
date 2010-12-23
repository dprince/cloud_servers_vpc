class CreateServerCommands < ActiveRecord::Migration

  def self.up
    create_table :server_commands do |t|
      t.integer :server_id, :nil => false
      t.text :command, :nil => false
      t.timestamps
    end

    add_index :server_commands, :server_id

  end

  def self.down
    drop_table :server_commands
  end

end
