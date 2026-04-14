# Handles forecast lookup requests. Provides a search form (new) and displays
# forecast results (create). Delegates all business logic to ForecastLookupService.
class ForecastsController < ApplicationController
  # GET /
  # Renders the address search form.
  def new
  end

  # POST /forecast
  # Looks up the forecast for the given address and renders results.
  # On error, renders an inline error page instead of redirecting.
  def create
    @address = forecast_params[:address]

    if @address.blank?
      render_error("Please enter an address to look up the forecast.")
      return
    end

    result = ForecastLookupService.call(@address)
    @forecast = result.forecast
    @zip_code = result.zip_code
    @city     = result.city
    @cached   = result.cached?
  rescue AddressGeocodingService::AddressNotFoundError => e
    render_error(e.message)
  rescue WeatherForecastService::FetchError
    render_error("Unable to retrieve forecast data right now. Please try again in a moment.")
  end

  private

  def forecast_params
    params.permit(:address, :authenticity_token)
  end

  # Renders the error view with contextual icon and message.
  def render_error(message)
    @error_message = message
    render :error, status: :unprocessable_content
  end
end
