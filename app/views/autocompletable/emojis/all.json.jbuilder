json.custom_emojis @custom_emojis do |emoji|
  json.shortcode emoji.shortcode
  json.image_url emoji.image.attached? ? url_for(emoji.image) : nil
  json.sgid emoji.attachable_sgid
end

json.unicode_emojis do
  @unicode_emojis_by_category.each do |category, emojis|
    json.set! category do
      json.array! emojis do |emoji|
        json.shortcode emoji.shortcode
        json.emoji emoji.emoji
      end
    end
  end
end
