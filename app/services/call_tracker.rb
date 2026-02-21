class CallTracker
  KEY_PREFIX = "call_participants"
  KEY_EXPIRY = 1.hour.to_i

  def initialize(room)
    @room = room
  end

  def join(user)
    redis.sadd(key, user.id)
    redis.expire(key, KEY_EXPIRY)
  end

  def leave(user)
    redis.srem(key, user.id)
  end

  def participant_count
    redis.scard(key)
  end

  def participant_ids
    redis.smembers(key).map(&:to_i)
  end

  def active?
    participant_count > 0
  end

  class << self
    def active_room_ids
      redis.keys("#{KEY_PREFIX}:*").filter_map do |key|
        room_id = key.split(":").last.to_i
        room_id if redis.scard(key) > 0
      end
    end

    def counts_for_rooms(room_ids)
      return {} if room_ids.empty?

      room_ids.index_with do |room_id|
        redis.scard("#{KEY_PREFIX}:#{room_id}")
      end
    end

    private

    def redis
      Redis.new(url: ENV.fetch("REDIS_URL", "redis://localhost:6379"))
    end
  end

  private

  def key
    "#{KEY_PREFIX}:#{@room.id}"
  end

  def redis
    @redis ||= Redis.new(url: ENV.fetch("REDIS_URL", "redis://localhost:6379"))
  end
end
