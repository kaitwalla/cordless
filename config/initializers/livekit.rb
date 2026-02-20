# Skip validation during asset precompilation
skip_validation = ENV["SECRET_KEY_BASE_DUMMY"].present? || Rails.env.local?

Rails.application.config.x.livekit = ActiveSupport::InheritableOptions.new(
  api_key: ENV.fetch("LIVEKIT_API_KEY") { skip_validation ? "devkey" : raise("LIVEKIT_API_KEY is required") },
  api_secret: ENV.fetch("LIVEKIT_API_SECRET") { skip_validation ? "secret" : raise("LIVEKIT_API_SECRET is required") },
  url: ENV.fetch("LIVEKIT_URL", "ws://localhost:7880")
)
