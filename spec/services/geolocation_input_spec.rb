require "rails_helper"

RSpec.describe GeolocationInput do
  describe ".parse" do
    context "with an IP address" do
      it "parses an ipv4 address" do
        input = described_class.parse("8.8.8.8")

        expect(input).to be_ip
        expect(input).not_to be_url
        expect(input.ip).to eq("8.8.8.8")
        expect(input.host).to be_nil
      end

      it "parses an ipv6 address" do
        input = described_class.parse("2606:4700:4700::1111")

        expect(input).to be_ip
        expect(input.ip).to eq("2606:4700:4700::1111")
      end

      it "strips surrounding whitespace" do
        expect(described_class.parse("  8.8.8.8  ").ip).to eq("8.8.8.8")
      end
    end

    context "with a URL or hostname" do
      it "parses a bare hostname" do
        input = described_class.parse("google.com")

        expect(input).to be_url
        expect(input).not_to be_ip
        expect(input.host).to eq("google.com")
        expect(input.ip).to be_nil
      end

      it "parses a URL with scheme, path and query string" do
        input = described_class.parse("https://google.com/search?q=posi+trace")

        expect(input.host).to eq("google.com")
      end

      it "parses a URL with a port" do
        expect(described_class.parse("http://google.com:8080").host).to eq("google.com")
      end

      it "downcases the host" do
        expect(described_class.parse("HTTPS://GooGle.COM").host).to eq("google.com")
      end

      it "accepts hyphens inside labels" do
        expect(described_class.parse("my-tracking-site.example.com").host)
          .to eq("my-tracking-site.example.com")
      end

      it "rejects labels with leading or trailing hyphens" do
        expect { described_class.parse("-google.com") }
          .to raise_error(GeolocationInput::InvalidError)
        expect { described_class.parse("google-.com") }
          .to raise_error(GeolocationInput::InvalidError)
      end
    end

    context "with invalid input" do
      it "raises for nil" do
        expect { described_class.parse(nil) }
          .to raise_error(GeolocationInput::InvalidError, /not a valid IP address or URL/)
      end

      it "raises for an empty string" do
        expect { described_class.parse("") }
          .to raise_error(GeolocationInput::InvalidError)
      end

      it "raises for a blank string" do
        expect { described_class.parse("   ") }
          .to raise_error(GeolocationInput::InvalidError)
      end

      it "raises for free text" do
        expect { described_class.parse("not a url") }
          .to raise_error(GeolocationInput::InvalidError)
      end

      it "raises for a hostname with invalid characters" do
        expect { described_class.parse("goo_gle.com") }
          .to raise_error(GeolocationInput::InvalidError)
      end
    end
  end
end
