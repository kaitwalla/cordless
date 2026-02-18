require "application_system_test_case"

class SearchTest < ApplicationSystemTestCase
  setup do
    sign_in "jz@37signals.com"
  end

  test "searching for messages" do
    join_room rooms(:designers)

    # Send a message to search for
    send_message "The quick brown fox jumps over the lazy dog"

    # Open search
    click_on "Search"

    fill_in "q", with: "brown fox"
    click_on "Search messages"

    assert_selector ".search-result", text: "brown fox"
  end

  test "recent searches are remembered" do
    click_on "Search"

    fill_in "q", with: "testing"
    click_on "Search messages"

    # Go back to search
    click_on "Search"

    assert_selector ".recent-search", text: "testing"
  end

  test "clearing search history" do
    click_on "Search"

    fill_in "q", with: "first search"
    click_on "Search messages"

    click_on "Search"
    fill_in "q", with: "second search"
    click_on "Search messages"

    click_on "Search"
    assert_selector ".recent-search", count: 2

    click_on "Clear history"

    assert_no_selector ".recent-search"
  end

  test "clicking search result navigates to message" do
    join_room rooms(:designers)
    send_message "Unique phrase for testing navigation"

    click_on "Search"
    fill_in "q", with: "Unique phrase"
    click_on "Search messages"

    click_on "Unique phrase for testing navigation"

    # Should be back in the room with the message visible
    assert_message_text "Unique phrase for testing navigation"
  end
end
