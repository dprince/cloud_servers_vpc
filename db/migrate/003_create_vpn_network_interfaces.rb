class CreateVpnNetworkInterfaces < ActiveRecord::Migration
  def self.up
    create_table :vpn_network_interfaces do |t|
      t.string :vpn_ip_addr, :null => false
      t.string :ptp_ip_addr, :null => false
      t.integer :server_id, :null => false

      t.timestamps
    end
  end

  def self.down
    drop_table :vpn_network_interfaces
  end
end
