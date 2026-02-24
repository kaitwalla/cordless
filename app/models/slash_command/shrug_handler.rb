class SlashCommand::ShrugHandler < SlashCommand::BaseHandler
  def execute
    text = args.present? ? "#{args} \u00AF\\_(\u30C4)_/\u00AF" : "\u00AF\\_(\u30C4)_/\u00AF"
    message.transaction do
      message.update!(body: text)
      message.broadcast_update
    end
  end
end
