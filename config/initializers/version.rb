Rails.application.config.app_version = ENV["APP_VERSION"].presence || begin
  version_file = Rails.root.join("VERSION")
  if version_file.exist?
    version_file.read.strip
  else
    # Fall back to git describe for development
    `git describe --tags 2>/dev/null`.strip.presence || "dev"
  end
end

Rails.application.config.git_revision = ENV["GIT_REVISION"].presence ||
  `git rev-parse --short HEAD 2>/dev/null`.strip.presence
