class RemoveGiphySlashCommand < ActiveRecord::Migration[8.2]
  def up
    execute "DELETE FROM slash_commands WHERE name = 'giphy'"
  end

  def down
    # giphy command is no longer supported
  end
end
