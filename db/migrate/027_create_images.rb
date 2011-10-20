class CreateImages < ActiveRecord::Migration
  def self.up
    create_table :images do |t|
      t.string :name, :null => false
      t.string :image_ref, :null => false
      t.string :os_type, :null => true
      t.integer :account_id, :null => false
      t.boolean :is_active, :null => false, :default => false
      t.timestamps
    end
  end

  def self.down
    drop_table :images
  end
end
