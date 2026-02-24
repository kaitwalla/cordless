require "application_system_test_case"

class SearchTest < ApplicationSystemTestCase
  setup do
    sign_in "jz@37signals.com"
    join_room rooms(:designers)
  end

  test "user can access search page" do
    visit searches_path

    # Should see the search input
    assert_selector "input[name='q']"
  end

  test "searching for messages" do
    # Send a message to search for
    send_message "The quick brown fox jumps over the lazy dog"

    # Open search
    visit searches_path

    fill_in "q", with: "brown fox"
    find("form button[type='submit']").click

    # Should see search results
    assert_selector ".message", text: "brown fox", wait: 5
  end
end
