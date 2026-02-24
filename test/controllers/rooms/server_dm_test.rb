require "test_helper"

class Rooms::ServerDmTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:david)
    sign_in @user

    # Create a server DM for the user
    @server_dm = Rooms::Direct.find_or_create_for([ @user, User.server ])
  end

  test "cannot delete server DM" do
    assert_no_difference -> { Room.count } do
      delete rooms_direct_url(@server_dm)
    end

    assert_response :forbidden
  end

  test "cannot hide server DM by setting involvement to invisible" do
    membership = @server_dm.memberships.find_by(user: @user)
    original_involvement = membership.involvement

    patch room_involvement_url(@server_dm), params: { involvement: "invisible" }

    assert_response :forbidden
    assert_equal original_involvement, membership.reload.involvement
  end

  test "can change server DM involvement to other levels" do
    membership = @server_dm.memberships.find_by(user: @user)

    patch room_involvement_url(@server_dm), params: { involvement: "mentions" }

    assert_response :redirect
    assert_equal "mentions", membership.reload.involvement
  end

  test "can delete regular DMs" do
    other_user = users(:jason)
    regular_dm = Rooms::Direct.find_or_create_for([ @user, other_user ])

    assert_difference -> { Room.count }, -1 do
      delete rooms_direct_url(regular_dm)
    end

    assert_response :redirect
  end
end
