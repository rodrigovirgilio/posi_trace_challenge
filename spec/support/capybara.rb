# frozen_string_literal: true

require "capybara/rspec"
require "capybara-screenshot/rspec"
require "selenium-webdriver"

Capybara.register_driver :headless_firefox do |app|
  options = Selenium::WebDriver::Firefox::Options.new
  options.add_argument("--headless")
  options.add_argument("--no-sandbox")
  options.add_argument("--disable-dev-shm-usage")
  options.add_argument("--window-size=1400,1000")
  Capybara::Selenium::Driver.new(app, browser: :firefox, options: options)
end

Capybara.javascript_driver = :headless_firefox
Capybara.default_driver = :rack_test
Capybara.default_max_wait_time = 5
Capybara.server = :puma, { Silent: true }

# Save screenshots to tmp/capybara
Capybara::Screenshot.prune_strategy = :keep_last_run
Capybara.save_path = Rails.root.join("tmp", "capybara")
