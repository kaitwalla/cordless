class CallChannel < RoomChannel
  on_unsubscribe :left, unless: :subscription_rejected?

  def joined
    broadcast_call_event("joined")
  end

  def left
    broadcast_call_event("left")
  end

  private
    def broadcast_call_event(action)
      RoomChannel.broadcast_to(@room, {
        type: "call_#{action}",
        user: {
          id: current_user.id,
          name: current_user.name
        },
        room_id: @room.id
      })
    end
end
