require "application_system_test_case"

class EmojiPickerTest < ApplicationSystemTestCase
  setup do
    sign_in "jz@37signals.com"
    join_room rooms(:designers)
  end

  test "opening and closing emoji picker" do
    # Open picker
    find("[data-controller='emoji-picker'] button").click
    assert_selector ".emoji-picker", visible: true

    # Close by clicking outside
    find(".composer__input").click
    assert_selector ".emoji-picker[hidden]", visible: false
  end

  test "switching emoji categories" do
    find("[data-controller='emoji-picker'] button").click
    assert_selector ".emoji-picker", visible: true

    # Wait for emojis to load
    assert_selector ".emoji-picker__emoji", wait: 5

    # Switch to gestures category
    find(".emoji-picker__tab[data-category='gestures']").click
    assert_selector ".emoji-picker__tab--active[data-category='gestures']"
  end

  test "searching for emojis" do
    find("[data-controller='emoji-picker'] button").click
    assert_selector ".emoji-picker", visible: true

    # Wait for emojis to load
    assert_selector ".emoji-picker__emoji", wait: 5

    # Search for an emoji
    fill_in placeholder: "Search emojis...", with: "smile"

    # Tabs should be hidden during search
    assert_selector ".emoji-picker__tabs[hidden]", visible: false

    # At least one emoji result should appear
    assert_selector ".emoji-picker__emoji", wait: 5
  end

  test "selecting a unicode emoji inserts it into composer" do
    find("[data-controller='emoji-picker'] button").click
    assert_selector ".emoji-picker", visible: true

    # Wait for emojis to load
    assert_selector ".emoji-picker__emoji", wait: 5

    # Click first emoji (using find with match: :first for proper Capybara waiting)
    find(".emoji-picker__emoji", match: :first).click

    # Picker should close
    assert_selector ".emoji-picker[hidden]", visible: false

    # Composer should have content (emoji was inserted)
    assert find("[data-composer-target='text']").value.present?
  end

  test "add custom emoji link is visible" do
    find("[data-controller='emoji-picker'] button").click
    assert_selector ".emoji-picker", visible: true

    # Wait for async content to load
    assert_selector ".emoji-picker__emoji", wait: 5

    assert_selector ".emoji-picker__add-link", text: "Add custom emoji"
  end

  test "closing picker with escape key" do
    find("[data-controller='emoji-picker'] button").click
    assert_selector ".emoji-picker", visible: true

    # Ensure focus is within the picker (search input gets auto-focused)
    assert_selector ".emoji-picker__search-input:focus"

    # Send escape key - the controller listens on document so this should work
    find(".emoji-picker__search-input").send_keys :escape
    assert_selector ".emoji-picker[hidden]", visible: false
  end
end
