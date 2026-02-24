# Seed built-in slash commands
# Run with: rails runner db/seeds/slash_commands.rb

SlashCommand.find_or_create_by!(name: "shrug") do |cmd|
  cmd.description = "Append a shrug emoticon to your message"
  cmd.usage_hint = "/shrug [text]"
  cmd.command_type = :builtin
end

SlashCommand.find_or_create_by!(name: "tableflip") do |cmd|
  cmd.description = "Append a table flip emoticon to your message"
  cmd.usage_hint = "/tableflip [text]"
  cmd.command_type = :builtin
end

SlashCommand.find_or_create_by!(name: "giphy") do |cmd|
  cmd.description = "Search for and post a GIF from Giphy"
  cmd.usage_hint = "/giphy [search term]"
  cmd.command_type = :builtin
end

SlashCommand.find_or_create_by!(name: "confess") do |cmd|
  cmd.description = "Post an anonymous message to the confessions channel"
  cmd.usage_hint = "/confess [message]"
  cmd.command_type = :builtin
end

puts "Created #{SlashCommand.count} slash commands"
