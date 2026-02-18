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

  test "admin views bot details and key" do
    visit account_bots_url

    click_on "Bender Bot"

    assert_text "Bot key"
    assert_selector "[data-controller='clipboard']"
  end

  test "admin regenerates bot key" do
    visit account_bot_url(users(:bender))

    old_key_element = find("[data-clipboard-target='source']", visible: false)
    old_key = old_key_element.value

    accept_confirm do
      click_on "Regenerate key"
    end

    # Wait for page to reflect the regenerated key
    assert_no_text old_key, wait: 5

    new_key_element = find("[data-clipboard-target='source']", visible: false)
    new_key = new_key_element.value

    assert_not_equal old_key, new_key
  end

  test "admin updates bot webhook URL" do
    visit edit_account_bot_url(users(:bender))

    fill_in "Webhook URL", with: "https://newwebhook.example.com/bot"
    click_on "Save changes"

    assert_text "https://newwebhook.example.com/bot"
  end
end
