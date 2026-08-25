# Shared WebMock stubs for ipstack lookups in request specs.
module IpstackStub
  IPSTACK_SUCCESS_BODY = {
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
  }.freeze

  def stub_ipstack(ip, status: 200, body: IPSTACK_SUCCESS_BODY.to_json)
    stub_request(:get, "http://api.ipstack.com/#{ip}")
      .with(query: { access_key: "test-ipstack-access-key" })
      .to_return(status: status, body: body)
  end
end

RSpec.configure do |config|
  config.include IpstackStub, type: :request
end
