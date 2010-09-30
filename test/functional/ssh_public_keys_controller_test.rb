require 'test_helper'

class SshPublicKeysControllerTest < ActionController::TestCase

  include AuthTestHelper

  fixtures :users
  fixtures :ssh_public_keys

  test "should create ssh_public_key" do
    login_as(:bob)
    assert_difference('SshPublicKey.count') do
      post :create, :ssh_public_key => {:public_key => "AABBCCDD112233", :description => "home", :user_id => users(:bob).id}
    end
    assert_response :success
  end

  test "admin update ssh_public_key" do
    login_as(:admin)
    put :update, :id => ssh_public_keys(:jim_ssh_public_key).to_param, :ssh_public_key => {:public_key => "ZZzzZZzz", :description => "blah"}
    assert_redirected_to ssh_public_key_path(assigns(:ssh_public_key))
  end

  test "user update ssh_public_key" do
    login_as(:jim)
    put :update, :id => ssh_public_keys(:jim_ssh_public_key).to_param, :ssh_public_key => {:public_key => "ZZzzZZzz", :description => "blah"}
    assert_redirected_to ssh_public_key_path(assigns(:ssh_public_key))
  end

 test "user should not update another users ssh_public_key" do
    login_as(:bob)
    put :update, :id => ssh_public_keys(:jim_ssh_public_key).to_param, :ssh_public_key => {:public_key => "ZZzzZZzz", :description => "blah"}
    assert_response 401
  end

end
