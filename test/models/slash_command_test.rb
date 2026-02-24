require "test_helper"

class SlashCommandTest < ActiveSupport::TestCase
  setup do
    @bot = users(:bender)
  end

  test "creates a builtin command" do
    command = SlashCommand.new(
      name: "shrug",
      description: "Append a shrug emoticon",
      command_type: :builtin
    )

    assert command.valid?
    assert command.save
  end

  test "creates a webhook command with bot" do
    command = SlashCommand.new(
      name: "mycommand",
      description: "Trigger my bot",
      command_type: :webhook,
      bot: @bot
    )

    assert command.valid?
    assert command.save
  end

  test "webhook command requires bot" do
    command = SlashCommand.new(
      name: "mycommand",
      description: "Trigger my bot",
      command_type: :webhook
    )

    assert_not command.valid?
    assert_includes command.errors[:bot], "can't be blank"
  end

  test "builtin command does not require bot" do
    command = SlashCommand.new(
      name: "builtin",
      description: "A built-in command",
      command_type: :builtin
    )

    assert command.valid?
  end

  test "requires unique name" do
    SlashCommand.create!(name: "unique", description: "First one", command_type: :builtin)

    duplicate = SlashCommand.new(name: "unique", description: "Second one", command_type: :builtin)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:name], "has already been taken"
  end

  test "name format validation" do
    valid_names = %w[shrug tableflip my_command cmd123]
    invalid_names = ["UPPERCASE", "with-dash", "with spaces", "special!"]

    valid_names.each do |name|
      command = SlashCommand.new(name: name, description: "test")
      command.valid?
      assert_not_includes command.errors[:name], "only allows lowercase letters, numbers, and underscores",
        "Expected #{name} to be valid"
    end

    invalid_names.each do |name|
      command = SlashCommand.new(name: name, description: "test")
      command.valid?
      assert_includes command.errors[:name], "only allows lowercase letters, numbers, and underscores",
        "Expected #{name} to be invalid"
    end
  end

  test "requires description" do
    command = SlashCommand.new(name: "test", command_type: :builtin)

    assert_not command.valid?
    assert_includes command.errors[:description], "can't be blank"
  end

  test "filtered_by returns matching commands" do
    cmd1 = SlashCommand.create!(name: "happy", description: "Happy command", command_type: :builtin)
    cmd2 = SlashCommand.create!(name: "sad", description: "Sad command", command_type: :builtin)

    results = SlashCommand.filtered_by("happy")
    assert_includes results, cmd1
    assert_not_includes results, cmd2

    # Also matches description
    results = SlashCommand.filtered_by("Sad")
    assert_not_includes results, cmd1
    assert_includes results, cmd2
  end

  test "ordered scope" do
    SlashCommand.create!(name: "zebra", description: "Z command", command_type: :builtin)
    SlashCommand.create!(name: "alpha", description: "A command", command_type: :builtin)

    commands = SlashCommand.ordered
    assert_equal "alpha", commands.first.name
    assert_equal "zebra", commands.last.name
  end
end
