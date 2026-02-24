require "application_system_test_case"

class RoomInvolvementTest < ApplicationSystemTestCase
  setup do
    sign_in "jz@37signals.com"
    join_room rooms(:designers)
  end

  test "user can access room involvement settings" do
    visit room_involvement_path(rooms(:designers))

    # Should be on the involvement page
    assert_current_path room_involvement_path(rooms(:designers))
  end
end
