require 'test_helper'

class ReservationsControllerTest < ActionController::TestCase

  include AuthTestHelper

  fixtures :users
  fixtures :reservations

  test "should not get index" do
    get :index
    assert_response 302
  end

  test "should get index as admin" do

    login_as(:admin)
    get :index
    assert_response :success
    assert_not_nil assigns(:reservations)

  end

  test "should create reservation" do
    login_as(:bob)
    before_count = users(:bob).reservations.size
    assert_difference('Reservation.count') do
      post :create, :reservation => {:flavor_ref => "2", :image_ref => "1", :size => 4}
    end
    assert_response 201
    after_count = User.find(users(:bob).id).reservations.size
    assert after_count > before_count, "Failed to associate reservation with user."
    assert_response :success
  end

  test "admin update reservation" do
    login_as(:admin)
    put :update, :id => reservations(:jim_reservation).to_param, :reservation => {:flavor_ref => "9", :image_ref => "1", :size => 4}
    assert_redirected_to reservation_path(assigns(:reservation))
  end

  test "user update reservation" do
    login_as(:jim)
    put :update, :id => reservations(:jim_reservation).to_param, :reservation => {:flavor_ref => "9", :image_ref => "1", :size => 4}
    assert_redirected_to reservation_path(assigns(:reservation))
  end

 test "user should not update another users reservation" do
    login_as(:bob)
    put :update, :id => reservations(:jim_reservation).to_param, :reservation => {:flavor_ref => "2", :image_ref => "1", :size => 4}
    assert_response 401
  end

  test "user destroy reservation" do
    login_as(:jim)
    delete :destroy, :id => reservations(:jim_reservation).to_param
    assert_equal true, Reservation.find(reservations(:jim_reservation).id).historical
  end

end
