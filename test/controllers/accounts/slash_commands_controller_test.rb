require "test_helper"

class Accounts::SlashCommandsControllerTest < ActionDispatch::IntegrationTest
  setup do
    host! "once.cordless.test"
    sign_in :david # Admin user
    @bot = users(:bender)
  end

  test "index lists slash commands" do
    command = create_command("listme")

    get account_slash_commands_url
    assert_response :success
    assert_select "code", text: "/listme"
  end

  test "index requires admin" do
    sign_in :jz

    get account_slash_commands_url
    assert_response :forbidden
  end

  test "new shows form" do
    get new_account_slash_command_url
    assert_response :success
    assert_select "form"
  end

  test "create creates webhook command" do
    assert_difference "SlashCommand.count", 1 do
      post account_slash_commands_url, params: {
        slash_command: {
          name: "mycommand",
          description: "My custom command",
          command_type: "webhook",
          bot_id: @bot.id
        }
      }
    end

    assert_redirected_to account_slash_commands_url
  end

  test "create with invalid params renders new" do
    post account_slash_commands_url, params: {
      slash_command: { name: "" }
    }

    assert_response :unprocessable_entity
  end

  test "edit shows form" do
    command = create_command("editable")

    get edit_account_slash_command_url(command)
    assert_response :success
  end

  test "update updates command" do
    command = create_command("updateme")

    patch account_slash_command_url(command), params: {
      slash_command: { description: "New description" }
    }

    assert_redirected_to account_slash_commands_url
    assert_equal "New description", command.reload.description
  end

  test "destroy removes command" do
    command = create_command("deleteme")

    assert_difference "SlashCommand.count", -1 do
      delete account_slash_command_url(command)
    end

    assert_redirected_to account_slash_commands_url
  end

  test "all actions require admin" do
    sign_in :jz
    command = create_command("protected")

    get account_slash_commands_url
    assert_response :forbidden

    get new_account_slash_command_url
    assert_response :forbidden

    post account_slash_commands_url, params: { slash_command: { name: "test" } }
    assert_response :forbidden

    get edit_account_slash_command_url(command)
    assert_response :forbidden

    patch account_slash_command_url(command), params: { slash_command: { description: "test" } }
    assert_response :forbidden

    delete account_slash_command_url(command)
    assert_response :forbidden
  end

  private

  def create_command(name)
    SlashCommand.create!(
      name: name,
      description: "Test command",
      command_type: :webhook,
      bot: @bot
    )
  end
end
