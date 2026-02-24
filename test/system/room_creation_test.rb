require "application_system_test_case"

class RoomCreationTest < ApplicationSystemTestCase
  setup do
    sign_in "david@37signals.com"  # Admin user
  end

  test "admin can access new room page" do
    find(".rooms__new-btn").click

    # Should be on the new room page
    assert_selector "input[name='room[name]']"
  end

  test "admin creates an open room" do
    visit new_rooms_open_path

    fill_in "room[name]", with: "Company Announcements"
    find("button[type='submit']").click

    # Should be in the new room
    assert_selector "h1", text: "Company Announcements", wait: 5
  end
end
