module Geolocations
  # Finds a stored geolocation by IP address or URL.
  class Locator
    def self.call(raw_input)
      input = GeolocationInput.parse(raw_input)
      find(input) || raise(ActiveRecord::RecordNotFound,
                           "No geolocation stored for #{input.ip || input.host}")
    end

    def self.find(input)
      find_direct(input) || find_by_resolved_ip(input)
    end

    def self.find_direct(input)
      return Geolocation.find_by(ip: input.ip) if input.ip?

      Geolocation.find_by(url: input.host)
    end

    def self.find_by_resolved_ip(input)
      return if input.ip?

      Geolocation.find_by(ip: IpResolver.call(input.host))
    rescue IpResolver::ResolutionError
      nil
    end
  end
end
