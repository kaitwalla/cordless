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

    # Fill in user details
    fill_in "user[name]", with: "Admin User"
    fill_in "user[email_address]", with: "admin@acme.com"
    fill_in "user[password]", with: "securepassword123"

    find("button[type='submit']").click

    # Should be logged in and see the rooms
    assert_selector ".rooms", wait: 10
  end
end
