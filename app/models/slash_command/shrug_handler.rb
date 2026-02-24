class SlashCommand::ShrugHandler < SlashCommand::BaseHandler
  def execute
    text = args.present? ? "#{args} \u00AF\\_(\u30C4)_/\u00AF" : "\u00AF\\_(\u30C4)_/\u00AF"
    room.messages.create!(body: text, creator: user).broadcast_create
  end
end
