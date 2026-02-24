require "application_system_test_case"

class FirstRunTest < ApplicationSystemTestCase
  setup do
    # Clear existing data to simulate first run
    # Order matters due to foreign key constraints
    Boost.delete_all
    Search.delete_all
    Membership.delete_all
    Message.delete_all
    Room.delete_all
    Ban.delete_all
    Push::Subscription.delete_all
    Webhook.delete_all
    Session.delete_all
    SlashCommand.delete_all
    CustomEmoji.delete_all
    Export.delete_all
    User.delete_all
    Account.delete_all
  end

  test "first run creates account and admin user" do
    visit root_url

    # Should be redirected to first run setup
    assert_selector "legend", text: "Set up Cordless"

    # Fill in user details (account name comes from first user's name)
    fill_in "user[name]", with: "Admin User"
    fill_in "user[email_address]", with: "admin@acme.com"
    fill_in "user[password]", with: "securepassword123"

    find("button[type='submit']").click

    # Should be logged in and see the rooms
    assert_selector ".rooms", wait: 5
  end

  test "first run requires all fields" do
    visit root_url

    # Try to submit without filling any fields
    find("button[type='submit']").click

    # HTML5 validation should prevent submission - check we're still on the page
    assert_selector "legend", text: "Set up Cordless"
  end

  test "first run validates email format" do
    visit root_url

    fill_in "user[name]", with: "Admin User"
    fill_in "user[email_address]", with: "not-an-email"
    fill_in "user[password]", with: "securepassword123"

    find("button[type='submit']").click

    # Should show validation error or stay on page due to HTML5 validation
    assert_selector "legend", text: "Set up Cordless"
  end

  test "first run enforces password minimum length" do
    visit root_url

    fill_in "user[name]", with: "Admin User"
    fill_in "user[email_address]", with: "admin@acme.com"
    fill_in "user[password]", with: "short"

    find("button[type='submit']").click

    # Should show password length error
    assert_text "is too short"
  end
end
