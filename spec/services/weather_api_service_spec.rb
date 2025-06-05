# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WeatherApiService do
  let(:service) { described_class.new }

  describe '#fetch_weather' do
    context 'with valid US location' do
      let(:location) { create(:location) }

      it 'fetches weather by zipcode', vcr: { cassette_name: 'weather_api/us_zipcode' } do
        result = service.fetch_weather(location)
        
        expect(result.success?).to be true
        expect(result.data[:current_temp]).to be_a(Numeric)
        expect(result.data[:high_temp]).to be_a(Numeric)
        expect(result.data[:low_temp]).to be_a(Numeric)
        expect(result.data[:conditions]).to be_present
      end
    end

    context 'with non-US location' do
      let(:location) { create(:location, :london) }

      it 'fetches weather by zipcode if it exists', vcr: { cassette_name: 'weather_api/london_zipcode' } do
        result = service.fetch_weather(location)
        
        expect(result.success?).to be true
        expect(result.data[:current_temp]).to be_a(Numeric)
        expect(result.data[:conditions]).to be_present
      end
    end

    context 'with non-US location without zipcode' do
      let(:location) { create(:location, :london, zipcode: nil) }

      it 'fetches weather by latitude and longitude', vcr: { cassette_name: 'weather_api/london_coord' } do
        result = service.fetch_weather(location)
        
        expect(result.success?).to be true
        expect(result.data[:current_temp]).to be_a(Numeric)
        expect(result.data[:conditions]).to be_present
      end
     end
  end

  context 'with API errors' do
    let(:location) { create(:location) }
    before(:all) { VCR.turn_off! }
    after(:all) { VCR.turn_on! }
    

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
  end 

  context 'when API key is not set' do
    let(:location) { create(:location) }

    before do
      allow(ENV).to receive(:fetch).with('WEATHER_API_KEY', nil).and_return(nil)
    end

    it 'returns configuration error' do
      result = service.fetch_weather(location)

      expect(result.success?).to be false
      expect(result.error).to eq('Weather API key not configured')
    end
  end

  describe '#configured?' do
    it 'returns true if API key is set' do
      expect(service.configured?).to be true
    end

    it 'returns false if API key is not set' do
      allow(ENV).to receive(:fetch).with('WEATHER_API_KEY', nil).and_return(nil)
      expect(service.configured?).to be false
    end
  end
end
