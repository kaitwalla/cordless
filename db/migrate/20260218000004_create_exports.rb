class CreateExports < ActiveRecord::Migration[8.0]
  def change
    create_table :exports do |t|
      t.references :account, null: false, foreign_key: true
      t.references :requested_by, null: false, foreign_key: { to_table: :users }
      t.integer :status, default: 0, null: false

      t.timestamps
    end

    add_index :exports, :created_at
  end
end
