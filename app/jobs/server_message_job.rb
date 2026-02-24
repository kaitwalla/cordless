class ServerMessageJob < ApplicationJob
  def perform(user, body)
    User.server_message(user, body)
  end
end
