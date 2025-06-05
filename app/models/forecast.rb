class Forecast < ApplicationRecord
  CACHE_DURATION = 30.minutes

  belongs_to :location

  validates :current_temp, :forecast_timestamp, presence: true

  def current?
    forecast_timestamp > CACHE_DURATION.ago
  end

  def expired?
    !current?
  end

  def formatted_current_temp
    return 'N/A' if current_temp.nil?
    
    "#{current_temp.round(1)}°F"
  end

  def formatted_high_temp
    return 'N/A' if high_temp.nil?
    
    "#{high_temp.round(1)}°F"
  end

  def formatted_low_temp
    return 'N/A' if low_temp.nil?
    
    "#{low_temp.round(1)}°F"
  end

  def age
    return 'Just now' if forecast_timestamp > 1.minute.ago
    
    "#{time_ago_in_words(forecast_timestamp)} ago"
  end

  private

  def time_ago_in_words(time)
    ActionController::Base.helpers.time_ago_in_words(time)
  end
end
