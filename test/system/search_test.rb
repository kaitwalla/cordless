require "application_system_test_case"

class SearchTest < ApplicationSystemTestCase
  setup do
    sign_in "jz@37signals.com"
    join_room rooms(:designers)
  end

  test "searching for messages" do
    # Send a message to search for
    send_message "The quick brown fox jumps over the lazy dog"

    # Open search via the search link in composer
    visit searches_path

    fill_in "q", with: "brown fox"
    find("button[type='submit']").click

    assert_selector ".message", text: "brown fox", wait: 5
  end

  test "recent searches are remembered" do
    visit searches_path

    fill_in "q", with: "testing"
    find("button[type='submit']").click

    # Go back to search
    visit searches_path

    # Recent searches appear as links with the query text
    assert_selector "a", text: '"testing"'
  end

  test "clearing search history" do
    visit searches_path

    fill_in "q", with: "first search"
    find("button[type='submit']").click

    visit searches_path
    fill_in "q", with: "second search"
    find("button[type='submit']").click

    visit searches_path
    # Recent searches appear as links
    assert_selector ".searches__recents a", minimum: 2

    # Click the clear button (broom icon)
    accept_confirm do
      find(".searches__btn").click
    end

    assert_no_selector ".searches__recents a"
  end

  test "clicking search result navigates to message" do
    send_message "Unique phrase for testing navigation"

    visit searches_path
    fill_in "q", with: "Unique phrase"
    find("button[type='submit']").click

    # Click on the search result
    find(".message", text: "Unique phrase", match: :first).click

    # Should be back in the room with the message visible
    assert_message_text "Unique phrase for testing navigation"
  end
end
