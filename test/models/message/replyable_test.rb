require "test_helper"

class Message::ReplyableTest < ActiveSupport::TestCase
  setup do
    @message = messages(:first)
  end

  test "message is attachable" do
    assert @message.respond_to?(:attachable_sgid)
    assert @message.attachable_sgid.present?
  end

  test "attachable partial path" do
    assert_equal "messages/reply_attachment", @message.to_attachable_partial_path
  end

  test "trix content attachment partial path" do
    assert_equal "messages/reply_attachment", @message.to_trix_content_attachment_partial_path
  end

  test "attachable content type" do
    assert_equal "application/vnd.cordless.reply", @message.attachable_content_type
  end

  test "plain text representation" do
    assert_equal "[Reply to #{@message.creator.name}]", @message.attachable_plain_text_representation(nil)
  end

  test "plain text representation with nil creator" do
    @message.creator = nil
    assert_equal "[Reply to Unknown]", @message.attachable_plain_text_representation(nil)
  end

  test "lookup message attachable from sgid" do
    html = %Q(<action-text-attachment sgid="#{@message.attachable_sgid}" content-type="application/vnd.cordless.reply"></action-text-attachment>)
    node = ActionText::Fragment.wrap(html).find_all(ActionText::Attachment.tag_name).first

    attachment = ActionText::Attachment.from_node(node)
    assert_equal @message, attachment.attachable
  end

  test "reply attachment is preserved when saving message body" do
    original_message = messages(:first)
    reply_attachment = reply_attachment_for(original_message)

    new_message = Message.create!(
      room: rooms(:designers),
      creator: users(:david),
      body: "<div>#{reply_attachment}</div>",
      client_message_id: "reply-test"
    )

    assert_includes new_message.body.to_s, "action-text-attachment"
    assert_includes new_message.body.to_s, original_message.attachable_sgid
  end

  private
    def reply_attachment_for(message)
      content = %Q(<figure class="reply-attachment">Reply to #{message.creator.name}</figure>)
      %Q(<action-text-attachment sgid="#{message.attachable_sgid}" content-type="application/vnd.cordless.reply" content="#{content.gsub('"', '&quot;')}"></action-text-attachment>)
    end
end
