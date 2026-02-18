require "application_system_test_case"

class MessageAttachmentsTest < ApplicationSystemTestCase
  setup do
    sign_in "jz@37signals.com"
    join_room rooms(:designers)
  end

  test "sending a message with image attachment" do
    using_session("Kevin") do
      sign_in "kevin@37signals.com"
      join_room rooms(:designers)
    end

    # Attach an image file
    attach_file "message[attachment]", Rails.root.join("test/fixtures/files/earth.png"), visible: false

    # Wait for upload and send
    assert_selector ".attachment-preview", wait: 5
    click_on "send"

    using_session("Kevin") do
      join_room rooms(:designers)
      assert_selector ".message__attachment img", wait: 5
    end
  end

  test "sending a message with jpg attachment" do
    using_session("Kevin") do
      sign_in "kevin@37signals.com"
      join_room rooms(:designers)
    end

    attach_file "message[attachment]", Rails.root.join("test/fixtures/files/moon.jpg"), visible: false

    assert_selector ".attachment-preview", wait: 5
    click_on "send"

    using_session("Kevin") do
      join_room rooms(:designers)
      assert_selector ".message__attachment img", wait: 5
    end
  end

  test "removing attachment before sending" do
    attach_file "message[attachment]", Rails.root.join("test/fixtures/files/earth.png"), visible: false

    assert_selector ".attachment-preview", wait: 5

    click_on "Remove attachment"

    assert_no_selector ".attachment-preview"
  end
end
