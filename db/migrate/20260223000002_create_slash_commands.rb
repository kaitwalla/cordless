class CreateSlashCommands < ActiveRecord::Migration[8.2]
  def change
    create_table :slash_commands do |t|
      t.string :name, null: false
      t.string :description, null: false
      t.integer :command_type, default: 0, null: false
      t.references :bot, foreign_key: { to_table: :users }
      t.string :usage_hint
      t.timestamps
    end

    add_index :slash_commands, :name, unique: true
  end
end
