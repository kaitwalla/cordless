class AddMembershipHashToRooms < ActiveRecord::Migration[8.2]
  def change
    add_column :rooms, :membership_hash, :string
    add_index :rooms, :membership_hash, where: "type = 'Rooms::Direct'"
  end
end
