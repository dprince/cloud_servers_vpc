class CreateServerErrors < ActiveRecord::Migration
  def self.up
    create_table :server_errors do |t|
      t.string :error_message, :null => false
      t.integer :server_id, :null => true
      t.timestamps
    end
  end

  def self.down
    drop_table :server_errors
  end
end
