class SlashCommand::TableflipHandler < SlashCommand::BaseHandler
  def execute
    text = args.present? ? "#{args} (\u256F\u00B0\u25A1\u00B0)\u256F\uFE35 \u253B\u2501\u253B" : "(\u256F\u00B0\u25A1\u00B0)\u256F\uFE35 \u253B\u2501\u253B"
    message.transaction do
      message.update!(body: text)
      message.broadcast_update
    end
  end
end
