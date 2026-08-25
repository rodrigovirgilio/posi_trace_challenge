require "rails_helper"

RSpec.describe Geolocation, type: :model do
  subject(:geolocation) { build(:geolocation) }

  it "is valid with valid attributes" do
    expect(geolocation).to be_valid
  end

  describe "ip" do
    it "must be present" do
      geolocation.ip = nil
      expect(geolocation).not_to be_valid
      expect(geolocation.errors[:ip]).to include("can't be blank")
    end

    it "must be unique" do
      create(:geolocation, ip: "8.8.8.8")
      duplicate = build(:geolocation, ip: "8.8.8.8")

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:ip]).to include("has already been taken")
    end

    it "must be a valid ip address" do
      geolocation.ip = "not-an-ip"

      expect(geolocation).not_to be_valid
      expect(geolocation.errors[:ip]).to include("is invalid")
    end

    it "accepts a valid ipv6 address" do
      geolocation.ip = "2606:4700:4700::1111"
      expect(geolocation).to be_valid
    end
  end

  describe "latitude" do
    it "must be present" do
      geolocation.latitude = nil
      expect(geolocation).not_to be_valid
      expect(geolocation.errors[:latitude]).to include("can't be blank")
    end

    it "accepts the boundary values" do
      geolocation.latitude = 90
      expect(geolocation).to be_valid
      geolocation.latitude = -90
      expect(geolocation).to be_valid
    end

    it "rejects values above 90" do
      geolocation.latitude = 90.000001
      expect(geolocation).not_to be_valid
    end

    it "rejects values below -90" do
      geolocation.latitude = -90.000001
      expect(geolocation).not_to be_valid
    end
  end

  describe "longitude" do
    it "must be present" do
      geolocation.longitude = nil
      expect(geolocation).not_to be_valid
      expect(geolocation.errors[:longitude]).to include("can't be blank")
    end

    it "accepts the boundary values" do
      geolocation.longitude = 180
      expect(geolocation).to be_valid
      geolocation.longitude = -180
      expect(geolocation).to be_valid
    end

    it "rejects values above 180" do
      geolocation.longitude = 180.000001
      expect(geolocation).not_to be_valid
    end

    it "rejects values below -180" do
      geolocation.longitude = -180.000001
      expect(geolocation).not_to be_valid
    end
  end
end
