class SlashCommand::TableflipHandler < SlashCommand::BaseHandler
  def execute
    text = args.present? ? "#{args} (\u256F\u00B0\u25A1\u00B0)\u256F\uFE35 \u253B\u2501\u253B" : "(\u256F\u00B0\u25A1\u00B0)\u256F\uFE35 \u253B\u2501\u253B"
    room.messages.create!(body: text, creator: user).broadcast_create
  end
end
