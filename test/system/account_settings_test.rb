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

  test "admin restricts room creation to administrators" do
    visit edit_account_url

    # Find the switch for room creation restriction and toggle it
    switch = find("input.switch__input", match: :first)
    switch.click if !switch.checked?

    # Wait for form to submit
    sleep 0.5

    # Log out
    visit user_profile_path
    find("button[data-action='sessions#logout:prevent']").click

    sign_in "jz@37signals.com"

    # Non-admin should not see new room button (the + button)
    visit root_url
    assert_no_selector ".rooms__new-btn"
  end

  test "non-admin cannot access account settings" do
    # Log out
    visit user_profile_path
    find("button[data-action='sessions#logout:prevent']").click

    sign_in "jz@37signals.com"

    visit edit_account_url

    # Non-admin sees a different view (no form fields to edit)
    assert_no_selector "input[placeholder='Name this account']"
  end
end
