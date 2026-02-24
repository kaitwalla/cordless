require "test_helper"

class SlashCommand::ConfessHandlerTest < ActiveSupport::TestCase
  setup do
    @user = users(:david)
    @room = rooms(:watercooler)
    @account = accounts(:signal)
  end

  test "posts anonymous confession when feature is enabled" do
    @account.settings.anonymous_confessions_enabled = true
    @account.save!

    Current.stubs(:account).returns(@account)
    handler = SlashCommand::ConfessHandler.new(
      args: "I secretly love Nickelback",
      room: @room,
      user: @user
    )
    handler.execute

    confessions_room = Rooms::Open.find_by(name: "anonymous-confessions")
    assert_not_nil confessions_room

    confession = confessions_room.messages.last
    assert_equal "I secretly love Nickelback", confession.body.to_plain_text
    assert_equal "Anonymous", confession.creator.name
    assert confession.creator.bot?
  end

  test "shows error message when feature is disabled" do
    @account.settings.anonymous_confessions_enabled = false
    @account.save!

    Current.stubs(:account).returns(@account)
    handler = SlashCommand::ConfessHandler.new(
      args: "I secretly love Nickelback",
      room: @room,
      user: @user
    )
    handler.execute

    error_message = @room.messages.last
    assert_equal "Anonymous confessions are not enabled", error_message.body.to_plain_text
  end

  test "does nothing when args is blank and feature is enabled" do
    @account.settings.anonymous_confessions_enabled = true
    @account.save!

    original_message_count = Message.count

    Current.stubs(:account).returns(@account)
    handler = SlashCommand::ConfessHandler.new(
      args: "",
      room: @room,
      user: @user
    )
    handler.execute

    assert_equal original_message_count, Message.count
  end

  test "creates anonymous-confessions room if it does not exist" do
    @account.settings.anonymous_confessions_enabled = true
    @account.save!

    Rooms::Open.where(name: "anonymous-confessions").destroy_all

    Current.stubs(:account).returns(@account)
    handler = SlashCommand::ConfessHandler.new(
      args: "My secret",
      room: @room,
      user: @user
    )
    handler.execute

    confessions_room = Rooms::Open.find_by(name: "anonymous-confessions")
    assert_not_nil confessions_room
    assert_equal "Rooms::Open", confessions_room.type
  end

  test "creates Anonymous user if it does not exist" do
    @account.settings.anonymous_confessions_enabled = true
    @account.save!

    User.where(name: "Anonymous").destroy_all

    Current.stubs(:account).returns(@account)
    handler = SlashCommand::ConfessHandler.new(
      args: "My secret",
      room: @room,
      user: @user
    )
    handler.execute

    anonymous_user = User.find_by(name: "Anonymous")
    assert_not_nil anonymous_user
    assert anonymous_user.bot?
  end

  test "reuses existing Anonymous user" do
    @account.settings.anonymous_confessions_enabled = true
    @account.save!

    existing_anonymous = User.find_or_create_by!(name: "Anonymous") do |user|
      user.role = :bot
      user.password = SecureRandom.hex(32)
    end

    Current.stubs(:account).returns(@account)
    handler = SlashCommand::ConfessHandler.new(
      args: "My secret",
      room: @room,
      user: @user
    )
    handler.execute

    confessions_room = Rooms::Open.find_by(name: "anonymous-confessions")
    confession = confessions_room.messages.last
    assert_equal existing_anonymous.id, confession.creator_id
  end
end
