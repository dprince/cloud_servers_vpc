require 'test_helper'

class ReservationTest < ActiveSupport::TestCase

  fixtures :users
  fixtures :accounts
  fixtures :reservations

  test "create reservation" do
    reservation = Reservation.new(
      :flavor_ref => 1,
      :image_ref => 1,
      :size => 4,
      :user_id => users(:admin).id
    )

    assert reservation.valid?, "Reservation server should be valid."
    assert reservation.save, "Reservation server should have been saved."
  end

  test "size is a number" do
    reservation = Reservation.new(
      :flavor_ref => 1,
      :image_ref => 1,
      :size => "asdf",
      :user_id => users(:admin).id
    )

    assert_equal false, reservation.valid?, "Reservation server should not be valid."
  end

  test "requires size" do
    reservation = Reservation.new(
      :flavor_ref => 1,
      :image_ref => 1,
      :user_id => users(:admin).id
    )

    assert_equal false, reservation.valid?, "Reservation server should not be valid."
  end

  test "requires flavor_ref" do
    reservation = Reservation.new(
      :image_ref => 1,
      :size => 4,
      :user_id => users(:admin).id
    )

    assert_equal false, reservation.valid?, "Reservation server should not be valid."
  end

  test "requires image_ref" do
    reservation = Reservation.new(
      :flavor_ref => 1,
      :size => 4,
      :user_id => users(:admin).id
    )

    assert_equal false, reservation.valid?, "Reservation server should not be valid."
  end

  test "requires user" do
    reservation = Reservation.new(
      :image_ref => 1,
      :flavor_ref => 1,
      :size => 4
    )

    assert_equal false, reservation.valid?, "Reservation server should not be valid."
  end

  test "sync creates server" do
    reservation = Reservation.create(
      :image_ref => 1,
      :flavor_ref => 1,
      :size => 1,
      :user_id => users(:admin).id
    )
  
    AsyncExec.jobs.clear
    reservation.sync
    assert_not_nil AsyncExec.jobs[CreateReserveServer]
    AsyncExec.jobs.clear
  end

  test "sync deletes server" do
    AsyncExec.jobs.clear
    reservation = reservations(:admin_reservation)
    reservation.update_attribute(:size, 1)
    reservation.sync
    assert_not_nil AsyncExec.jobs[MakeReserveServerHistorical]
    AsyncExec.jobs.clear
  end

  test "sync updates server" do
    AsyncExec.jobs.clear
    reservation = reservations(:admin_reservation)
    reservation.update_attribute(:image_ref, 999) #fixture uses 1
    reservation.sync
    assert_not_nil AsyncExec.jobs[CreateReserveServer]
    assert_not_nil AsyncExec.jobs[MakeReserveServerHistorical]
    AsyncExec.jobs.clear
  end

end
