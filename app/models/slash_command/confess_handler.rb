class SlashCommand::ConfessHandler < SlashCommand::BaseHandler
  def execute
    unless feature_enabled?
      message.update!(body: "Anonymous confessions are not enabled")
      message.broadcast_update
      return
    end

    return if args.blank?

    message.destroy!

    confessions_room.messages.create!(
      body: args,
      creator: anonymous_user
    ).broadcast_create
  end

  private

  def feature_enabled?
    Current.account.settings.anonymous_confessions_enabled?
  end

  def confessions_room
    Rooms::Open.find_or_create_by!(name: "anonymous-confessions")
  end

  def anonymous_user
    User.find_or_create_by!(name: "Anonymous") do |user|
      user.role = :bot
      user.password = SecureRandom.hex(32)
    end
  end
end
