# Rooms for direct message chats between users. These act as a singleton, so a single set of users will
# always refer to the same direct room.
class Rooms::Direct < Room
  before_create :set_membership_hash

  class << self
    def find_or_create_for(users)
      find_for(users) || create_for({}, users: users)
    end

    def membership_hash_for(users)
      Digest::SHA256.hexdigest(users.map(&:id).sort.join("-"))
    end

    private
      def find_for(users)
        find_by(membership_hash: membership_hash_for(users))
      end
  end

  def default_involvement
    "everything"
  end

  private
    def set_membership_hash
      self.membership_hash = self.class.membership_hash_for(users)
    end
end
