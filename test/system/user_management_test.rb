require "application_system_test_case"

class UserManagementTest < ApplicationSystemTestCase
  setup do
    sign_in "david@37signals.com"  # Admin user
  end

  test "admin views user list" do
    visit account_users_url

    assert_selector "h1", text: "People"
    assert_selector ".user", text: "David"
    assert_selector ".user", text: "Jason"
    assert_selector ".user", text: "JZ"
    assert_selector ".user", text: "Kevin"
  end

  test "admin views user profile" do
    visit account_users_url

    click_on "JZ"

    assert_selector "h1", text: "JZ"
    assert_text "Designer"
  end

  test "admin can edit user details" do
    visit account_user_url(users(:kevin))

    click_on "Edit"

    fill_in "Name", with: "Kevin Updated"
    click_on "Save changes"

    assert_selector "h1", text: "Kevin Updated"
  end

  test "admin can deactivate user" do
    visit account_user_url(users(:kevin))

    click_on "Edit"

    accept_confirm do
      click_on "Deactivate"
    end

    assert_text "deactivated"
  end

  test "non-admin cannot access user management" do
    sign_in "kevin@37signals.com"  # Non-admin user

    visit account_users_url

    # Should be redirected or see forbidden
    assert_no_selector "h1", text: "People"
  end
end
