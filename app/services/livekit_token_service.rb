require "livekit"

class LivekitTokenService
  TTL = 3600  # 1 hour in seconds

  def initialize(user:, room:)
    @user = user
    @room = room
  end

  def generate_token
    token = LiveKit::AccessToken.new(
      api_key: config.api_key,
      api_secret: config.api_secret,
      identity: user_identity,
      ttl: TTL
    )

    token.name = @user.name
    token.video_grant = video_grant

    token.to_jwt
  end

  def url
    config.url
  end

  def room_name
    "room_#{@room.id}"
  end

  private
    def user_identity
      "user_#{@user.id}"
    end

    def video_grant
      LiveKit::VideoGrant.new(
        roomJoin: true,
        room: room_name,
        canPublish: true,
        canSubscribe: true,
        canPublishData: true
      )
    end

    def config
      Rails.application.config.x.livekit
    end
end
