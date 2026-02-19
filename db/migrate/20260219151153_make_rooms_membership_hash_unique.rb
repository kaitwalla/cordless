class MakeRoomsMembershipHashUnique < ActiveRecord::Migration[8.2]
  def change
    remove_index :rooms, :membership_hash, where: "type = 'Rooms::Direct'"
    add_index :rooms, :membership_hash, unique: true, where: "type = 'Rooms::Direct'"
  end
end
