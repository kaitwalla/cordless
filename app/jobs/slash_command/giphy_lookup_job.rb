require "net/http"
require "json"

class SlashCommand::GiphyLookupJob < ApplicationJob
  GIPHY_API_URL = "https://api.giphy.com/v1/gifs/search"

  def perform(room_id, user_id, query)
    room = Room.find(room_id)
    user = User.find(user_id)

    gif_url = fetch_gif_url(query)

    if gif_url
      create_gif_message(room, user, gif_url, query)
    else
      create_error_message(room, query)
    end
  end

  private

  def fetch_gif_url(query)
    return nil unless giphy_api_key.present?

    uri = URI(GIPHY_API_URL)
    uri.query = URI.encode_www_form(
      api_key: giphy_api_key,
      q: query,
      limit: 1,
      rating: "g"
    )

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = 5
    http.read_timeout = 10

    request = Net::HTTP::Get.new(uri)
    response = http.request(request)
    return nil unless response.is_a?(Net::HTTPSuccess)

    data = JSON.parse(response.body)
    data.dig("data", 0, "images", "original", "url")
  rescue JSON::ParserError, Net::OpenTimeout, Net::ReadTimeout, StandardError => e
    Rails.logger.error "Giphy API error: #{e.message}"
    nil
  end

  def create_gif_message(room, user, gif_url, query)
    body = "<img src=\"#{gif_url}\" alt=\"#{query}\" style=\"max-width: 300px;\">"
    message = room.messages.create!(body: body, creator: user)
    message.broadcast_create
  end

  def create_error_message(room, query)
    system_bot = User.find_by(name: "System", role: :bot) || User.create!(
      name: "System",
      role: :bot,
      password: SecureRandom.hex(32)
    )

    message = room.messages.create!(body: "No GIF found for \"#{query}\"", creator: system_bot)
    message.broadcast_create
  end

  def giphy_api_key
    Rails.configuration.x.giphy&.api_key
  end
end
