class CreateReservations < ActiveRecord::Migration
  def self.up
    create_table :reservations do |t|
      t.string :image_ref
      t.string :flavor_ref
      t.integer :size
      t.integer :user_id
      t.boolean :historical, :default => false
      t.timestamps
    end
  end

  def self.down
    drop_table :reservations
  end
end
