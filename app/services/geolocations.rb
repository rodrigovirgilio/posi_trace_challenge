# Namespace for the geolocation use-case services.
module Geolocations
  # A geolocation for the requested IP is already stored.
  class AlreadyExistsError < StandardError
    def initialize(ip)
      super("A geolocation for #{ip} already exists")
    end
  end

  # The provider returned data that does not satisfy model validations.
  class ValidationFailedError < StandardError
    attr_reader :record

    def initialize(record)
      @record = record
      super(record.errors.full_messages.to_sentence)
    end
  end
end
