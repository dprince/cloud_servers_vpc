require 'test_helper'

class ReserveServerTest < ActiveSupport::TestCase

  fixtures :users
  fixtures :accounts
  fixtures :reservations
  fixtures :reserve_servers

  test "create reserve server" do

    reserve = ReserveServer.new(
      :flavor_ref => 1,
      :image_ref => 1,
      :account_id => users(:admin).account.id,
      :reservation_id => reservations(:admin_reservation).id
    )

    assert reserve.valid?, "Reserve server should be valid."
    assert reserve.save, "Reserve server should have been saved."
    assert reserve.create_reserve_server
    assert_equal false, reserve.historical, "Reserve server should not be historical."

  end

  test "create requires flavor ref" do

    reserve = ReserveServer.new(
      :image_ref => 1,
      :account_id => users(:admin).account.id,
      :reservation_id => reservations(:admin_reservation).id
    )

    assert_equal false, reserve.valid?, "Reserve server should not be valid."

  end

  test "create requires image ref" do

    reserve = ReserveServer.new(
      :flavor_ref => 1,
      :account_id => users(:admin).account.id,
      :reservation_id => reservations(:admin_reservation).id
    )

    assert_equal false, reserve.valid?, "Reserve server should not be valid."

  end

  test "create requires reservation" do

    reserve = ReserveServer.new(
      :image_ref => 1,
      :flavor_ref => 1,
      :account_id => users(:admin).account.id
    )

    assert_equal false, reserve.valid?, "Reserve server should not be valid."

  end

  test "create requires account" do

    reserve = ReserveServer.new(
      :image_ref => 1,
      :flavor_ref => 1,
      :reservation_id => reservations(:admin_reservation).id
    )

    assert_equal false, reserve.valid?, "Reserve server should not be valid."

  end


end
