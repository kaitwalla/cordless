require "application_system_test_case"

class RoomCreationTest < ApplicationSystemTestCase
  setup do
    sign_in "david@37signals.com"  # Admin user
  end

  test "admin creates an open room" do
    # Click the + button to create a new room
    find(".rooms__new-btn").click

    fill_in "room[name]", with: "Company Announcements"
    find("button[type='submit']").click

    # Should be in the new room
    assert_selector "h1", text: "Company Announcements", wait: 5
  end

  test "admin creates a closed room" do
    # Click the + button then switch to closed room type
    find(".rooms__new-btn").click

    # Toggle to closed room (click the switch)
    find(".switch__input").click

    fill_in "room[name]", with: "Secret Project"
    find("button[type='submit']").click

    # Should be in the new room
    assert_selector "h1", text: "Secret Project", wait: 5
  end

  test "room name is required" do
    find(".rooms__new-btn").click

    # Try to submit without a name - HTML5 validation should prevent it
    find("button[type='submit']").click

    # Should still be on the form
    assert_selector "input[placeholder='Name the room']"
  end
end
