# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LocationsController, type: :controller do
  let(:valid_attributes) { { address: '123 Main St, Cupertino, CA 95014' } }
  let(:invalid_attributes) { { address: '' } }

  describe 'GET #index' do
    context 'with no locations' do
      before { get :index }

      it 'returns a success response' do
        expect(response).to be_successful
        expect(assigns(:locations)).to eq([])
        expect(assigns(:weather_results)).to eq({})
      end
    end

    context 'with locations' do
      let!(:location1) { create(:location) }
      let!(:location2) { create(:location, :san_francisco) }
      let(:weather_service) { instance_double(WeatherApiService) }

      before do
        allow(WeatherApiService).to receive(:new).and_return(weather_service)
      end

      it 'assigns locations in recent order and fetches weather' do
        successful_result = WeatherApiService::Result.new(
          success?: true,
          forecast: build(:forecast, location: location1),
          from_cache: false
        )

        allow(weather_service).to receive(:fetch_weather).and_return(successful_result)

        get :index

        expect(assigns(:locations)).to eq([location2, location1])
        expect(assigns(:weather_results)).to have_key(location1.id)
        expect(assigns(:weather_results)).to have_key(location2.id)
      end

      it 'excludes failed weather results' do
        successful_result = WeatherApiService::Result.new(success?: true, forecast: build(:forecast))
        failed_result = WeatherApiService::Result.new(success?: false, error: 'API Error')

        allow(weather_service).to receive(:fetch_weather).with(location2).and_return(successful_result)
        allow(weather_service).to receive(:fetch_weather).with(location1).and_return(failed_result)

        get :index

        expect(assigns(:weather_results)).to eq({ location2.id => successful_result })
      end
    end
  end

  describe 'GET #show' do
    let(:location) { create(:location) }
    let(:weather_service) { instance_double(WeatherApiService) }

    before do
      allow(WeatherApiService).to receive(:new).and_return(weather_service)
    end

    context 'when location exists and weather fetch succeeds' do
      let(:base_result_attributes) do
        {
          success?: true,
          forecast: create(:forecast, location: location),
          from_cache: false
        }
      end

      let(:successful_result) { WeatherApiService::Result.new(base_result_attributes) }

      before do
        allow(weather_service).to receive(:fetch_weather).with(location).and_return(successful_result)
        get :show, params: { id: location.to_param }
      end

      it 'assigns the location and from_cache status' do
        expect(assigns(:location)).to eq(location)
        expect(assigns(:from_cache)).to eq(false)
        expect(response).to be_successful
      end

      context 'when data comes from cache' do
        let(:successful_result) { WeatherApiService::Result.new(base_result_attributes.merge(from_cache: true)) }

        it 'sets from_cache to true' do
          expect(assigns(:from_cache)).to eq(true)
        end
      end
    end

    context 'when weather fetch fails' do
      let(:failed_result) { WeatherApiService::Result.new(success?: false, error: 'API Error') }

      before do
        allow(weather_service).to receive(:fetch_weather).with(location).and_return(failed_result)
        get :show, params: { id: location.to_param }
      end

      it 'sets flash alert' do
        expect(assigns(:location)).to eq(location)
        expect(flash.now[:alert]).to eq('Unable to fetch weather: API Error')
      end
    end

    context 'when location does not exist' do
      before { get :show, params: { id: 'nonexistent' } }
      it 'redirects with alert' do
        expect(response).to redirect_to(locations_url)
        expect(flash[:alert]).to eq('Location not found.')
      end
    end
  end

  describe 'GET #new' do
    before { get :new }
    it 'assigns a new location' do
      expect(assigns(:location)).to be_a_new(Location)
      expect(response).to be_successful
    end
  end

  describe 'POST #create' do
    context 'with valid params' do
      before do
        # Mock geocoding to avoid API calls in controller tests
        allow_any_instance_of(Location).to receive(:geocode)
        allow_any_instance_of(Location).to receive(:geocoded?).and_return(true)
      end

      it 'creates a new Location and redirects' do
        expect do
          post :create, params: { location: valid_attributes }
        end.to change(Location, :count).by(1)

        expect(response).to redirect_to(Location.last)
        expect(flash[:notice]).to eq('Location was successfully created.')
      end
    end

    context 'with invalid params' do
      it 'does not create a Location and renders new template' do
        expect do
          post :create, params: { location: invalid_attributes }
        end.not_to change(Location, :count)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response).to render_template(:new)
      end
    end
  end
  describe 'DELETE #destroy' do
    let!(:location) { create(:location) }

    it 'destroys the location and redirects' do
      expect do
        delete :destroy, params: { id: location.to_param }
      end.to change(Location, :count).by(-1)

      expect(response).to redirect_to(locations_url)
      expect(flash[:notice]).to eq('Location was successfully destroyed.')
    end

    context 'when location does not exist' do
      before { delete :destroy, params: { id: 'nonexistent' } }
      it 'redirects with alert' do
        expect(response).to redirect_to(locations_url)
        expect(flash[:alert]).to eq('Location not found.')
      end
    end
  end

  describe 'private methods' do
    let(:controller) { described_class.new }
    describe '#location_params' do
      it 'permits address parameter' do
        params = ActionController::Parameters.new(
          location: { address: '123 Main St', malicious_param: 'hack' }
        )
        controller.params = params

        result = controller.send(:location_params)

        expect(result).to eq(ActionController::Parameters.new(address: '123 Main St').permit!)
      end
    end
  end
end
