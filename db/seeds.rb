# Seed data for local testing. These records let you exercise the API right
# after `bin/rails db:seed` without calling the ipstack provider.
geolocations = [
  {
    ip: "8.8.8.8",
    url: "dns.google",
    ip_type: "ipv4",
    continent_code: "NA",
    continent_name: "North America",
    country_code: "US",
    country_name: "United States",
    region_code: "CA",
    region_name: "California",
    city: "Mountain View",
    zip: "94043",
    latitude: 37.386,
    longitude: -122.0838
  },
  {
    ip: "1.1.1.1",
    url: "one.one.one.one",
    ip_type: "ipv4",
    continent_code: "OC",
    continent_name: "Oceania",
    country_code: "AU",
    country_name: "Australia",
    region_code: "NSW",
    region_name: "New South Wales",
    city: "Sydney",
    zip: "2000",
    latitude: -33.8688,
    longitude: 151.2093
  },
  {
    ip: "140.82.121.4",
    url: "github.com",
    ip_type: "ipv4",
    continent_code: "NA",
    continent_name: "North America",
    country_code: "US",
    country_name: "United States",
    region_code: "WA",
    region_name: "Washington",
    city: "Seattle",
    zip: "98101",
    latitude: 47.6062,
    longitude: -122.3321
  }
]

geolocations.each do |attributes|
  Geolocation.find_or_create_by!(ip: attributes[:ip]) do |geolocation|
    geolocation.assign_attributes(attributes)
  end
end
