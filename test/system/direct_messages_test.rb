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

    # Start a direct message conversation via the "Ping" link
    visit new_rooms_direct_path

    # Search and select a user
    fill_in "q", with: "Kevin"
    find("li", text: "Kevin", match: :first).click

    # Should go to the DM room
    wait_for_cable_connection
    dismiss_pwa_install_prompt

    send_message "Hey Kevin, got a minute?"

    using_session("Kevin") do
      # Kevin should see the DM notification
      assert_selector ".direct.unread", wait: 10

      # Click on the direct room
      find(".direct.unread").click
      wait_for_cable_connection
      dismiss_pwa_install_prompt

      assert_message_text "Hey Kevin, got a minute?"

      send_message "Sure, what's up?"
    end

    # JZ should see Kevin's response
    assert_message_text "Sure, what's up?", wait: 5
  end

  test "direct messages show participant names" do
    sign_in "kevin@37signals.com"
    join_room rooms(:david_and_kevin)

    # Direct room should show the other participant's name
    assert_selector "h1", text: "David"
  end
end
