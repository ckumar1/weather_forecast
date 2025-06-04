require 'rails_helper'

RSpec.describe Forecast, type: :model do
  describe 'factory' do
    it 'has a valid factory' do
      expect(build(:forecast)).to be_valid
    end
  end

  # Associations
  describe 'associations' do
    it { should belong_to(:location) }
  end

  # Validations
  describe 'validations' do
    it { should validate_presence_of(:current_temp) }
  end

  describe 'callbacks' do
    it 'automatically sets forecast_timestamp on creation' do
      location = create(:location)
      forecast = Forecast.create!(current_temp: 72.5, location: location)
      
      expect(forecast.forecast_timestamp).to be_present
      expect(forecast.forecast_timestamp).to be_within(1.second).of(Time.current)
    end
  end

  describe '#current?' do
    it 'returns true for recent forecasts' do
      forecast = build(:forecast, forecast_timestamp: 10.minutes.ago)
      expect(forecast).to be_current
    end
    
    it 'returns false for forecasts older than 30 minutes' do
      forecast = build(:forecast, forecast_timestamp: 31.minutes.ago)
      expect(forecast).not_to be_current
    end
  end
  
  describe '#expired?' do
    it 'is opposite of current?' do
      fresh_forecast = build(:forecast, forecast_timestamp: 5.minutes.ago)
      old_forecast = build(:forecast, :expired)
      
      expect(fresh_forecast).not_to be_expired
      expect(old_forecast).to be_expired
    end
  end
  
  describe '#formatted_current_temp' do
    it 'formats temperature with degree symbol' do
      forecast = build(:forecast, current_temp: 72.5)
      expect(forecast.formatted_current_temp).to eq('72.5°F')
    end
    
    it 'rounds to one decimal place' do
      forecast = build(:forecast, current_temp: 72.567)
      expect(forecast.formatted_current_temp).to eq('72.6°F')
    end
  end

  describe '#age' do
    it 'returns "Just now" for very recent forecasts' do
      forecast = build(:forecast, forecast_timestamp: 30.seconds.ago)
      expect(forecast.age).to eq('Just now')
    end
    
    it 'returns time ago for older forecasts' do
      # Using Timecop or travel_to would be better here, but keeping it simple
      forecast = build(:forecast, forecast_timestamp: 5.minutes.ago)
      expect(forecast.age).to include('minutes ago')
    end
  end

  describe 'defaults' do
    it 'sets from_cache to false by default' do
      forecast = Forecast.new
      expect(forecast.from_cache).to eq(false)
    end
    
    it 'sets forecast_timestamp on creation' do
      location = create(:location)
      forecast = Forecast.create!(current_temp: 72.5, location:)
      
      expect(forecast.forecast_timestamp).to be_within(1.second).of(Time.current)
    end
  end
end
