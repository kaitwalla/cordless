class Autocompletable::CommandsController < ApplicationController
  def index
    @slash_commands = find_slash_commands.limit(10)
  end

  private

  def find_slash_commands
    query = params[:query].to_s.downcase
    commands = SlashCommand.ordered
    query.present? ? commands.filtered_by(query) : commands
  end
end
