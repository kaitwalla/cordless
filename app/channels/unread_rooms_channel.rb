class UnreadRoomsChannel < ApplicationCable::Channel
  def subscribed
    stream_from "unread_rooms:#{current_user.id}"
  end
end
