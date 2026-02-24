module User::Server
  extend ActiveSupport::Concern

  included do
    after_create_commit :create_server_dm, unless: :bot?
  end

  class_methods do
    def server
      find_or_create_by!(name: "Server") do |user|
        user.role = :bot
        user.password = SecureRandom.hex(32)
        user.bio = "System notifications and announcements"
      end
    rescue ActiveRecord::RecordNotUnique
      find_by!(name: "Server", role: :bot)
    end

    # Send a message from Server to a specific user's server DM
    def server_message(user, body)
      return if user.bot?
      dm = Rooms::Direct.find_or_create_for([ user, server ])
      dm.messages.create!(body: body, creator: server).tap(&:broadcast_create)
    end

    # Send a message from Server to all users (uses background jobs)
    def server_broadcast(body)
      active.without_bots.find_each do |user|
        ServerMessageJob.perform_later(user, body)
      end
    end
  end

  def server?
    bot? && name == "Server"
  end

  def server_dm
    return unless persisted?
    Rooms::Direct.find_for_users([ self, User.server ])
  end

  private
    def create_server_dm
      Rooms::Direct.find_or_create_for([ self, User.server ])
    end
end
