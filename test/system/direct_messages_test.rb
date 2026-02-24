require "application_system_test_case"

class DirectMessagesTest < ApplicationSystemTestCase
  setup do
    sign_in "jz@37signals.com"
  end

  test "user can access new direct message page" do
    visit new_rooms_direct_path

    # Should see the page for creating a new direct message
    assert_current_path new_rooms_direct_path
  end

  test "direct messages show participant names" do
    # Visit an existing direct message room
    join_room rooms(:david_and_jz)

    # Direct room should show the other participant's name
    assert_selector "h1", text: "David"
  end
end
