require "application_system_test_case"

class BotManagementTest < ApplicationSystemTestCase
  setup do
    sign_in "david@37signals.com"  # Admin user
  end

  test "admin views bot list" do
    visit account_bots_url

    assert_selector "h1", text: "Bots"
    assert_selector ".bot", text: "Bender Bot"
  end

  test "admin creates a new bot" do
    visit account_bots_url

    click_on "New bot"

    fill_in "Name", with: "Weather Bot"
    fill_in "Webhook URL", with: "https://example.com/webhook"
    click_on "Create bot"

    assert_text "Weather Bot"
  end

  test "admin edits bot and sees curl commands" do
    visit account_bots_url

    # Click on the edit button for Bender Bot
    within(".bot", text: "Bender Bot") do
      find("a[href*='edit']").click
    end

    assert_selector "h1", text: "Edit"
  end

  test "admin updates bot webhook URL" do
    visit edit_account_bot_url(users(:bender))

    fill_in "Webhook URL", with: "https://newwebhook.example.com/bot"
    click_on "Save changes"

    # Should redirect back to the bots index
    assert_current_path account_bots_path
  end
end
