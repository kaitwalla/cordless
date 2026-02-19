source "https://rubygems.org"

git_source(:github) { |repo| "https://github.com/#{repo}.git" }

# Rails
gem "rails", github: "rails/rails", branch: "main"
gem "ostruct"
gem "benchmark"

# Drivers
gem "sqlite3", "~> 2.7"
gem "redis", "~> 5.4"

# Deployment
gem "puma", "~> 6.6"

# Jobs
gem "resque", "~> 2.7"
gem "resque-pool", "~> 0.7"

# Assets
gem "propshaft", github: "rails/propshaft"
gem "importmap-rails", github: "rails/importmap-rails"

# Hotwire
gem "turbo-rails", github: "hotwired/turbo-rails"
gem "stimulus-rails", "~> 1.3"

# Media handling
gem "image_processing", "~> 1.14"
gem "aws-sdk-s3", "~> 1.169", require: false

# Telemetry
gem "sentry-ruby", "~> 5.26"
gem "sentry-rails", "~> 5.26"

# Other
gem "bcrypt", "~> 3.1"
gem "web-push", "~> 3.0"
gem "rqrcode", "~> 3.1"
gem "rails_autolink", "~> 1.1"
gem "geared_pagination", "~> 1.2"
gem "jbuilder", "~> 2.14"
gem "net-http-persistent", "~> 4.0"
gem "kredis", "~> 1.8"
gem "platform_agent", "~> 1.0"
gem "thruster", "~> 0.1"

group :development, :test do
  gem "debug"
  gem "rubocop-rails-omakase", require: false
  gem "faker", require: false
  gem "brakeman", require: false
end

group :test do
  gem "capybara"
  gem "mocha"
  gem "selenium-webdriver"
  gem "simplecov", require: false
  gem "webmock", require: false
end
