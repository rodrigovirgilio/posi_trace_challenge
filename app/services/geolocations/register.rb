module Geolocations
  # Resolves, fetches and stores the geolocation for an IP address or URL.
  class Register
    def self.call(raw_input, provider: GeolocationProviders.build)
      new(provider: provider).call(raw_input)
    end

    def initialize(provider:)
      @provider = provider
    end

    def call(raw_input)
      input = GeolocationInput.parse(raw_input)
      ip = resolve_ip(input)
      raise AlreadyExistsError, ip if Geolocation.exists?(ip: ip)

      register(input, ip)
    end

    private

    def resolve_ip(input)
      return input.ip if input.ip?

      IpResolver.call(input.host)
    end

    def register(input, ip)
      record = Geolocation.new(attributes(input, ip))
      raise ValidationFailedError, record unless record.save

      record
    end

    def attributes(input, ip)
      @provider.fetch(ip).merge(ip: ip, url: input.host)
    end
  end
end
