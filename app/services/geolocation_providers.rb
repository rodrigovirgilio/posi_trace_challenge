# Registry of geolocation providers. The geolocation module depends only on
# the provider's #fetch(ip) interface, so swapping the service provider is a
# matter of adding a new adapter and pointing GEOLOCATION_PROVIDER at it.
module GeolocationProviders
  class Error < StandardError; end

  # The provider rejected the lookup itself (e.g. invalid or reserved IP).
  class InvalidLookupError < Error; end

  # The provider could not serve the request (auth, quota, timeout, 5xx...).
  class UnavailableError < Error; end

  # GEOLOCATION_PROVIDER named an unregistered provider.
  class UnknownProviderError < Error; end

  PROVIDERS = {
    "ipstack" => "GeolocationProviders::Ipstack"
  }.freeze

  def self.build(name = Rails.configuration.x.geolocation.provider)
    PROVIDERS
      .fetch(name.to_s) { raise UnknownProviderError, "Unknown geolocation provider: #{name}" }
      .constantize
      .new
  end
end
