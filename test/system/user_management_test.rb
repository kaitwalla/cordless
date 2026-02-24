require "application_system_test_case"

class UserManagementTest < ApplicationSystemTestCase
  setup do
    sign_in "david@37signals.com"  # Admin user
  end

  test "admin views user list in account settings" do
    visit edit_account_url

    # Account settings page shows users
    assert_text "David"
    assert_text "JZ"
    assert_text "Kevin"
  end

  test "admin views user profile" do
    visit user_url(users(:kevin))

    assert_selector "h1", text: "Kevin"
    assert_text "Programmer"
  end

  test "non-admin cannot access admin features" do
    # Log out and sign in as non-admin
    visit user_profile_path
    find("button[data-action='sessions#logout:prevent']").click

    sign_in "kevin@37signals.com"  # Non-admin user

    visit edit_account_url

    # Non-admin should see limited view (no edit form)
    assert_no_selector "input[placeholder='Name this account']"
  end
end
