# frozen_string_literal: true

require "rails_helper"

RSpec.configure do |config|
  # Specify a root folder where Swagger JSON files are generated
  # NOTE: If you're using the rswag-api to serve API descriptions, you'll need
  # to ensure that it's configured to serve Swagger from the same folder
  config.openapi_root = Rails.root.join("swagger").to_s

  # Define one or more Swagger documents and provide global metadata for each one
  # When you run the 'rswag:specs:swaggerize' rake task, the complete Swagger will
  # be generated at the provided relative path under openapi_root
  # By default, the operations defined in spec files are added to the first
  # document below. You can override this behavior by adding a openapi_spec tag to the
  # the root example_group in your specs, e.g. describe '...', openapi_spec: 'v2/swagger.json'
  config.openapi_specs = {
    "v1/openapi.yaml" => {
      openapi: "3.1.0",
      info: {
        title: "PosiTrace Geolocation API",
        version: "v1",
        description: <<~DESC
          RESTful API to register, retrieve and delete geolocation data based
          on an IP address or URL, backed by the ipstack geolocation service.

          All endpoints require a bearer token (see `API_TOKEN`) and speak
          JSON:API (`application/vnd.api+json`) for both input and output.
        DESC
      },
      paths: {},
      servers: [
        {
          url: "http://localhost:3000"
        }
      ],
      components: {
        securitySchemes: {
          bearer_auth: {
            type: :http,
            scheme: :bearer
          }
        }
      },
      security: [ { bearer_auth: [] } ]
    }
  }

  # Specify the format of the output Swagger file when running 'rswag:specs:swaggerize'.
  # The openapi_specs configuration option has the filename including format in
  # the key, this may want to be changed to avoid putting yaml in json files.
  config.openapi_format = :yaml
end
