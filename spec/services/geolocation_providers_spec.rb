require "rails_helper"

RSpec.describe GeolocationProviders do
  describe ".build" do
    it "builds the ipstack provider by default" do
      expect(described_class.build).to be_a(GeolocationProviders::Ipstack)
    end

    it "builds a provider by symbol or string name" do
      expect(described_class.build(:ipstack)).to be_a(GeolocationProviders::Ipstack)
      expect(described_class.build("ipstack")).to be_a(GeolocationProviders::Ipstack)
    end

    it "raises for an unknown provider" do
      expect { described_class.build("nonsense") }
        .to raise_error(GeolocationProviders::UnknownProviderError, /Unknown geolocation provider/)
    end
  end
end
