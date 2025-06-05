# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WeatherApiService do
  let(:service) { described_class.new }

  before do
    Rails.cache.clear
  end

  describe '#fetch_weather' do
    context 'with fresh API call' do
      let(:location) { create(:location) }

      it 'fetches weather and creates forecast', vcr: { cassette_name: 'weather_api/fresh_call' } do
        expect {
          result = service.fetch_weather(location)
          
          expect(result.success?).to be true
          expect(result.from_cache).to be false
          expect(result.forecast).to be_present
          expect(result.forecast.current_temp).to be_a(Numeric)
          expect(result.forecast.conditions).to be_present
        }.to change { Forecast.count }.by(1)
      end
    end

    context 'with existing current forecast' do
      let(:location) { create(:location) }
      let!(:current_forecast) { create(:forecast, location:, forecast_timestamp: 10.minutes.ago) }

      it 'returns existing forecast without API call' do
        expect(HTTParty).not_to receive(:get)
        
        result = service.fetch_weather(location)
        
        expect(result.success?).to be true
        expect(result.from_cache).to be true
        expect(result.forecast).to eq(current_forecast)
      end
    end

    context 'with expired forecast' do
      let(:location) { create(:location) }
      let!(:expired_forecast) { create(:forecast, :expired, location:, current_temp: 99) }

      it 'fetches fresh data', vcr: { cassette_name: 'weather_api/refresh_expired' } do
        result = service.fetch_weather(location)
        
        expect(result.success?).to be true
        expect(result.from_cache).to be false
        expect(location.forecast.reload.current_temp).not_to eq(99)
      end
    end

    context 'with cached data' do
      let(:location) { create(:location) }
      let(:cached_weather_data) do
        {
          current_temp: 75.0,
          high_temp: 80.0,
          low_temp: 70.0,
          conditions: 'Sunny',
          fetched_at: 5.minutes.ago
        }
      end

      before do
        Rails.cache.write(location.weather_cache_key, cached_weather_data, expires_in: 30.minutes)
      end

      it 'uses cached data without API call' do
        expect(HTTParty).not_to receive(:get)
        
        result = service.fetch_weather(location)
        
        expect(result.success?).to be true
        expect(result.from_cache).to be true
        expect(result.forecast.current_temp).to eq(75.0)
      end

      context 'with existing expired forecast' do
        let!(:old_forecast) { create(:forecast, :expired, location:, current_temp: 65.0) }

        it 'updates existing forecast with cached data' do
          expect {
            service.fetch_weather(location)
          }.not_to change { Forecast.count }
          
          expect(location.reload.forecast.current_temp).to eq(75.0)
        end
      end
    end

    context 'with multiple locations sharing zipcode' do
      let(:location1) { create(:location) }
      let(:location2) { create(:location, address: '2 Apple Park Way, Cupertino, CA 95014') }

      it 'second location uses cached data from first', vcr: { cassette_name: 'weather_api/shared_cache' } do
        result1 = service.fetch_weather(location1)
        expect(result1.from_cache).to be false
        
        result2 = service.fetch_weather(location2)
        expect(result2.from_cache).to be true
        expect(result2.forecast.current_temp).to eq(result1.forecast.current_temp)
      end
    end

    context 'with API errors' do
      let(:location) { create(:location) }
      
      before { VCR.turn_off! }
      after { VCR.turn_on! }

      it 'handles invalid API key' do
        stub_request(:get, /api.weatherapi.com/)
          .to_return(status: 401, body: { error: { message: 'Invalid API key' } }.to_json)
        
        result = service.fetch_weather(location)
        
        expect(result.success?).to be false
        expect(result.error).to eq('Invalid API key')
      end
      
      it 'handles network timeout' do
        stub_request(:get, /api.weatherapi.com/).to_timeout
        
        result = service.fetch_weather(location)
        
        expect(result.success?).to be false
        expect(result.error).to include('timed out')
      end

      it 'handles rate limit' do
        stub_request(:get, /api.weatherapi.com/)
          .to_return(status: 429)
        
        result = service.fetch_weather(location)
        
        expect(result.success?).to be false
        expect(result.error).to eq('API rate limit exceeded')
      end
    end

    context 'with invalid input' do
      it 'handles non-geocoded location' do
        location = build(:location, :not_geocoded)
        
        result = service.fetch_weather(location)
        
        expect(result.success?).to be false
        expect(result.error).to eq('Location must be geocoded')
      end

      it 'handles missing API key' do
        allow(ENV).to receive(:fetch).with('WEATHER_API_KEY', nil).and_return(nil)
        service = described_class.new
        
        result = service.fetch_weather(create(:location))

        expect(result.success?).to be false
        expect(result.error).to eq('Weather API key not configured')
      end
    end
  end

  describe '#configured?' do
    it 'returns true when API key is present' do
      expect(service.configured?).to be true
    end

    it 'returns false when API key is missing' do
      allow(ENV).to receive(:fetch).with('WEATHER_API_KEY', nil).and_return(nil)
      service = described_class.new
      expect(service.configured?).to be false
    end
  end
end
