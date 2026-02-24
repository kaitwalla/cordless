require "test_helper"

class AccountTest < ActiveSupport::TestCase
  test "settings" do
    accounts(:signal).settings.restrict_room_creation_to_administrators = true
    assert accounts(:signal).settings.restrict_room_creation_to_administrators?
    assert accounts(:signal)[:settings]["restrict_room_creation_to_administrators"]

    accounts(:signal).update!(settings: { "restrict_room_creation_to_administrators" => "true" })
    assert accounts(:signal).reload.settings.restrict_room_creation_to_administrators?

    accounts(:signal).settings.restrict_room_creation_to_administrators = false
    assert_not accounts(:signal).settings.restrict_room_creation_to_administrators?
    assert_not accounts(:signal)[:settings]["restrict_room_creation_to_administrators"]
    accounts(:signal).update!(settings: { "restrict_room_creation_to_administrators" => "false" })
    assert_not accounts(:signal).reload.settings.restrict_room_creation_to_administrators?
  end

  test "anonymous_confessions_enabled setting" do
    account = accounts(:signal)

    assert_not account.settings.anonymous_confessions_enabled?

    account.settings.anonymous_confessions_enabled = true
    assert account.settings.anonymous_confessions_enabled?
    assert_equal true, account[:settings]["anonymous_confessions_enabled"]

    account.update!(settings: { "anonymous_confessions_enabled" => "true" })
    assert account.reload.settings.anonymous_confessions_enabled?

    account.settings.anonymous_confessions_enabled = false
    assert_not account.settings.anonymous_confessions_enabled?
    account.update!(settings: { "anonymous_confessions_enabled" => "false" })
    assert_not account.reload.settings.anonymous_confessions_enabled?
  end
end
