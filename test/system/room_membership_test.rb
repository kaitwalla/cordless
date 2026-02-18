require "application_system_test_case"

class RoomMembershipTest < ApplicationSystemTestCase
  setup do
    sign_in "david@37signals.com"  # Admin user
  end

  test "admin adds member to closed room" do
    join_room rooms(:watercooler)

    open_room_settings
    click_on "Members"

    fill_in "Add people", with: "Kevin"
    click_on "Kevin"

    assert_selector ".member", text: "Kevin"
  end

  test "admin removes member from closed room" do
    join_room rooms(:designers)

    open_room_settings
    click_on "Members"

    within(".member", text: "JZ") do
      click_on "Remove"
    end

    assert_no_selector ".member", text: "JZ"
  end

  test "user leaves a room" do
    sign_in "jz@37signals.com"
    join_room rooms(:designers)

    open_room_settings

    accept_confirm do
      click_on "Leave room"
    end

    assert_no_selector ".rooms a", text: "Designers"
  end

  test "open room shows all members" do
    join_room rooms(:hq)

    open_room_settings
    click_on "Members"

    # Open rooms include all users
    assert_selector ".member", text: "David"
    assert_selector ".member", text: "Jason"
    assert_selector ".member", text: "JZ"
    assert_selector ".member", text: "Kevin"
  end

  private

  def open_room_settings
    find(".room-header__settings-btn").click
  rescue Capybara::ElementNotFound
    find("[data-controller='room-settings']").click
  end
end
