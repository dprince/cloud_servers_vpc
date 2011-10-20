require 'test_helper'

class ImagesControllerTest < ActionController::TestCase

  include AuthTestHelper

  fixtures :images
  fixtures :accounts
  fixtures :users

  test "should get index" do
    login_as(:bob)
    get :index
    assert_response :success
    assert_not_nil assigns(:images)
  end

  test "should show image as bob" do
    login_as(:bob)
    get :show, :id => images(:bob_image).to_param
    assert_response :success
  end

  test "should not show bob's image to jim" do
    login_as(:jim)
    get :show, :id => images(:bob_image).to_param
    assert_response 401
  end

  test "bob update image" do
    login_as(:bob)
    put :update, :id => images(:bob_image).to_param, :image => {:name => "test1"}
    assert_redirected_to image_path(assigns(:image))
  end

  test "jim can't update bobs image" do
    login_as(:jim)
    put :update, :id => images(:bob_image).to_param, :image => {:name => "test1"}
    assert_response 401
  end

  test "image destroy himself" do
    login_as(:bob)
    delete :destroy, :id => images(:bob_image).to_param
    assert_response :success
  end

  test "jim can't destroy bobs image" do
    login_as(:jim)
    delete :destroy, :id => images(:bob_image).to_param
    assert_response 401
  end

end
