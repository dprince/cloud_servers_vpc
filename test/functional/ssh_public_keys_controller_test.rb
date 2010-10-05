require 'test_helper'

class SshPublicKeysControllerTest < ActionController::TestCase

  include AuthTestHelper

  fixtures :users
  fixtures :ssh_public_keys

  test "should not get index" do
    get :index
    assert_response 302
  end

  test "should get index as admin" do

    login_as(:admin)
    get :index
    assert_response :success
    assert_not_nil assigns(:ssh_public_keys)

  end

  test "should create ssh_public_key" do
    login_as(:bob)
    before_count=users(:bob).ssh_public_keys.size
    assert_difference('SshPublicKey.count') do
      post :create, :ssh_public_key => {:public_key => "AABBCCDD112233", :description => "home", :user_id => users(:bob).id}
    end
    after_count=users(:bob).ssh_public_keys.size
    assert after_count > before_count, "Failed to associate ssh key with user."
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

  test "user destroy ssh_public_key" do
    login_as(:bob)
    delete :destroy, :id => ssh_public_keys(:bob_ssh_public_key).to_param
    assert_raise ActiveRecord::RecordNotFound do
      SshPublicKey.find(ssh_public_keys(:bob_ssh_public_key).id)
    end
  end

end
