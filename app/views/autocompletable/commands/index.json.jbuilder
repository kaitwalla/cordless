json.array! @slash_commands do |command|
  json.name "/#{command.name}"
  json.value command.name
  json.description command.description
  json.usage_hint command.usage_hint
end
