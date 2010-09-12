require File.dirname(__FILE__) + '/test_helper'

class CloudserversAuthenticationTest < Test::Unit::TestCase
  

  def test_good_authentication
    response = {'x-cdn-management-url' => 'http://cdn.example.com/path', 'x-storage-url' => 'http://cdn.example.com/storage', 'authtoken' => 'dummy_token'}
    response.stubs(:code).returns('204')
    server = mock(:use_ssl= => true, :verify_mode= => true, :start => true, :finish => true)
    server.stubs(:get).returns(response)
    Net::HTTP.stubs(:new).returns(server)
    @connection = stub(:authuser => 'dummy_user', :authkey => 'dummy_key', :cdnmgmthost= => true, :cdnmgmtpath= => true, :cdnmgmtport= => true, :cdnmgmtscheme= => true, :storagehost= => true, :storagepath= => true, :storageport= => true, :storagescheme= => true, :authtoken= => true, :authok= => true)
    result = CloudServers::Authentication.new(@connection)
    assert_equal result.class, CloudServers::Authentication
  end
  
  def test_bad_authentication
    response = mock()
    response.stubs(:code).returns('499')
    server = mock(:use_ssl= => true, :verify_mode= => true, :start => true)
    server.stubs(:get).returns(response)
    Net::HTTP.stubs(:new).returns(server)
    @connection = stub(:authuser => 'bad_user', :authkey => 'bad_key', :authok= => true, :authtoken= => true)
    assert_raises(AuthenticationException) do
      result = CloudServers::Authentication.new(@connection)
    end
  end
    
  def test_bad_hostname
    Net::HTTP.stubs(:new).raises(ConnectionException)
    @connection = stub(:authuser => 'bad_user', :authkey => 'bad_key', :authok= => true, :authtoken= => true)
    assert_raises(ConnectionException) do
      result = CloudServers::Authentication.new(@connection)
    end
  end
    
end