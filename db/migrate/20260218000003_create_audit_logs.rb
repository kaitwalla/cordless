class CreateAuditLogs < ActiveRecord::Migration[8.2]
  def change
    create_table :audit_logs do |t|
      t.references :user, null: true
      t.string :action, null: false
      t.string :resource_type, null: false
      t.bigint :resource_id
      t.json :changes_made
      t.string :ip_address
      t.timestamps
    end

    add_index :audit_logs, [ :resource_type, :resource_id ]
    add_index :audit_logs, :created_at
  end
end
