require "ipaddr"

# Normalizes the raw "ip or url" input accepted by the API into either a
# canonical IP address or a bare hostname.
class GeolocationInput
  class InvalidError < StandardError
    def initialize(input)
      super("#{input.inspect} is not a valid IP address or URL")
    end
  end

  HOSTNAME_PATTERN = /\A[a-z0-9]+([\-.][a-z0-9]+)*\z/i
  SCHEME_PATTERN = %r{\A[a-z][a-z0-9+.-]*://}i

  attr_reader :ip, :host

  def self.parse(raw)
    new(raw)
  end

  def initialize(raw)
    @raw = raw.to_s.strip
    raise InvalidError, @raw if @raw.empty?

    if (parsed_ip = parse_ip)
      @ip = parsed_ip
    else
      @host = parse_host
    end
  end

  def ip?
    !@ip.nil?
  end

  def url?
    !@host.nil?
  end

  private

  def parse_ip
    IPAddr.new(@raw).to_s
  rescue IPAddr::InvalidAddressError
    nil
  end

  def parse_host
    host = URI.parse(with_scheme(@raw)).host&.downcase
    raise InvalidError, @raw unless host&.match?(HOSTNAME_PATTERN)

    host
  rescue URI::InvalidURIError
    raise InvalidError, @raw
  end

  def with_scheme(value)
    value.match?(SCHEME_PATTERN) ? value : "https://#{value}"
  end
end
