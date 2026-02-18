require "test_helper"

class WebhookTest < ActiveSupport::TestCase
  test "payload" do
    message = messages(:first)
    message_path = Rails.application.routes.url_helpers.room_at_message_path(message.room, message)
    bot_messages_path = Rails.application.routes.url_helpers.room_bot_messages_path(message.room, users(:bender).bot_key)

    request_body = nil
    WebMock.stub_request(:post, webhooks(:bender).url).to_return do |request|
      request_body = JSON.parse(request.body)
      { status: 200, body: "", headers: {} }
    end

    response = webhooks(:bender).deliver(messages(:first))
    assert_equal 200, response.code.to_i

    # Verify the payload structure
    assert_equal message.creator.id, request_body["user"]["id"]
    assert_equal message.creator.name, request_body["user"]["name"]
    assert_equal message.room.id, request_body["room"]["id"]
    assert_equal message.room.name, request_body["room"]["name"]
    assert_equal bot_messages_path, request_body["room"]["path"]
    assert_equal message.id, request_body["message"]["id"]
    assert_equal message_path, request_body["message"]["path"]
  end

  test "delivery" do
    WebMock.stub_request(:post, webhooks(:bender).url).to_return(status: 200, body: "", headers: {})
    response = webhooks(:bender).deliver(messages(:first))
    assert_equal 200, response.code.to_i
  end

  test "delivery with OK text reply" do
    WebMock.stub_request(:post, webhooks(:bender).url).to_return(status: 200, body: "Hello back!", headers: { "Content-Type" => "text/plain" })
    response = webhooks(:bender).deliver(messages(:first))

    reply_message = Message.last
    assert_equal "Hello back!", reply_message.body.to_plain_text
  end

  test "delivery with OK attachment reply" do
    WebMock.stub_request(:post, webhooks(:bender).url).to_return(status: 200, body: file_fixture("moon.jpg"), headers: { "Content-Type" => "image/jpeg" })
    response = webhooks(:bender).deliver(messages(:first))

    reply_message = Message.last
    assert reply_message.attachment.present?
  end

  test "delivery with error reply" do
    assert_no_difference -> { Message.count } do
      WebMock.stub_request(:post, webhooks(:bender).url).to_return(status: 500, body: "Internal Error!", headers: {})
      response = webhooks(:bender).deliver(messages(:first))
    end
  end

  test "delivery that times out" do
    Webhook.any_instance.stubs(:post).raises(Net::OpenTimeout)
    response = webhooks(:bender).deliver(messages(:first))

    reply_message = Message.last
    assert_equal "Failed to respond (timeout)", reply_message.body.to_plain_text
  end
end
