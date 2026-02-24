require "application_system_test_case"

class AccountSettingsTest < ApplicationSystemTestCase
  setup do
    sign_in "david@37signals.com"  # Admin user
  end

  test "admin views account settings" do
    visit edit_account_url

    # Account name field has placeholder "Name this account"
    assert_selector "input[placeholder='Name this account']"
  end

  test "admin updates organization name" do
    visit edit_account_url

    fill_in "account[name]", with: "Basecamp"
    find("button[type='submit']", match: :first).click

    visit edit_account_url
    assert_selector "input[value='Basecamp']"
  end
end
