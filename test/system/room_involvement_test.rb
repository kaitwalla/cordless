require "application_system_test_case"

class RoomInvolvementTest < ApplicationSystemTestCase
  setup do
    sign_in "jz@37signals.com"
  end

  test "changing room involvement to everything" do
    join_room rooms(:designers)

    open_room_settings
    click_on "Notifications"

    choose "Everything"
    assert_selector ".involvement-option.selected", text: "Everything"
  end

  test "changing room involvement to mentions only" do
    join_room rooms(:designers)

    open_room_settings
    click_on "Notifications"

    choose "Mentions"
    assert_selector ".involvement-option.selected", text: "Mentions"
  end

  test "changing room involvement to nothing" do
    join_room rooms(:designers)

    open_room_settings
    click_on "Notifications"

    choose "Nothing"

    assert_selector ".involvement-option.selected", text: "Nothing"
  end

  private

  def open_room_settings
    find(".room-header__settings-btn").click
  rescue Capybara::ElementNotFound
    find("[data-controller='room-settings']").click
  end
end
