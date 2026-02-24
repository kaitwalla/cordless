json.array!((@custom_emojis || []) + (@unicode_emojis || [])) do |emoji|
  if emoji.is_a?(CustomEmoji)
    json.name ":#{emoji.shortcode}:"
    json.value emoji.shortcode
    json.type "custom"
    json.image_url emoji.image.attached? ? url_for(emoji.image) : nil
    json.sgid emoji.attachable_sgid
  else
    json.name emoji.emoji
    json.value emoji.shortcode
    json.type "unicode"
    json.emoji emoji.emoji
    json.category emoji.category
  end
end
