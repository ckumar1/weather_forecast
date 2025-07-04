# frozen_string_literal: true

# Service for fetching weather data from WeatherAPI.com with intelligent caching.
# Uses database-first caching strategy to leverage Rails association optimizations.
#
# Caching approach:
# 1. Check database for current forecast (fast association lookup)
# 2. Check Rails cache if no current forecast exists
# 3. Make API call as last resort
class WeatherApiService
  include HTTParty

  # Result object for consistent success/failure handling
  Result = Struct.new(:success?, :forecast, :error, :from_cache, keyword_init: true)

  base_uri ENV.fetch('WEATHER_API_BASE_URL', 'https://api.weatherapi.com/v1')
  default_timeout 10
  format :json

  def initialize
    @api_key = ENV.fetch('WEATHER_API_KEY', nil)
  end

  # Fetches weather data for a location using database-first caching
  # @param location [Location] must be geocoded
  # @return [Result] success/failure with forecast data or error
  def fetch_weather(location)
    return api_key_error unless configured?
    return location_error unless location&.geocoded?

    fetch_from_existing_forecast(location) ||
      fetch_from_cache(location) ||
      fetch_fresh_weather(location)
  end

  private

  # Check database first - leverages Rails association caching
  def fetch_from_existing_forecast(location)
    return unless location.forecast&.current?

    Rails.logger.info "[WeatherAPI] Using existing forecast for location #{location.id}"
    Result.new(success?: true, forecast: location.forecast, from_cache: true)
  end

  # Check Rails cache for locations without current forecasts
  def fetch_from_cache(location)
    cached_data = Rails.cache.read(location.weather_cache_key)
    return unless cached_data

    Rails.logger.info "[WeatherAPI] Cache hit for #{location.weather_cache_key}"
    forecast = create_or_update_forecast(location, cached_data)
    Result.new(success?: true, forecast: forecast, from_cache: true)
  end

  # Last resort - make fresh API call
  def fetch_fresh_weather(location)
    query = determine_query_param(location)
    response = make_api_request(query)

    handle_response(response, location)
  rescue Net::ReadTimeout, Net::OpenTimeout => e
    Result.new(success?: false, error: "Weather API request timed out: #{e.message}")
  end

  def configured?
    @api_key.present?
  end

  # Prefer zipcode over coordinates for better API accuracy
  def determine_query_param(location)
    location.zipcode.presence || "#{location.latitude},#{location.longitude}"
  end

  def make_api_request(query)
    self.class.get('/forecast.json',
                   query: {
                     key: @api_key,
                     q: query,
                     days: 1,
                     aqi: 'no',
                     alerts: 'no'
                   })
  end

  def handle_response(response, location)
    case response.code
    when 200
      handle_success_response(response, location)
    when 401
      Result.new(success?: false, error: 'Invalid API key')
    when 429
      Result.new(success?: false, error: 'API rate limit exceeded')
    else
      Result.new(success?: false, error: "Unexpected API response: #{response.code}")
    end
  end

  def handle_success_response(response, location)
    Rails.logger.info '[WeatherAPI] Successfully fetched weather data'

    cache_data = parse_success_response(response).merge(fetched_at: Time.current)
    Rails.cache.write(location.weather_cache_key, cache_data, expires_in: Forecast::CACHE_DURATION)

    forecast = create_or_update_forecast(location, cache_data)
    Result.new(success?: true, forecast:, from_cache: false)
  end

  def parse_success_response(response)
    body = response.parsed_response

    {
      current_temp: body.dig('current', 'temp_f'),
      conditions: body.dig('current', 'condition', 'text'),
      high_temp: body.dig('forecast', 'forecastday', 0, 'day', 'maxtemp_f'),
      low_temp: body.dig('forecast', 'forecastday', 0, 'day', 'mintemp_f')
    }
  end

  def create_or_update_forecast(location, data)
    forecast_attributes = build_forecast_attributes(data)
    location.forecast&.update!(forecast_attributes) || location.create_forecast!(forecast_attributes)
  end

  def build_forecast_attributes(data)
    {
      current_temp: data[:current_temp],
      high_temp: data[:high_temp],
      low_temp: data[:low_temp],
      conditions: data[:conditions],
      forecast_timestamp: data[:fetched_at] || Time.current
    }
  end

  def api_key_error
    Result.new(success?: false, error: 'Weather API key not configured')
  end

  def location_error
    Result.new(success?: false, error: 'Location must be geocoded')
  end
end
