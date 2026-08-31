require "ipaddr"

class Geolocation < ApplicationRecord
  validates :ip, presence: true, uniqueness: true
  validates :latitude, presence: true,
                     numericality: { greater_than_or_equal_to: -90, less_than_or_equal_to: 90 }
  validates :longitude, presence: true,
                        numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180 }
  validate :ip_must_be_valid

  private

  def ip_must_be_valid
    return if ip.blank?

    errors.add(:ip, "is invalid") unless valid_ip?
  end

  def valid_ip?
    IPAddr.new(ip)
    true
  rescue IPAddr::InvalidAddressError
    false
  end
end
