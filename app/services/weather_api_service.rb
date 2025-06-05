# frozen_string_literal: true

class WeatherApiService
  include HTTParty

  Result = Struct.new(:success?, :data, :error, keyword_init: true)

  base_uri ENV.fetch('WEATHER_API_BASE_URL', 'https://api.weatherapi.com/v1')
  default_timeout 10
  format :json

  def initialize
    @api_key = ENV.fetch('WEATHER_API_KEY', nil)
  end

  def fetch_weather(location)
    return api_key_error unless configured?

    query = determine_query_param(location)
    response = make_api_request(query)

    handle_response(response)
  rescue Net::ReadTimeout, Net::OpenTimeout => e
    Result.new(success?: false, error: "Weather API request timed out: #{e.message}")
  rescue StandardError => e
    Result.new(success?: false, error: "Weather API request failed: #{e.message}")
  end

  def configured?
    @api_key.present?
  end

  private

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
      }
    )
  end

  def handle_response(response)
    case response.code
    when 200
      parse_success_response(response)
    when 401
      Result.new(success?: false, error: 'Invalid API key')
    when 429
      Result.new(success?: false, error: 'API rate limit exceeded')
    else
      Result.new(success?: false, error: "Unexpected API response: #{response.code} - #{response.message}")
    end
  end

  def parse_success_response(response)
    body = response.parsed_response

    data = {
      current_temp: body.dig('current', 'temp_f'),
      conditions: body.dig('current', 'condition', 'text'),
      high_temp: body.dig('forecast', 'forecastday', 0, 'day', 'maxtemp_f'),
      low_temp: body.dig('forecast', 'forecastday', 0, 'day', 'mintemp_f'),
    }

    Result.new(success?: true, data:)
  end

  def api_key_error
    Result.new(success?: false, error: 'Weather API key not configured')
  end
end
