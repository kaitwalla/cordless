module Message::Broadcasts
  def broadcast_create
    broadcast_append_to room, :messages, target: [ room, :messages ]
    broadcast_unread_notification
  end

  def broadcast_remove
    broadcast_remove_to room, :messages
  end

  private
    def broadcast_unread_notification
      room.memberships.where.not(user_id: creator_id).find_each do |membership|
        ActionCable.server.broadcast("unread_rooms:#{membership.user_id}", { roomId: room.id })
      end
    end
end
