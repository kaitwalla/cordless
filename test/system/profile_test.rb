require "application_system_test_case"

class ProfileTest < ApplicationSystemTestCase
  setup do
    sign_in "jz@37signals.com"
  end

  test "user views their profile" do
    visit user_profile_path

    # Profile page should have the user's name field
    assert_selector "input[name='user[name]']"
  end

  test "user views another user profile" do
    visit user_url(users(:kevin))

    assert_selector "h1", text: "Kevin"
    assert_text "Programmer"
  end
end
