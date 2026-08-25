require "json"

module GeolocationProviders
  # ipstack adapter. Docs: https://docs.apilayer.com/ipstack/docs/api-documentation
  #
  # Implements the provider contract: #fetch(ip) returns a normalized
  # attributes hash for Geolocation and raises GeolocationProviders::Error
  # subclasses on failure.
  class Ipstack
    ENDPOINT = "http://api.ipstack.com"

    # ipstack error codes that mean the lookup itself is invalid
    # (106 = invalid_ip_address, also used for reserved/private ranges).
    CLIENT_ERROR_CODES = [ 106 ].freeze

    def initialize(access_key: default_access_key, connection: nil)
      @access_key = access_key
      @connection = connection || build_connection
    end

    def fetch(ip)
      raise UnavailableError, "IPSTACK_ACCESS_KEY is not configured" if @access_key.blank?

      parse(response_for(ip))
    rescue Faraday::Error => e
      raise UnavailableError, "ipstack request failed: #{e.message}"
    rescue KeyError => e
      raise UnavailableError, "ipstack response is missing #{e.key}"
    end

    private

    def response_for(ip)
      @connection.get("#{ENDPOINT}/#{ip}", access_key: @access_key)
    end

    def parse(response)
      unless response.success?
        raise UnavailableError, "ipstack responded with HTTP #{response.status}"
      end

      body = JSON.parse(response.body, symbolize_names: true)
      raise_error_from(body) if body[:success] == false

      normalize(body)
    rescue JSON::ParserError
      raise UnavailableError, "ipstack returned an invalid JSON response"
    end

    def raise_error_from(body)
      error = body[:error] || {}
      message = "ipstack error #{error[:code]} (#{error[:type]}): #{error[:info]}"

      if CLIENT_ERROR_CODES.include?(error[:code])
        raise InvalidLookupError, message
      end

      raise UnavailableError, message
    end

    def normalize(body)
      {
        ip: body.fetch(:ip),
        ip_type: body[:type],
        continent_code: body[:continent_code],
        continent_name: body[:continent_name],
        country_code: body[:country_code],
        country_name: body[:country_name],
        region_code: body[:region_code],
        region_name: body[:region_name],
        city: body[:city],
        zip: body[:zip],
        latitude: body[:latitude],
        longitude: body[:longitude]
      }
    end

    def build_connection
      Faraday.new do |f|
        f.options.open_timeout = 2
        f.options.timeout = 5
      end
    end

    def default_access_key
      Rails.configuration.x.geolocation.ipstack_access_key
    end
  end
end
