module MessagesHelper
  def message_reply_attachment_for_edit(message)
    return nil unless message.body.body

    message.body.body.attachments.find do |attachment|
      attachment.attachable.is_a?(Message)
    end&.attachable
  end

  def message_text_content_for_edit(message)
    return "" unless message.body.body

    # Get the HTML and strip reply attachments
    html = message.body.body.to_trix_html
    doc = Nokogiri::HTML.fragment(html)

    # Remove figures containing reply attachment data
    doc.css('figure[data-trix-attachment]').each do |figure|
      begin
        attachment_data = JSON.parse(figure['data-trix-attachment'])
        if attachment_data['contentType'] == 'application/vnd.cordless.reply'
          figure.remove
        end
      rescue JSON::ParserError
        # Skip if can't parse
      end
    end

    doc.to_html
  end

  def message_area_tag(room, &)
    tag.div id: "message-area", class: "message-area", contents: true, data: {
      controller: "messages presence drop-target",
      action: [ messages_actions, drop_target_actions, presence_actions ].join(" "),
      messages_first_of_day_class: "message--first-of-day",
      messages_formatted_class: "message--formatted",
      messages_me_class: "message--me",
      messages_mentioned_class: "message--mentioned",
      messages_threaded_class: "message--threaded",
      messages_page_url_value: room_messages_url(room)
    }, &
  end

  def messages_tag(room, &)
    tag.div id: dom_id(room, :messages), class: "messages", data: {
      controller: "maintain-scroll refresh-room",
      action: [ maintain_scroll_actions, refresh_room_actions ].join(" "),
      messages_target: "messages",
      refresh_room_loaded_at_value: room.updated_at.to_fs(:epoch),
      refresh_room_url_value: room_refresh_url(room)
    }, &
  end

  def message_tag(message, &)
    message_timestamp_milliseconds = message.created_at.to_fs(:epoch)

    tag.div id: dom_id(message),
      class: class_names("message", emoji_message_class(message)),
      data: {
        controller: "reply",
        user_id: message.creator_id,
        message_id: message.id,
        message_timestamp: message_timestamp_milliseconds,
        message_updated_at: message.updated_at.to_fs(:epoch),
        sort_value: message_timestamp_milliseconds,
        messages_target: "message",
        search_results_target: "message",
        refresh_room_target: "message",
        reply_composer_outlet: "#composer"
      }, &
  rescue Exception => e
    Sentry.capture_exception(e, extra: { message: message })
    Rails.logger.error "Exception while rendering message #{message.class.name}##{message.id}, failed with: #{e.class} `#{e.message}`"

    render "messages/unrenderable"
  end

  def message_timestamp(message, **attributes)
    local_datetime_tag message.created_at, **attributes
  end

  def message_presentation(message)
    case message.content_type
    when "attachment"
      message_attachment_presentation(message)
    when "sound"
      message_sound_presentation(message)
    else
      auto_link h(ContentFilters::TextMessagePresentationFilters.apply(message.body.body)), html: { target: "_blank" }
    end
  rescue Exception => e
    Sentry.capture_exception(e, extra: { message: message })
    Rails.logger.error "Exception while generating message representation for #{message.class.name}##{message.id}, failed with: #{e.class} `#{e.message}`"

    ""
  end

  def emoji_message_class(message)
    return nil unless message.emoji_only?

    count = message.total_emoji_count
    case count
    when 1 then "message--emoji message--emoji-1"
    when 2 then "message--emoji message--emoji-2"
    when 3 then "message--emoji message--emoji-3"
    else "message--emoji"
    end
  end

  private
    def messages_actions
      "turbo:before-stream-render@document->messages#beforeStreamRender keydown.up@document->messages#editMyLastMessage"
    end

    def maintain_scroll_actions
      "turbo:before-stream-render@document->maintain-scroll#beforeStreamRender"
    end

    def refresh_room_actions
      "visibilitychange@document->refresh-room#visibilityChanged online@window->refresh-room#online"
    end

    def presence_actions
      "visibilitychange@document->presence#visibilityChanged"
    end

    def message_attachment_presentation(message)
      Messages::AttachmentPresentation.new(message, context: self).render
    end

    def message_sound_presentation(message)
      sound = message.sound

      tag.div class: "sound", data: { controller: "sound", action: "messages:play->sound#play", sound_url_value: asset_path(sound.asset_path) } do
        play_button + (sound.image ? sound_image_tag(sound.image) : sound.text)
      end
    end

    def play_button
      tag.button "🔊", class: "btn btn--plain", data: { action: "sound#play" }
    end

    def sound_image_tag(image)
      image_tag image.asset_path, width: image.width, height: image.height, class: "align--middle"
    end

    def message_author_title(author)
      [ author.name, author.bio ].compact_blank.join(" – ")
    end
end
