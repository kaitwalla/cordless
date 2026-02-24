require "application_system_test_case"

class MessageAttachmentsTest < ApplicationSystemTestCase
  setup do
    sign_in "jz@37signals.com"
    join_room rooms(:designers)
  end

  test "user can attach a file" do
    # The attachment button should be present
    assert_selector ".composer__attachment-btn"
  end
end
