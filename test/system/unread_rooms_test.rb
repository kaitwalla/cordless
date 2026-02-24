require "application_system_test_case"

class UnreadRoomsTest < ApplicationSystemTestCase
  setup do
    sign_in "jz@37signals.com"
  end

  test "user can view rooms" do
    join_room rooms(:designers)

    # Should see the room in the sidebar
    assert_selector ".rooms a", text: "Designers"
  end
end
