require "application_system_test_case"

class AuthenticationTest < ApplicationSystemTestCase
  test "user logs in with valid credentials" do
    visit root_url

    fill_in "email_address", with: "jz@37signals.com"
    fill_in "password", with: "secret123456"
    click_on "log_in"

    assert_selector "a.btn", text: "Designers"
  end

  test "user fails to log in with invalid password" do
    visit root_url

    fill_in "email_address", with: "jz@37signals.com"
    fill_in "password", with: "wrongpassword"
    click_on "log_in"

    # Login failure adds "shake" class to the panel
    assert_selector ".panel.shake"
  end

  test "user fails to log in with invalid email" do
    visit root_url

    fill_in "email_address", with: "nonexistent@example.com"
    fill_in "password", with: "secret123456"
    click_on "log_in"

    # Login failure adds "shake" class to the panel
    assert_selector ".panel.shake"
  end

  test "user logs out" do
    sign_in "jz@37signals.com"

    visit user_profile_path
    find("button[data-action='sessions#logout:prevent']").click

    assert_selector "input[name='email_address']"
  end
end
