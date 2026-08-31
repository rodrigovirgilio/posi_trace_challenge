require "digest"

# Verifies bearer tokens presented to the API against the configured
# API_TOKEN environment variable. Fails closed when no token is configured.
class ApiToken
  def self.valid?(provided)
    expected = ENV["API_TOKEN"]
    return false if expected.blank? || provided.blank?

    ActiveSupport::SecurityUtils.secure_compare(
      Digest::SHA256.hexdigest(provided),
      Digest::SHA256.hexdigest(expected)
    )
  end
end
