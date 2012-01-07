require 'test_helper'

class UsersControllerTest < ActionController::TestCase

  include AuthTestHelper

  fixtures :users

  test "should get index as admin" do
    login_as(:admin)
    get :index
    assert_response :success
    assert_not_nil assigns(:users)
  end

  test "non admin should not get index" do
    login_as(:bob)
    get :index
    assert_response 401
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should not create user without account" do
    assert_no_difference('User.count') do
      post :create, :user => {:username => "test1", :first_name => "Mr.", :last_name => "Big", :password => "test123"}
    end
  end

  test "should create user with account" do
    assert_difference('User.count') do
      post :create, :user => {:username => "test1", :first_name => "Mr.", :last_name => "Big", :password => "test123", :account_attributes => {:username => 'blah123', :api_key => 'AABBCCDD'} }
    end
    user=User.find(:first, :conditions => ["username = ?", "test1"])
    assert_equal "blah123", user.account.username, "Cloud Servers username was not set."
    assert_equal "AABBCCDD", user.account.api_key, "Cloud Servers api key was not set."
    assert_redirected_to user_path(assigns(:user))
  end

  test "should not create user with invalid account" do
    assert_no_difference('User.count') do
      ENV['CLOUD_SERVERS_UTIL_INIT_MOCK_FAIL']="true"
      post :create, :user => {:username => "test1", :first_name => "Mr.", :last_name => "Big", :password => "test123", :account_attributes => {:username => 'blah123', :api_key => 'AABBCCDD'} }
    end
  end

  test "should not create admin" do
    assert_difference('User.count', 0) do
      post :create, :user => {:username => "test1", :first_name => "Mr.", :last_name => "Big", :password => "test123", :is_admin => true}
    end
    assert_response 401
  end

  test "should show user as admin" do
    login_as(:admin)
    get :show, :id => users(:bob).to_param
    assert_response :success
  end

  test "should show user himself" do
    login_as(:bob)
    get :show, :id => users(:bob).to_param
    assert_response :success
  end

  test "should not show other people" do
    login_as(:jim)
    get :show, :id => users(:bob).to_param
    assert_response 401
  end

  test "should admin get edit" do
    login_as(:admin)
    get :edit, :id => users(:bob).to_param
    assert_response :success
  end

  test "user edit himself" do
    login_as(:bob)
    get :edit, :id => users(:bob).to_param
    assert_response :success
  end

  test "user edit others" do
    login_as(:jim)
    get :edit, :id => users(:bob).to_param
    assert_response 401
  end

  test "admin update user" do
    login_as(:admin)
    put :update, :id => users(:bob).to_param, :user => {:username => "test1", :first_name => "Mr.", :last_name => "Big"}
    assert_redirected_to user_path(assigns(:user))
  end

  test "user update himself" do
    login_as(:bob)
    put :update, :id => users(:bob).to_param, :user => {:username => "test1", :first_name => "Mr.", :last_name => "Big"}
    assert_redirected_to user_path(assigns(:user))
  end

  test "user should not update others" do
    login_as(:jim)
    put :update, :id => users(:bob).to_param, :user => {:username => "test1", :first_name => "Mr.", :last_name => "Big"}
    assert_response 401
  end

  test "user should not make himself admin" do
    login_as(:jim)
    put :update, :id => users(:jim).to_param, :user => {:is_admin => true}
    assert_response 401
    user=User.find(users(:jim).id) 
    assert_equal false, user.is_admin
  end

  test "admin destroy user" do
    login_as(:admin)
    delete :destroy, :id => users(:bob).to_param
    assert_equal false, User.find(users(:bob).id).is_active
    assert_redirected_to users_path
  end

  test "user destroy himself" do
    login_as(:bob)
    delete :destroy, :id => users(:bob).to_param
    assert_equal false, User.find(users(:bob).id).is_active
    assert_redirected_to users_path
  end

  test "user destroy others" do
    login_as(:jim)
    delete :destroy, :id => users(:bob).to_param
    assert_equal true, User.find(users(:bob).id).is_active
    assert_response 401
  end

end
