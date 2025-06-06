# frozen_string_literal: true

# Represents a geographical location that can be geocoded and have its weather forecasted.
# This model handles address normalization, geocoding, and serves as the primary record
# for weather forecasting locations.
#
# @attribute address [String] The full address of the location
# @attribute city [String] The city component of the address
# @attribute state [String] The state/province component of the address
# @attribute zipcode [String] The postal code of the address
# @attribute country [String] The country code (default: US or CA)
# @attribute latitude [Decimal] The latitude coordinate
# @attribute longitude [Decimal] The longitude coordinate
class Location < ApplicationRecord
  geocoded_by :address, params: { countrycodes: 'us,ca' }
  before_validation :normalize_address
  after_validation :geocode, if: :should_geocode?

  # Associations
  has_one :forecast, dependent: :destroy

  # Validations
  validates :address, presence: true, uniqueness: { case_sensitive: false }
  validate :coordinates_present_unless_skipped

  # Scopes
  scope :recent, -> { order(created_at: :desc).limit(10) }

  attr_accessor :skip_geocoding

  # Returns a user-friendly display name for the location
  # Prefers city/state format over raw address when available
  # @return [String] formatted location name
  def display_name
    return address if city.blank? && state.blank?

    [city, state].reject(&:blank?).join(', ')
  end

  # Checks if the location has valid geocoded coordinates
  # @return [Boolean] true if both latitude and longitude are present
  def geocoded?
    latitude.present? && longitude.present?
  end

  # Returns coordinates as an array for API calls
  # @return [Array<Decimal>] [latitude, longitude]
  def coordinates
    [latitude, longitude]
  end

  # Generates a cache key for weather data lookups
  # Prefers zipcode-based keys for better cache hit rates
  # @return [String] cache key for weather data
  def weather_cache_key
    return "weather_forecast/zipcode/#{zipcode}" if zipcode.present?

    "weather_forecast/coordinates/#{latitude}_#{longitude}"
  end

  private

  def normalize_address
    self.address = address&.strip&.squish
  end

  def should_geocode?
    address_changed? && !skip_geocoding && address.present?
  end

  def coordinates_present_unless_skipped
    return if skip_geocoding || new_record?

    errors.add(:base, 'Location could not be geocoded') unless geocoded?
  end

  # Override the geocode method to capture address components from the same API call
  def geocode
    return false unless address.present?

    result = Geocoder.search(address).first
    return false unless result

    update_coordinates(result)
    update_address_components(result)
    true
  end

  def update_coordinates(result)
    self.latitude = result.latitude
    self.longitude = result.longitude
  end

  def update_address_components(result)
    self.city ||= result.city
    self.state ||= result.state
    self.zipcode ||= result.postal_code
    self.country ||= result.country_code&.upcase
  end
end
