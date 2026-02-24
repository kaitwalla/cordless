require "test_helper"

class Autocompletable::CommandsControllerTest < ActionDispatch::IntegrationTest
  setup do
    host! "once.cordless.test"
    sign_in :david
  end

  test "index returns json with commands" do
    create_command("shrug", "Append a shrug")

    get autocompletable_commands_url(format: :json)
    assert_response :success

    json = JSON.parse(response.body)
    assert json.is_a?(Array)

    command = json.find { |c| c["value"] == "shrug" }
    assert command.present?
    assert_equal "/shrug", command["name"]
    assert_equal "Append a shrug", command["description"]
  end

  test "index filters by query" do
    create_command("happy", "Happy command")
    create_command("sad", "Sad command")

    get autocompletable_commands_url(format: :json, query: "happy")
    assert_response :success

    json = JSON.parse(response.body)

    assert json.any? { |c| c["value"] == "happy" }
    assert_not json.any? { |c| c["value"] == "sad" }
  end

  test "index filters by description" do
    create_command("cmd1", "Search for gifs")
    create_command("cmd2", "Post a message")

    get autocompletable_commands_url(format: :json, query: "gif")
    assert_response :success

    json = JSON.parse(response.body)

    assert json.any? { |c| c["value"] == "cmd1" }
    assert_not json.any? { |c| c["value"] == "cmd2" }
  end

  private

  def create_command(name, description)
    SlashCommand.create!(
      name: name,
      description: description,
      command_type: :builtin
    )
  end
end
