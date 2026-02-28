module EmojiHelper
  REACTIONS = {
    "👍" => "Thumbs up",
    "👏" => "Clapping",
    "👋" => "Waving hand",
    "💪" => "Muscle",
    "❤️" => "Red heart",
    "😂" => "Face with tears of joy",
    "🎉" => "Party popper",
    "🔥" => "Fire"
  }

  # Renders boost content, converting custom emoji shortcodes to images
  def render_boost_content(content)
    return content unless content.match?(/:[a-z0-9_-]+:/)

    # Check if it's a custom emoji shortcode
    shortcode = content.gsub(/^:|:$/, "")
    custom_emoji = CustomEmoji.find_by(shortcode: shortcode)

    if custom_emoji&.image&.attached?
      render partial: "custom_emojis/custom_emoji", locals: { custom_emoji: custom_emoji }
    else
      content
    end
  end
end
