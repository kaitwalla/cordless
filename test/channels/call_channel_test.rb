require "test_helper"

class CallChannelTest < ActionCable::Channel::TestCase
  setup do
    @room = rooms(:watercooler)
    @user = users(:david)
    stub_connection(current_user: @user)
  end

  test "subscribes to room" do
    subscribe(room_id: @room.id)

    assert subscription.confirmed?
    assert_has_stream_for @room
  end

  test "rejects subscription without room membership" do
    other_user = users(:jz)
    stub_connection(current_user: other_user)

    subscribe(room_id: @room.id)

    assert subscription.rejected?
  end

  test "rejects subscription to non-existent room" do
    subscribe(room_id: -1)

    assert subscription.rejected?
  end

  test "joined broadcasts to room channel" do
    subscribe(room_id: @room.id)

    assert_broadcasts(RoomChannel.broadcasting_for(@room), 1) do
      perform :joined
    end
  end

  test "left broadcasts to room channel" do
    subscribe(room_id: @room.id)

    assert_broadcasts(RoomChannel.broadcasting_for(@room), 1) do
      perform :left
    end
  end
end
