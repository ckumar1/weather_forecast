# frozen_string_literal: true

class LocationsController < ApplicationController
  before_action :set_location, only: [:show, :destroy]

  def index
    @locations = Location.recent

    @weather_results = @locations.filter_map do |location|
      result = weather_service.fetch_weather(location)
      [location.id, result] if result.success?
    end.to_h
  end

  def show
    # fetch weather data for the location
    result = weather_service.fetch_weather(@location)
     
    if result.success?
      @from_cache = result.from_cache
    else
      flash.now[:alert] = "Unable to fetch weather: #{result.error}"
    end
  end

  def new
    @location = Location.new
  end

  def create
    @location = Location.new(location_params)

    if @location.save
      result = weather_service.fetch_weather(@location)
      if result.success?
        redirect_to @location, notice: 'Location was successfully created.'
      else
        redirect_to @location, alert: "Location created, but unable to fetch weather: #{result.error}"
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @location.destroy
    redirect_to locations_url, notice: 'Location was successfully destroyed.'
  end

  private

  def weather_service
    @weather_service ||= WeatherApiService.new
  end

  def set_location
    @location = Location.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to locations_url, alert: 'Location not found.'
  end

  def location_params
    params.require(:location).permit(:address)
  end
end
