class GeolocationSerializer
  include JSONAPI::Serializer

  set_type :geolocation

  attributes :ip, :url, :ip_type,
             :continent_code, :continent_name,
             :country_code, :country_name,
             :region_code, :region_name,
             :city, :zip

  attribute :latitude do |geolocation|
    geolocation.latitude.to_f
  end

  attribute :longitude do |geolocation|
    geolocation.longitude.to_f
  end
end
