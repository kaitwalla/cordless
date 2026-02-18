require "application_system_test_case"

class AccountSettingsTest < ApplicationSystemTestCase
  setup do
    sign_in "david@37signals.com"  # Admin user
  end

  test "admin views account settings" do
    visit edit_account_url

    assert_selector "h1", text: "Settings"
    assert_field "Organization name", with: "37signals"
  end

  test "admin updates organization name" do
    visit edit_account_url

    fill_in "Organization name", with: "Basecamp"
    click_on "Save changes"

    visit edit_account_url
    assert_field "Organization name", with: "Basecamp"
  end

  test "admin generates new join code" do
    visit edit_account_url

    within(".join-code", match: :first) do
      old_code = find("[data-clipboard-target='source']", visible: false).value

      accept_confirm do
        click_on "Generate new code"
      end

      # Wait for the page to update
      sleep 0.5

      new_code = find("[data-clipboard-target='source']", visible: false).value
      assert_not_equal old_code, new_code
    end
  end

  test "admin restricts room creation to administrators" do
    visit edit_account_url

    check "Only administrators can create rooms"
    click_on "Save changes"

    # Log in as non-admin
    find("[data-controller='profile']").click
    click_on "Log out"

    sign_in "jz@37signals.com"

    visit root_url

    # Non-admin should not see new room button
    assert_no_selector "a", text: "New room"
  end

  test "non-admin cannot access account settings" do
    find("[data-controller='profile']").click
    click_on "Log out"

    sign_in "jz@37signals.com"

    visit edit_account_url

    # Should be redirected away from settings page
    assert_no_current_path edit_account_path
  end
end
