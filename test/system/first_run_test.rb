require "application_system_test_case"

class FirstRunTest < ApplicationSystemTestCase
  setup do
    # Clear existing account and users to simulate first run
    Account.delete_all
    User.delete_all
    Room.delete_all
    Membership.delete_all
  end

  test "first run creates account and admin user" do
    visit root_url

    # Should be redirected to first run setup
    assert_selector "h1", text: "Welcome"

    # Fill in account details
    fill_in "Organization name", with: "Acme Corp"

    # Fill in admin user details
    fill_in "Your name", with: "Admin User"
    fill_in "Email", with: "admin@acme.com"
    fill_in "Password", with: "securepassword123"

    click_on "Create account"

    # Should be logged in and see the default room
    assert_selector ".rooms"
  end

  test "first run requires all fields" do
    visit root_url

    click_on "Create account"

    assert_text "can't be blank"
  end

  test "first run validates email format" do
    visit root_url

    fill_in "Organization name", with: "Acme Corp"
    fill_in "Your name", with: "Admin User"
    fill_in "Email", with: "not-an-email"
    fill_in "Password", with: "securepassword123"

    click_on "Create account"

    assert_text "is invalid"
  end

  test "first run enforces password minimum length" do
    visit root_url

    fill_in "Organization name", with: "Acme Corp"
    fill_in "Your name", with: "Admin User"
    fill_in "Email", with: "admin@acme.com"
    fill_in "Password", with: "short"

    click_on "Create account"

    assert_text "is too short"
  end
end
