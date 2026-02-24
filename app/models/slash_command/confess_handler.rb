class SlashCommand::ConfessHandler < SlashCommand::BaseHandler
  def execute
    unless feature_enabled?
      reply_with(body: "Anonymous confessions are not enabled")
      return
    end

    return if args.blank?

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
    Rooms::Open.find_or_create_by!(name: "anonymous-confessions") do |room|
      room.creator = anonymous_user
    end
  end

  def anonymous_user
    User.find_or_create_by!(name: "Anonymous") do |user|
      user.role = :bot
      user.password = SecureRandom.hex(32)
    end
  end
end
