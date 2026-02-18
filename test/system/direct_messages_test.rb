require "application_system_test_case"

class DirectMessagesTest < ApplicationSystemTestCase
  setup do
    sign_in "jz@37signals.com"
  end

  test "sending a direct message to another user" do
    using_session("Kevin") do
      sign_in "kevin@37signals.com"
      visit root_url
    end

    # Start a direct message conversation
    click_on "New message"
    fill_in "Search for people", with: "Kevin"
    click_on "Kevin"
    click_on "Start conversation"

    wait_for_cable_connection
    dismiss_pwa_install_prompt

    send_message "Hey Kevin, got a minute?"

    using_session("Kevin") do
      # Kevin should see the DM notification
      assert_selector ".rooms a.unread", wait: 5

      # Click on the direct room
      find(".rooms a.unread").click
      wait_for_cable_connection
      dismiss_pwa_install_prompt

      assert_message_text "Hey Kevin, got a minute?"

      send_message "Sure, what's up?"
    end

    # JZ should see Kevin's response
    assert_message_text "Sure, what's up?"
  end

  test "direct messages show participant names" do
    sign_in "kevin@37signals.com"
    join_room rooms(:david_and_kevin)

    # Direct room should show the other participant's name
    assert_selector ".room-header", text: "David"
  end
end
