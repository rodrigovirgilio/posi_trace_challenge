require "swagger_helper"

RSpec.describe "Geolocations API", type: :request do
  let(:Authorization) { "Bearer test-api-token" }

  geolocation_document_schema = {
    type: :object,
    properties: {
      data: {
        type: :object,
        properties: {
          id: { type: :string, example: "1" },
          type: { type: :string, example: "geolocation" },
          attributes: {
            type: :object,
            properties: {
              ip: { type: :string, example: "8.8.8.8" },
              url: { type: %i[string null], example: "google.com" },
              ip_type: { type: %i[string null], example: "ipv4" },
              continent_code: { type: %i[string null], example: "NA" },
              continent_name: { type: %i[string null], example: "North America" },
              country_code: { type: %i[string null], example: "US" },
              country_name: { type: %i[string null], example: "United States" },
              region_code: { type: %i[string null], example: "CA" },
              region_name: { type: %i[string null], example: "California" },
              city: { type: %i[string null], example: "Mountain View" },
              zip: { type: %i[string null], example: "94035" },
              latitude: { type: :number, example: 37.386 },
              longitude: { type: :number, example: -122.0838 }
            },
            required: %w[ip latitude longitude]
          }
        },
        required: %w[id type attributes]
      }
    },
    required: %w[data]
  }

  error_document_schema = {
    type: :object,
    properties: {
      errors: {
        type: :array,
        items: {
          type: :object,
          properties: {
            status: { type: :string, example: "404" },
            title: { type: :string, example: "Not Found" },
            detail: { type: :string, example: "No geolocation stored for 1.2.3.4" }
          },
          required: %w[status title detail]
        }
      }
    },
    required: %w[errors]
  }

  path "/api/v1/geolocations" do
    post "Registers a geolocation" do
      tags "Geolocations"
      description "Fetches the geolocation for an IP address or URL from the " \
                  "configured provider and stores it in the database."
      consumes "application/vnd.api+json"
      produces "application/vnd.api+json"
      parameter name: :payload, in: :body, schema: {
        type: :object,
        properties: {
          data: {
            type: :object,
            properties: {
              type: { type: :string, example: "geolocations" },
              attributes: {
                type: :object,
                properties: {
                  ip_or_url: { type: :string, example: "8.8.8.8" }
                },
                required: %w[ip_or_url]
              }
            },
            required: %w[attributes]
          }
        },
        required: %w[data]
      }

      response "201", "geolocation registered" do
        schema geolocation_document_schema

        let(:payload) { { data: { type: "geolocations", attributes: { ip_or_url: "8.8.8.8" } } } }

        before { stub_ipstack("8.8.8.8") }

        run_test! do |response|
          attributes = response.parsed_body["data"]["attributes"]
          expect(attributes["country_name"]).to eq("United States")
        end
      end

      response "400", "malformed request" do
        schema error_document_schema

        let(:payload) { { ip_or_url: "8.8.8.8" } }

        run_test!
      end

      response "401", "missing or invalid bearer token" do
        schema error_document_schema

        let(:Authorization) { nil }
        let(:payload) { { data: { attributes: { ip_or_url: "8.8.8.8" } } } }

        run_test!
      end

      response "409", "geolocation already registered" do
        schema error_document_schema

        let(:payload) { { data: { attributes: { ip_or_url: "8.8.8.8" } } } }

        before { create(:geolocation, ip: "8.8.8.8") }

        run_test!
      end

      response "422", "invalid input or rejected lookup" do
        schema error_document_schema

        let(:payload) { { data: { attributes: { ip_or_url: "not a url" } } } }

        run_test!
      end

      response "502", "geolocation provider unavailable" do
        schema error_document_schema

        let(:payload) { { data: { attributes: { ip_or_url: "8.8.8.8" } } } }

        before { stub_ipstack("8.8.8.8", status: 500, body: "internal server error") }

        run_test!
      end
    end
  end

  path "/api/v1/geolocations/{location}" do
    parameter name: :location, in: :path, required: true,
              description: "IP address (e.g. 8.8.8.8) or hostname (e.g. google.com)",
              schema: { type: :string, example: "8.8.8.8" }

    get "Retrieves a stored geolocation" do
      tags "Geolocations"
      produces "application/vnd.api+json"

      response "200", "geolocation found" do
        schema geolocation_document_schema

        let(:location) { "8.8.8.8" }

        before { create(:geolocation, ip: "8.8.8.8") }

        run_test! do |response|
          expect(response.parsed_body["data"]["attributes"]["ip"]).to eq("8.8.8.8")
        end
      end

      response "401", "missing or invalid bearer token" do
        schema error_document_schema

        let(:Authorization) { nil }
        let(:location) { "8.8.8.8" }

        run_test!
      end

      response "404", "geolocation not found" do
        schema error_document_schema

        let(:location) { "1.2.3.4" }

        run_test!
      end
    end

    delete "Deletes a stored geolocation" do
      tags "Geolocations"

      response "204", "geolocation deleted" do
        let(:location) { "8.8.8.8" }

        before { create(:geolocation, ip: "8.8.8.8") }

        run_test!
      end

      response "401", "missing or invalid bearer token" do
        schema error_document_schema

        let(:Authorization) { nil }
        let(:location) { "8.8.8.8" }

        run_test!
      end

      response "404", "geolocation not found" do
        schema error_document_schema

        let(:location) { "1.2.3.4" }

        run_test!
      end
    end
  end
end
