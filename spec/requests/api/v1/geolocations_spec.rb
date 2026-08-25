require "rails_helper"

RSpec.describe "Api::V1::Geolocations", type: :request do
  let(:jsonapi_headers) do
    { "Accept" => "application/vnd.api+json", "Content-Type" => "application/vnd.api+json" }
  end

  let(:ipstack_success_body) do
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

  def stub_ipstack(ip, status: 200, body:)
    stub_request(:get, "http://api.ipstack.com/#{ip}")
      .with(query: { access_key: "test-ipstack-access-key" })
      .to_return(status: status, body: body)
  end

  describe "GET /api/v1/geolocations/:location" do
    it "returns a stored geolocation by ip" do
      geolocation = create(:geolocation, ip: "8.8.8.8", latitude: 37.386, longitude: -122.0838)

      get "/api/v1/geolocations/8.8.8.8", headers: jsonapi_headers

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("application/vnd.api+json")

      body = response.parsed_body
      expect(body["data"]["type"]).to eq("geolocation")
      expect(body["data"]["id"]).to eq(geolocation.id.to_s)
      expect(body["data"]["attributes"].symbolize_keys).to include(
        ip: "8.8.8.8",
        url: nil,
        ip_type: "ipv4",
        country_name: "United States",
        city: "Mountain View",
        latitude: 37.386,
        longitude: -122.0838
      )
    end

    it "returns a stored geolocation by url" do
      create(:geolocation, :from_url, ip: "8.8.8.8")

      get "/api/v1/geolocations/google.com", headers: jsonapi_headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"]["attributes"]["url"]).to eq("google.com")
    end

    it "finds a geolocation by url through DNS resolution when only the ip is stored" do
      create(:geolocation, ip: "8.8.8.8")
      allow(Resolv).to receive(:getaddress).with("google.com").and_return("8.8.8.8")

      get "/api/v1/geolocations/google.com", headers: jsonapi_headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"]["attributes"]["ip"]).to eq("8.8.8.8")
    end

    it "returns 404 for an unknown ip" do
      get "/api/v1/geolocations/1.2.3.4", headers: jsonapi_headers

      expect(response).to have_http_status(:not_found)
      expect(response.media_type).to eq("application/vnd.api+json")

      error = response.parsed_body["errors"].first
      expect(error["status"]).to eq("404")
      expect(error["title"]).to eq("Not Found")
      expect(error["detail"]).to include("1.2.3.4")
    end

    it "returns 404 for a url that cannot be resolved" do
      allow(Resolv).to receive(:getaddress).with("does-not-exist.example")
        .and_raise(Resolv::ResolvError)

      get "/api/v1/geolocations/does-not-exist.example", headers: jsonapi_headers

      expect(response).to have_http_status(:not_found)
    end

    it "returns 422 for an invalid location" do
      get "/api/v1/geolocations/not%20a%20url", headers: jsonapi_headers

      expect(response).to have_http_status(:unprocessable_content)

      error = response.parsed_body["errors"].first
      expect(error["status"]).to eq("422")
      expect(error["detail"]).to include("not a valid IP address or URL")
    end
  end

  describe "POST /api/v1/geolocations" do
    def post_geolocation(payload)
      post "/api/v1/geolocations", params: payload.to_json, headers: jsonapi_headers
    end

    it "fetches and stores the geolocation for an ip" do
      stub_ipstack("8.8.8.8", body: ipstack_success_body)

      expect {
        post_geolocation(data: { type: "geolocations", attributes: { ip_or_url: "8.8.8.8" } })
      }.to change(Geolocation, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(response.media_type).to eq("application/vnd.api+json")

      attributes = response.parsed_body["data"]["attributes"]
      expect(attributes["ip"]).to eq("8.8.8.8")
      expect(attributes["country_name"]).to eq("United States")
      expect(attributes["latitude"]).to eq(37.386)
      expect(attributes["longitude"]).to eq(-122.0838)

      expect(Geolocation.last.attributes.symbolize_keys)
        .to include(ip: "8.8.8.8", url: nil, country_name: "United States")
    end

    it "fetches and stores the geolocation for a url" do
      allow(Resolv).to receive(:getaddress).with("google.com").and_return("8.8.8.8")
      stub_ipstack("8.8.8.8", body: ipstack_success_body)

      post_geolocation(data: { attributes: { ip_or_url: "https://google.com/search?q=x" } })

      expect(response).to have_http_status(:created)
      expect(response.parsed_body["data"]["attributes"]["url"]).to eq("google.com")
      expect(Geolocation.last.url).to eq("google.com")
    end

    it "returns 409 when the geolocation is already stored" do
      create(:geolocation, ip: "8.8.8.8")

      expect {
        post_geolocation(data: { attributes: { ip_or_url: "8.8.8.8" } })
      }.not_to change(Geolocation, :count)

      expect(response).to have_http_status(:conflict)

      error = response.parsed_body["errors"].first
      expect(error["status"]).to eq("409")
      expect(error["title"]).to eq("Conflict")
      expect(error["detail"]).to include("8.8.8.8")
    end

    it "returns 422 for invalid input" do
      post_geolocation(data: { attributes: { ip_or_url: "not a url" } })

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["errors"].first["detail"])
        .to include("not a valid IP address or URL")
    end

    it "returns 422 when the url cannot be resolved" do
      allow(Resolv).to receive(:getaddress).with("does-not-exist.example")
        .and_raise(Resolv::ResolvError)

      post_geolocation(data: { attributes: { ip_or_url: "does-not-exist.example" } })

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["errors"].first["detail"]).to include("Could not resolve host")
    end

    it "returns 422 when the provider rejects the lookup" do
      body = {
        success: false,
        error: { code: 106, type: "invalid_ip_address", info: "The IP Address supplied is invalid." }
      }.to_json
      stub_ipstack("10.0.0.1", body: body)

      post_geolocation(data: { attributes: { ip_or_url: "10.0.0.1" } })

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["errors"].first["detail"]).to include("invalid_ip_address")
    end

    it "returns 502 when the provider is unavailable" do
      stub_ipstack("8.8.8.8", status: 500, body: "internal server error")

      post_geolocation(data: { attributes: { ip_or_url: "8.8.8.8" } })

      expect(response).to have_http_status(:bad_gateway)

      error = response.parsed_body["errors"].first
      expect(error["status"]).to eq("502")
      expect(error["title"]).to eq("Bad Gateway")
    end

    it "returns 422 when the provider payload fails validations" do
      body = JSON.parse(ipstack_success_body).merge("latitude" => nil).to_json
      stub_ipstack("8.8.8.8", body: body)

      post_geolocation(data: { attributes: { ip_or_url: "8.8.8.8" } })

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["errors"].first["detail"]).to include("Latitude")
    end

    it "returns 400 when the data param is missing" do
      post "/api/v1/geolocations", params: { ip_or_url: "8.8.8.8" }.to_json, headers: jsonapi_headers

      expect(response).to have_http_status(:bad_request)

      error = response.parsed_body["errors"].first
      expect(error["status"]).to eq("400")
      expect(error["detail"]).to include("data")
    end

    it "returns 400 for a malformed JSON body" do
      post "/api/v1/geolocations", params: "{invalid json", headers: jsonapi_headers

      expect(response).to have_http_status(:bad_request)
    end
  end

  describe "DELETE /api/v1/geolocations/:location" do
    it "deletes a stored geolocation by ip" do
      create(:geolocation, ip: "8.8.8.8")

      expect {
        delete "/api/v1/geolocations/8.8.8.8", headers: jsonapi_headers
      }.to change(Geolocation, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end

    it "deletes a stored geolocation by url" do
      create(:geolocation, :from_url, ip: "8.8.8.8")

      expect {
        delete "/api/v1/geolocations/google.com", headers: jsonapi_headers
      }.to change(Geolocation, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end

    it "returns 404 for an unknown location" do
      delete "/api/v1/geolocations/1.2.3.4", headers: jsonapi_headers

      expect(response).to have_http_status(:not_found)
    end
  end
end
