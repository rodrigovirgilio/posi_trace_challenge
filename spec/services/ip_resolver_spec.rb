require "rails_helper"

RSpec.describe IpResolver do
  describe ".call" do
    it "returns the resolved IP address for a resolvable host" do
      allow(Resolv).to receive(:getaddress).with("google.com").and_return("142.250.79.46")

      expect(described_class.call("google.com")).to eq("142.250.79.46")
    end

    it "raises ResolutionError when the host cannot be resolved" do
      allow(Resolv).to receive(:getaddress).with("does-not-exist.example")
        .and_raise(Resolv::ResolvError)

      expect { described_class.call("does-not-exist.example") }
        .to raise_error(IpResolver::ResolutionError, /Could not resolve host/)
    end
  end
end
