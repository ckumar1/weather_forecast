class Location < ApplicationRecord
  geocoded_by :address
  before_validation :normalize_address
  after_validation :geocode, if: :should_geocode?
  after_validation :set_geocoded_attributes, if: :should_set_geocoded_attributes?

  # Associations
  has_one :forecast, dependent: :destroy

  # Validations
  validates :address, presence: true, uniqueness: { case_sensitive: false }
  validate :coordinates_present_unless_skipped

  attr_accessor :skip_geocoding

  def display_name
    return address if city.blank? && state.blank? && zipcode.blank?

    [city, state, zipcode].reject(&:blank?).join(', ')
  end

  def geocoded?
    latitude.present? && longitude.present?
  end

  def coordinates
    [latitude, longitude]
  end

  private

  def normalize_address
    self.address = address&.strip&.squish
  end

  def should_geocode?
    address_changed? && !skip_geocoding
  end

  def should_set_geocoded_attributes?
    geocoded? && !skip_geocoding
  end

  def coordinates_present_unless_skipped
    return if skip_geocoding || new_record?

    errors.add(:base, "Location could not be geocoded") unless geocoded?
  end

  def set_geocoded_attributes
    return unless geocoded?
    return unless (result = Geocoder.search(coordinates).first)

    self.city ||= result.city
    self.state ||= result.state
    self.zipcode ||= result.postal_code
    self.country ||= result.country_code.upcase
  end
end
