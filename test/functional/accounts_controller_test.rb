require 'test_helper'

class AccountsControllerTest < ActionController::TestCase

  include AuthTestHelper

  fixtures :users
  fixtures :accounts

  test "should create account" do
    login_as(:bob)
    assert_difference('Account.count') do
      post :create, :account => {:username => "blah", :api_key => "ABABABABABAB"}, :format => :json
    end
    assert_response :success
  end

  test "admin update account" do
    login_as(:admin)
    put :update, :id => accounts(:jim_account).to_param, :account => {:username => "blah", :api_key => "ABABABABABAB"}
    assert_redirected_to account_path(assigns(:account))
  end

  test "user update account" do
    login_as(:jim)
    put :update, :id => accounts(:jim_account).to_param, :account => {:username => "blah", :api_key => "ABABABABABAB"}
    assert_redirected_to account_path(assigns(:account))
  end

 test "user should not update another users account" do
    login_as(:bob)
    put :update, :id => accounts(:jim_account).to_param, :account => {:username => "blah", :api_key => "ABABABABABAB"}
    assert_response 401
  end

  test "user get account limits" do
    login_as(:jim)
    get :limits, :id => accounts(:jim_account).to_param
    assert_response 200
  end

end
