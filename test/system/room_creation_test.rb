require "application_system_test_case"

class RoomCreationTest < ApplicationSystemTestCase
  setup do
    sign_in "david@37signals.com"  # Admin user
  end

  test "admin creates an open room" do
    click_on "New room"

    fill_in "Name", with: "Company Announcements"
    choose "Open"
    click_on "Create room"

    assert_selector ".room-header", text: "Company Announcements"
  end

  test "admin creates a closed room" do
    click_on "New room"

    fill_in "Name", with: "Secret Project"
    choose "Closed"
    click_on "Create room"

    assert_selector ".room-header", text: "Secret Project"
  end

  test "admin creates closed room and adds members" do
    click_on "New room"

    fill_in "Name", with: "Design Review"
    choose "Closed"

    # Add members
    fill_in "Add people", with: "JZ"
    click_on "JZ"

    click_on "Create room"

    assert_selector ".room-header", text: "Design Review"
  end

  test "room name is required" do
    click_on "New room"

    choose "Open"
    click_on "Create room"

    assert_text "can't be blank"
  end
end
