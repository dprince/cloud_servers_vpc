require File.dirname(__FILE__) + '/test_helper'

class CloudServersConnectionTest < Test::Unit::TestCase
  
  def test_init_connection_no_credentials
    assert_raises(CloudServers::Exception::Authentication) do
      conn = CloudServers::Connection.new(:api_key => "AABBCCDD11")
    end
  end

  def test_init_connection_no_password
    assert_raises(CloudServers::Exception::Authentication) do
      conn = CloudServers::Connection.new(:username => "test_account")
    end
  end
    
end
