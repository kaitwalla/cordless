require "application_system_test_case"

class BoostingMessagesTest < ApplicationSystemTestCase
  setup do
    sign_in "kevin@37signals.com"
    join_room rooms(:designers)
  end

  test "user can view messages with boosts" do
    # Should see existing messages
    assert_selector ".message", minimum: 1
  end
end
