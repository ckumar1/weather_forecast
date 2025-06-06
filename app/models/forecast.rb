# frozen_string_literal: true

# Represents a weather forecast for a specific location at a point in time.
# Forecasts include current temperature and conditions, as well as daily high/low
# temperatures. Forecasts are considered fresh for 30 minutes before requiring
# a refresh.
#
# @attribute current_temp [Decimal] The current temperature in Fahrenheit
# @attribute high_temp [Decimal] The forecasted high temperature for the day
# @attribute low_temp [Decimal] The forecasted low temperature for the day
# @attribute conditions [String] Text description of current weather conditions
# @attribute forecast_timestamp [DateTime] When this forecast was generated
class Forecast < ApplicationRecord
  CACHE_DURATION = 30.minutes

  belongs_to :location

  validates :current_temp, :forecast_timestamp, presence: true

  # Checks if the forecast is still within the cache duration window
  # @return [Boolean] true if forecast was created within the last 30 minutes
  def current?
    forecast_timestamp > CACHE_DURATION.ago
  end

  # Checks if the forecast has expired and needs refresh
  # @return [Boolean] true if forecast is older than 30 minutes
  def expired?
    !current?
  end

  # Formats the current temperature for display
  # @return [String] temperature with °F suffix or 'N/A' if nil
  def formatted_current_temp
    return 'N/A' if current_temp.nil?

    "#{current_temp.round(1)}°F"
  end

  # Formats the high temperature for display
  # @return [String] temperature with °F suffix or 'N/A' if nil
  def formatted_high_temp
    return 'N/A' if high_temp.nil?

    "#{high_temp.round(1)}°F"
  end

  # Formats the low temperature for display
  # @return [String] temperature with °F suffix or 'N/A' if nil
  def formatted_low_temp
    return 'N/A' if low_temp.nil?

    "#{low_temp.round(1)}°F"
  end

  # Returns human-readable age of the forecast
  # @return [String] relative time description (e.g., "5 minutes ago")
  def age
    return 'Just now' if forecast_timestamp > 1.minute.ago

    "#{time_ago_in_words(forecast_timestamp)} ago"
  end

  private

  # Helper method to format relative time
  # @param time [Time] the time to format
  # @return [String] human-readable relative time
  def time_ago_in_words(time)
    ActionController::Base.helpers.time_ago_in_words(time)
  end
end
