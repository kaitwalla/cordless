class SlashCommand::BaseHandler
  attr_reader :args, :room, :user

  def initialize(args:, room:, user:)
    @args = args
    @room = room
    @user = user
  end

  def execute
    # Override in subclasses
  end

  protected

  def reply_with(body:, creator: system_bot)
    room.messages.create!(body: body, creator: creator).tap do |msg|
      msg.broadcast_create
    end
  end

  def system_bot
    @system_bot ||= User.find_or_create_by!(name: "System") do |user|
      user.role = :bot
      user.password = SecureRandom.hex(32)
    end
  end
end
