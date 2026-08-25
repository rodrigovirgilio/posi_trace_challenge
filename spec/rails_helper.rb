require 'spec_helper'
ENV['RAILS_ENV'] ||= 'test'
ENV['IPSTACK_ACCESS_KEY'] ||= 'test-ipstack-access-key'
ENV['API_TOKEN'] ||= 'test-api-token'
require_relative '../config/environment'
abort("The Rails environment is running in production mode!") if Rails.env.production?
require 'rspec/rails'
require 'factory_bot_rails'
require 'webmock/rspec'

WebMock.disable_net_connect!(allow_localhost: true)

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories.
Rails.root.glob("spec/support/**/*.rb").sort_by(&:to_s).each { |f| require f }

begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end

RSpec.configure do |config|
  config.fixture_paths = [ Rails.root.join("spec/fixtures") ]
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!
  config.include FactoryBot::Syntax::Methods
end
