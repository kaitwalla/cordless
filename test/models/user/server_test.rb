require "test_helper"

class User::ServerTest < ActiveSupport::TestCase
  setup do
    @user = users(:david)
  end

  test "User.server creates the server bot if it doesn't exist" do
    User.where(name: "Server").destroy_all

    server = User.server
    assert server.persisted?
    assert_equal "Server", server.name
    assert server.bot?
  end

  test "User.server returns existing server bot" do
    server1 = User.server
    server2 = User.server

    assert_equal server1.id, server2.id
  end

  test "server? returns true for the server user" do
    server = User.server
    assert server.server?
  end

  test "server? returns false for regular users" do
    assert_not @user.server?
  end

  test "creating a non-bot user creates a server DM" do
    User.where(name: "Server").destroy_all

    new_user = User.create!(name: "New User", email_address: "new@example.com", password: "secret123456")

    assert new_user.server_dm.present?
    assert new_user.server_dm.server_dm?
    assert_includes new_user.server_dm.users, User.server
    assert_includes new_user.server_dm.users, new_user
  end

  test "creating a bot user does not create a server DM" do
    bot = User.create!(name: "Test Bot", email_address: "bot@example.com", password: "secret123456", role: :bot)

    assert_nil bot.server_dm
  end

  test "server_dm returns the DM with the server user" do
    dm = @user.server_dm
    return skip("Server DM not created for fixture user") unless dm

    assert dm.direct?
    assert dm.server_dm?
  end

  test "server_message sends a message to a user's server DM" do
    dm = Rooms::Direct.find_or_create_for([ @user, User.server ])

    assert_difference -> { dm.messages.count }, 1 do
      User.server_message(@user, "Hello from Server!")
    end

    message = dm.messages.last
    assert_equal "Hello from Server!", message.body.to_plain_text
    assert_equal User.server, message.creator
  end

  test "server_message does nothing for bot users" do
    bot = users(:bender)

    assert_no_difference -> { Message.count } do
      User.server_message(bot, "Hello bot!")
    end
  end

  test "server_broadcast enqueues jobs for all non-bot users" do
    active_users = User.active.without_bots

    assert_enqueued_jobs active_users.count, only: ServerMessageJob do
      User.server_broadcast("System announcement!")
    end
  end

  test "server_broadcast jobs deliver messages when performed" do
    active_users = User.active.without_bots

    # Create server DMs for all users first
    active_users.each { |u| Rooms::Direct.find_or_create_for([ u, User.server ]) }

    assert_difference -> { Message.count }, active_users.count do
      perform_enqueued_jobs do
        User.server_broadcast("System announcement!")
      end
    end
  end
end
