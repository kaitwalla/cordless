require "test_helper"

class LivekitTokenServiceTest < ActiveSupport::TestCase
  setup do
    @user = users(:david)
    @room = rooms(:watercooler)
    @service = LivekitTokenService.new(user: @user, room: @room)
  end

  test "generates a JWT token" do
    token = @service.generate_token

    assert_not_nil token
    assert_kind_of String, token
    # JWT tokens have 3 parts separated by dots
    assert_equal 3, token.split(".").length
  end

  test "returns the LiveKit URL" do
    assert_equal Rails.application.config.x.livekit.url, @service.url
  end

  test "generates room name based on room id" do
    assert_equal "room_#{@room.id}", @service.room_name
  end

  test "token contains correct identity" do
    token = @service.generate_token

    # Decode the JWT payload (middle part)
    payload = JSON.parse(Base64.decode64(token.split(".")[1]))

    assert_equal "user_#{@user.id}", payload["sub"]
  end

  test "token contains user name" do
    token = @service.generate_token

    payload = JSON.parse(Base64.decode64(token.split(".")[1]))

    assert_equal @user.name, payload["name"]
  end

  test "token has video grant for the room" do
    token = @service.generate_token

    payload = JSON.parse(Base64.decode64(token.split(".")[1]))

    assert payload["video"].present?
    assert_equal "room_#{@room.id}", payload["video"]["room"]
    assert payload["video"]["roomJoin"]
    assert payload["video"]["canPublish"]
    assert payload["video"]["canSubscribe"]
  end
end
