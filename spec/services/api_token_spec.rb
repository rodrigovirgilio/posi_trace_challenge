require "rails_helper"

RSpec.describe ApiToken do
  describe ".valid?" do
    around do |example|
      original = ENV.fetch("API_TOKEN", nil)
      ENV["API_TOKEN"] = "secret-token"
      example.run
      original ? ENV["API_TOKEN"] = original : ENV.delete("API_TOKEN")
    end

    it "returns true for the configured token" do
      expect(described_class.valid?("secret-token")).to be(true)
    end

    it "returns false for a wrong token" do
      expect(described_class.valid?("wrong-token")).to be(false)
    end

    it "returns false for a token of a different length" do
      expect(described_class.valid?("secret-token-but-much-longer-than-the-original")).to be(false)
    end

    it "returns false for nil" do
      expect(described_class.valid?(nil)).to be(false)
    end

    it "returns false for a blank token" do
      expect(described_class.valid?("")).to be(false)
    end

    it "returns false when no token is configured" do
      ENV.delete("API_TOKEN")

      expect(described_class.valid?("secret-token")).to be(false)
    end
  end
end
