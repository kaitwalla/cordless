class CreateCustomEmojis < ActiveRecord::Migration[8.2]
  def change
    create_table :custom_emojis do |t|
      t.string :shortcode, null: false
      t.references :creator, null: false, foreign_key: { to_table: :users }
      t.timestamps
    end

    add_index :custom_emojis, :shortcode, unique: true
  end
end
