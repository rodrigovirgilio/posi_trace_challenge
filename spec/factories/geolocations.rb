FactoryBot.define do
  factory :geolocation do
    sequence(:ip) { |n| "8.8.8.#{n}" }
    url { nil }
    ip_type { "ipv4" }
    continent_code { "NA" }
    continent_name { "North America" }
    country_code { "US" }
    country_name { "United States" }
    region_code { "CA" }
    region_name { "California" }
    city { "Mountain View" }
    zip { "94035" }
    latitude { 37.386 }
    longitude { -122.0838 }

    trait :from_url do
      url { "google.com" }
    end
  end
end
