require "test_helper"

WebMock.disable!

Capybara.register_driver :remote_chrome do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument("--headless=new")
  options.add_argument("--no-sandbox")
  options.add_argument("--disable-dev-shm-usage")
  options.add_argument("--disable-gpu")
  options.add_argument("--window-size=1400,1400")

  Capybara::Selenium::Driver.new(
    app,
    browser: :remote,
    url: ENV["SELENIUM_URL"],
    options: options
  )
end

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  if ENV["SELENIUM_URL"].present?
    driven_by :remote_chrome

    setup do
      Capybara.server_host = "0.0.0.0"
      Capybara.app_host = "http://web:#{Capybara.current_session.server&.port || Capybara.server_port}"
    end
  else
    driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ]
  end

  include SystemTestHelper
end
