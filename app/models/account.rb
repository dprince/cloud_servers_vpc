require 'rackspace_connection'

class Account < ActiveRecord::Base

  belongs_to :user

  def get_connection
    if self.connection_type == 'rackspace' then
      return RackspaceConnection.new(self.username, self.api_key, self.auth_url)
    elsif self.connection_type == 'openstack' then
      return OpenstackConnection.new(self.username, self.api_key, self.auth_url)
    else
      raise "Unsupported account connection type."
    end
  end

end
