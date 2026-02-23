module Message::Replyable
  extend ActiveSupport::Concern

  include ActionText::Attachable

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
