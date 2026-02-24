require "application_system_test_case"

class RoomInvolvementTest < ApplicationSystemTestCase
  setup do
    sign_in "jz@37signals.com"
    join_room rooms(:designers)
  end

  test "user can access room involvement settings" do
    # Click the bell icon to see notification options
    visit room_involvement_path(rooms(:designers))

    # Should see involvement options
    assert_selector "input[type='radio']", minimum: 3
  end

  test "changing room involvement" do
    visit room_involvement_path(rooms(:designers))

    # Find and click on a different involvement option
    all("input[type='radio']").last.click

    # The selection should be persisted
    visit room_involvement_path(rooms(:designers))
    assert_selector "input[type='radio']:checked"
  end
end
