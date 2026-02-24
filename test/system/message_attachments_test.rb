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

    # Attach an image file using the file input inside the composer
    find(".composer__attachment-btn input[type='file']", visible: false).attach_file(Rails.root.join("test/fixtures/files/earth.png"))

    # Wait for upload preview and send
    assert_selector ".composer__filelist img", wait: 5
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

    find(".composer__attachment-btn input[type='file']", visible: false).attach_file(Rails.root.join("test/fixtures/files/moon.jpg"))

    assert_selector ".composer__filelist img", wait: 5
    click_on "send"

    using_session("Kevin") do
      join_room rooms(:designers)
      assert_selector ".message__attachment img", wait: 5
    end
  end

  test "removing attachment before sending" do
    find(".composer__attachment-btn input[type='file']", visible: false).attach_file(Rails.root.join("test/fixtures/files/earth.png"))

    assert_selector ".composer__filelist img", wait: 5

    # Click the remove button on the attachment preview
    find(".composer__filelist button", match: :first).click

    assert_no_selector ".composer__filelist img"
  end
end
