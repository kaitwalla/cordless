require "application_system_test_case"

class ProfileTest < ApplicationSystemTestCase
  setup do
    sign_in "jz@37signals.com"
  end

  test "user views their profile edit form" do
    visit user_profile_path

    assert_field "Name", with: "JZ"
    assert_field "Bio", with: "Designer"
  end

  test "user updates their name" do
    visit user_profile_path

    fill_in "Name", with: "Jason Z"
    click_on "Save changes"

    visit user_profile_path

    assert_field "Name", with: "Jason Z"
  end

  test "user updates their bio" do
    visit user_profile_path

    fill_in "Bio", with: "Senior Designer"
    click_on "Save changes"

    visit user_profile_path

    assert_field "Bio", with: "Senior Designer"
  end

  test "user changes their password" do
    visit user_profile_path

    fill_in "user[password]", with: "newsecurepassword123"
    click_on "Save changes"

    # Log out using the logout button
    visit user_profile_path
    find("button[data-action='sessions#logout:prevent']").click

    # Log back in with new password
    fill_in "email_address", with: "jz@37signals.com"
    fill_in "password", with: "newsecurepassword123"
    click_on "log_in"

    assert_selector "a.btn", text: "Designers"
  end

  test "user views another user profile" do
    visit user_url(users(:kevin))

    assert_selector "h1", text: "Kevin"
    assert_text "Programmer"
  end
end
