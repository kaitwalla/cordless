class Room::PushMessageJob < ApplicationJob
  def perform(room, message)
    message = Message.for_push.find(message.id)
    Room::MessagePusher.new(room:, message:).push
  end
end
