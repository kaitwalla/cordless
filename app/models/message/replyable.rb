module Message::Replyable
  extend ActiveSupport::Concern

  REPLY_CONTENT_TYPE = "application/vnd.cordless.reply"

  include ActionText::Attachable

  def attachable_content_type
    REPLY_CONTENT_TYPE
  end

  def to_attachable_partial_path
    "messages/reply_attachment"
  end

  def to_trix_content_attachment_partial_path
    "messages/reply_attachment"
  end

  def attachable_plain_text_representation(caption)
    "[Reply to #{creator&.name || 'Unknown'}]"
  end
end
