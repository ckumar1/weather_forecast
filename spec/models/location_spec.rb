# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Location, type: :model do
  describe 'factory' do
    it 'has a valid factory' do
      expect(build(:location)).to be_valid
    end
  end

  describe 'associations' do
    it { should have_one(:forecast).dependent(:destroy) }
  end

  describe 'validations' do
    subject { build(:location) }

    it { should validate_presence_of(:address) }
    it { should validate_uniqueness_of(:address).case_insensitive }

    it 'is expected to validate that :address is case-insensitively unique' do
      location = create(:location, address: '123 Main St, Cupertino, CA 95014', skip_geocoding: true)
      expect(location).to be_valid

      location_duplicate = build(:location, address: '123 MAIN ST, Cupertino, CA 95014', skip_geocoding: true)
      expect(location_duplicate).not_to be_valid
      expect(location_duplicate.errors[:address]).to include('has already been taken')
    end

    describe 'geocoding' do
      context 'when address is provided without coordinates' do
        it 'geocodes the address', vcr: { cassette_name: 'geocoding/successful_geocoding' } do
          location = Location.new(address: 'Cupertino, CA')
          location.save

          expect(location).to be_valid
          expect(location.latitude).to be_present
          expect(location.longitude).to be_present
          expect(location.latitude).to be_within(0.001).of(37.322893)
          expect(location.longitude).to be_within(0.001).of(-122.03229)
          expect(location.city).to eq('Cupertino')
          expect(location.state).to eq('California')
          expect(location.zipcode).to eq('95014')
          expect(location.country).to eq('US')
        end
      end

      context 'when address is invalid' do
        it 'fails validation if geocoding returns no results', vcr: { cassette_name: 'geocoding/failed_geocoding' } do
          location = Location.new(address: 'zzzzzz invalid nonsense address 99999')
          location.save

          expect(location).not_to be_valid
          expect(location.errors[:base]).to include('Location could not be geocoded')
        end
      end
    end
  end

  describe 'scopes' do
    describe '.recent' do
      before do
        15.times do |i|
          create(:location,
                 address: "#{i + 1} Test St, City, CA",
                 created_at: i.seconds.ago)
        end
      end

      it 'returns the 10 most recently created locations in descending order' do
        recent_locations = Location.recent

        expect(recent_locations.count).to eq(10)
        expect(recent_locations.first.created_at).to be > recent_locations.last.created_at
      end
    end
  end

  describe '#display_name' do
    it 'returns the address when city and state are blank' do
      location = build(:location, :not_geocoded, address: '123 Main St')
      expect(location.display_name).to eq('123 Main St')
    end

    it 'returns formatted city, state when available' do
      location = build(:location)
      expect(location.display_name).to eq('Cupertino, CA')
    end

    it 'excludes blank values from the formatted display' do
      location = build(:location, state: '')
      expect(location.display_name).to eq('Cupertino')
    end
  end

  describe '#weather_cache_key' do
    it 'returns zipcode-based cache key when zipcode is present' do
      location = build(:location)
      expect(location.weather_cache_key).to eq('weather_forecast/zipcode/95014')
    end

    it 'returns coordinates-based cache key when zipcode is not present' do
      location = build(:location, zipcode: nil)
      expect(location.weather_cache_key).to eq('weather_forecast/coordinates/37.331686_-122.030656')
    end
  end
end
