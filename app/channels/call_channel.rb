class CallChannel < RoomChannel
  on_unsubscribe :left, unless: :subscription_rejected?

  def joined
    call_tracker.join(current_user)
    broadcast_call_event("joined")
  end

  def left
    call_tracker.leave(current_user)
    broadcast_call_event("left")
  end

  private
    def call_tracker
      @call_tracker ||= CallTracker.new(@room)
    end

    def broadcast_call_event(action)
      RoomChannel.broadcast_to(@room, {
        type: "call_#{action}",
        user: {
          id: current_user.id,
          name: current_user.name
        },
        room_id: @room.id,
        participant_count: call_tracker.participant_count
      })
    end
end
