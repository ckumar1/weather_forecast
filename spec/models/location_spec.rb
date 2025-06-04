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

    describe 'duplicate addresses' do
      it 'does not allow duplicate addresses' do
        existing_location = create(:location, address: '123 Main St, Cupertino, CA 95014')
        new_location = build(:location, address: '123 MAIN ST, Cupertino, CA 95014')

        expect(new_location).not_to be_valid
        expect(new_location.errors[:address]).to include('has already been taken')
      end
    end
  end

  describe '#display_name' do
    it 'returns the address when city, state, and zipcode are blank' do
      location = build(:location, :not_geocoded, address: '123 Main St')
      expect(location.display_name).to eq('123 Main St')
    end

    it 'returns formatted city, state, zipcode when available' do
      location = build(:location, :geocoded)
      expect(location.display_name).to eq('Cupertino, CA, 95014')
    end

    it 'excludes blank values from the formatted display' do
      location = build(:location, city: 'Cupertino', state: '', zipcode: '95014')
      expect(location.display_name).to eq('Cupertino, 95014')
    end

    it 'handles partial geocoded data' do
      location = build(:location, city: 'Cupertino', state: 'CA', zipcode: nil)
      expect(location.display_name).to eq('Cupertino, CA')
    end
  end
end
