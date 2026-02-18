namespace :rooms do
  desc "Backfill membership_hash for existing direct rooms"
  task backfill_membership_hash: :environment do
    count = 0
    Rooms::Direct.find_each do |room|
      room.update_column(:membership_hash, Rooms::Direct.membership_hash_for(room.users))
      count += 1
      print "." if count % 100 == 0
    end
    puts "\nBackfilled #{count} direct rooms"
  end
end
