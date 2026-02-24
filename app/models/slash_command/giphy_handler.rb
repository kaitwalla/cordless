class SlashCommand::GiphyHandler < SlashCommand::BaseHandler
  GIPHY_API_URL = "https://api.giphy.com/v1/gifs/search"

  def execute
    return unless giphy_api_key.present?
    return reply_with_usage if args.blank?

    SlashCommand::GiphyLookupJob.perform_later(room.id, user.id, args)
  end

  private

  def reply_with_usage
    reply_with(body: "Usage: /giphy [search term]")
  end

  def giphy_api_key
    Rails.configuration.x.giphy&.api_key
  end
end
