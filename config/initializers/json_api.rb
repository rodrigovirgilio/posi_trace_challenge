# Register the JSON:API media type so request bodies sent as
# application/vnd.api+json are parsed like regular JSON.
Mime::Type.register "application/vnd.api+json", :json_api

ActionDispatch::Request.parameter_parsers[:json_api] = ->(body) { JSON.parse(body) }

# Parse application/vnd.api+json response bodies like JSON in integration
# tests (response.parsed_body). The test encoder is only available once the
# testing framework is loaded, so it is registered only for the test env.
if Rails.env.test?
  require "action_dispatch/testing/request_encoder"

  ActionDispatch::RequestEncoder.register_encoder :json_api,
                                                  response_parser: ->(body) { JSON.parse(body) }
end
