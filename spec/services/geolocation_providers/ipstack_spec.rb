require "rails_helper"

RSpec.describe GeolocationProviders::Ipstack do
  subject(:provider) { described_class.new(access_key: access_key, connection: connection) }

  let(:access_key) { "test-access-key" }
  let(:connection) { instance_double(Faraday::Connection) }

  let(:success_body) do
    {
      ip: "8.8.8.8",
      type: "ipv4",
      continent_code: "NA",
      continent_name: "North America",
      country_code: "US",
      country_name: "United States",
      region_code: "CA",
      region_name: "California",
      city: "Mountain View",
      zip: "94035",
      latitude: 37.386,
      longitude: -122.0838,
      location: { geoname_id: 5_375_480, capital: "Washington D.C." }
    }.to_json
  end

  def stub_response(status:, body:, success: status < 400)
    response = instance_double(Faraday::Response, success?: success, status: status, body: body)
    allow(connection).to receive(:get).and_return(response)
  end

  describe "#fetch" do
    it "requests the ipstack endpoint for the given ip with the access key" do
      stub_response(status: 200, body: success_body)

      provider.fetch("8.8.8.8")

      expect(connection).to have_received(:get)
        .with("http://api.ipstack.com/8.8.8.8", access_key: "test-access-key")
    end

    it "returns the normalized geolocation attributes" do
      stub_response(status: 200, body: success_body)

      expect(provider.fetch("8.8.8.8")).to eq(
        ip: "8.8.8.8",
        ip_type: "ipv4",
        continent_code: "NA",
        continent_name: "North America",
        country_code: "US",
        country_name: "United States",
        region_code: "CA",
        region_name: "California",
        city: "Mountain View",
        zip: "94035",
        latitude: 37.386,
        longitude: -122.0838
      )
    end

    context "when the access key is not configured" do
      let(:access_key) { nil }

      it "raises UnavailableError without calling the provider" do
        allow(connection).to receive(:get)

        expect { provider.fetch("8.8.8.8") }
          .to raise_error(GeolocationProviders::UnavailableError, /IPSTACK_ACCESS_KEY is not configured/)
        expect(connection).not_to have_received(:get)
      end
    end

    context "when ipstack reports an invalid ip (success: false, code 106)" do
      it "raises InvalidLookupError" do
        body = {
          success: false,
          error: { code: 106, type: "invalid_ip_address", info: "The IP Address supplied is invalid." }
        }.to_json
        stub_response(status: 200, body: body)

        expect { provider.fetch("127.0.0.1") }
          .to raise_error(GeolocationProviders::InvalidLookupError, /invalid_ip_address/)
      end
    end

    context "when ipstack reports a provider-side error (success: false, other codes)" do
      it "raises UnavailableError" do
        body = {
          success: false,
          error: { code: 104, type: "usage_limit_reached", info: "Monthly quota exceeded." }
        }.to_json
        stub_response(status: 200, body: body)

        expect { provider.fetch("8.8.8.8") }
          .to raise_error(GeolocationProviders::UnavailableError, /usage_limit_reached/)
      end
    end

    it "raises UnavailableError when ipstack responds with an HTTP error" do
      stub_response(status: 500, body: "internal server error", success: false)

      expect { provider.fetch("8.8.8.8") }
        .to raise_error(GeolocationProviders::UnavailableError, /HTTP 500/)
    end

    it "raises UnavailableError when the response is not valid JSON" do
      stub_response(status: 200, body: "<html>not json</html>")

      expect { provider.fetch("8.8.8.8") }
        .to raise_error(GeolocationProviders::UnavailableError, /invalid JSON/)
    end

    it "raises UnavailableError when the response is missing the ip field" do
      stub_response(status: 200, body: { country_name: "United States" }.to_json)

      expect { provider.fetch("8.8.8.8") }
        .to raise_error(GeolocationProviders::UnavailableError, /missing/)
    end

    it "raises UnavailableError when the connection fails" do
      allow(connection).to receive(:get).and_raise(Faraday::TimeoutError)

      expect { provider.fetch("8.8.8.8") }
        .to raise_error(GeolocationProviders::UnavailableError, /request failed/)
    end
  end
end
