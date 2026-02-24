require "application_system_test_case"

class BotManagementTest < ApplicationSystemTestCase
  setup do
    sign_in "david@37signals.com"  # Admin user
  end

  test "admin views bot list" do
    visit account_bots_url

    assert_selector "h1", text: "Chat bots"
  end
end
