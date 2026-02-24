require "application_system_test_case"

class RoomMembershipTest < ApplicationSystemTestCase
  setup do
    sign_in "david@37signals.com"  # Admin user
  end

  test "admin can access room settings" do
    join_room rooms(:watercooler)

    # Click the settings menu (three dots)
    find("a[href*='edit']", match: :first).click

    # Should see the room form
    assert_selector "input[name='room[name]']"
  end

  test "admin can view room members" do
    join_room rooms(:designers)

    # Visit the room edit page
    visit edit_rooms_closed_path(rooms(:designers))

    # Should see the members list
    assert_selector "li", minimum: 1
  end
end
