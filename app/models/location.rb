# frozen_string_literal: true

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

  def display_name
    return address if city.blank? && state.blank?

    [city, state].reject(&:blank?).join(', ')
  end

  def geocoded?
    latitude.present? && longitude.present?
  end

  def coordinates
    [latitude, longitude]
  end

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
