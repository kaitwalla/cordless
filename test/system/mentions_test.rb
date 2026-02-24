require "application_system_test_case"

class MentionsTest < ApplicationSystemTestCase
  setup do
    sign_in "jz@37signals.com"
    join_room rooms(:designers)
  end

  test "composer has rich text editor" do
    # The composer should have a rich text area
    assert_selector "trix-editor"
  end
end
