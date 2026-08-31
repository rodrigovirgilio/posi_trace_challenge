require "resolv"

# Resolves a hostname to an IP address via DNS so it can be geolocated.
class IpResolver
  class ResolutionError < StandardError
    def initialize(host)
      super("Could not resolve host #{host.inspect} to an IP address")
    end
  end

  def self.call(host)
    Resolv.getaddress(host)
  rescue Resolv::ResolvError
    raise ResolutionError, host
  end
end
