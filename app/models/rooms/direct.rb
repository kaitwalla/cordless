# Rooms for direct message chats between users. These act as a singleton, so a single set of users will
# always refer to the same direct room.
class Rooms::Direct < Room
  class << self
    def find_or_create_for(users)
      find_for_users(users) || create_for({ membership_hash: membership_hash_for(users), creator: users.first }, users: users)
    end

    def find_for_users(users)
      find_by(membership_hash: membership_hash_for(users))
    end

    def membership_hash_for(users)
      Digest::SHA256.hexdigest(users.map(&:id).sort.join("-"))
    end
  end

  def default_involvement
    "everything"
  end

  def server_dm?
    users.exists?(id: User.server.id)
  rescue ActiveRecord::RecordNotFound
    false
  end
end
