require "application_system_test_case"

class SendingMessagesTest < ApplicationSystemTestCase
  setup do
    sign_in "jz@37signals.com"
    join_room rooms(:designers)
  end

  test "sending a message" do
    send_message "Hello world!"

    assert_message_text "Hello world!", wait: 5
  end

  test "editing messages" do
    within_message messages(:third) do
      reveal_message_actions
      find(".message__edit-btn").click
      fill_in_rich_text_area "message_body", with: "Redacted!"
      click_on "Save changes"
    end

    assert_message_text "Redacted!", wait: 5
  end
end
