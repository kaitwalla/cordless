class AddIndexToMessagesForPagination < ActiveRecord::Migration[8.2]
  def change
    add_index :messages, [ :room_id, :created_at, :id ], name: "index_messages_on_room_and_created_at_and_id"
  end
end
