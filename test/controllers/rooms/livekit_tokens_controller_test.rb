require "test_helper"

class Rooms::LivekitTokensControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in :david
    @room = rooms(:watercooler)
  end

  test "show returns JSON with token data" do
    get room_livekit_token_url(@room), as: :json

    assert_response :success

    json = JSON.parse(response.body)
    assert json["token"].present?
    assert json["url"].present?
    assert json["room_name"].present?
    assert json["identity"].present?
    assert json["user_name"].present?
  end

  test "show returns correct room name" do
    get room_livekit_token_url(@room), as: :json

    json = JSON.parse(response.body)
    assert_equal "room_#{@room.id}", json["room_name"]
  end

  test "show returns correct identity for current user" do
    get room_livekit_token_url(@room), as: :json

    json = JSON.parse(response.body)
    assert_equal "user_#{users(:david).id}", json["identity"]
    assert_equal users(:david).name, json["user_name"]
  end

  test "show requires authentication" do
    reset!  # Clear the session

    get room_livekit_token_url(@room), as: :json

    assert_redirected_to new_session_url
  end

  test "show requires room membership" do
    sign_in :jz
    # JZ is not a member of the watercooler room
    closed_room = rooms(:watercooler)

    # First verify JZ is not a member
    assert_not users(:jz).memberships.exists?(room: closed_room)

    assert_raises(ActiveRecord::RecordNotFound) do
      get room_livekit_token_url(closed_room), as: :json
    end
  end

  test "show works for direct message rooms" do
    direct_room = rooms(:david_and_jason)

    get room_livekit_token_url(direct_room), as: :json

    assert_response :success

    json = JSON.parse(response.body)
    assert_equal "room_#{direct_room.id}", json["room_name"]
  end
end
