# Orchestrates the full forecast lookup workflow: geocoding an address, checking
# the cache by zip code, and fetching fresh data from the weather API when needed.
#
# This is the primary entry point called by the ForecastsController. It
# coordinates the AddressGeocodingService and WeatherForecastService while
# managing the 30-minute cache keyed by zip code.
#
# == Usage
#
#   result = ForecastLookupService.call("1600 Pennsylvania Ave, Washington, DC")
#   result.forecast         # => WeatherForecastService::Forecast
#   result.zip_code         # => "20500"
#   result.cached?          # => true/false
#
class ForecastLookupService
  CACHE_DURATION = 30.minutes
  CACHE_KEY_PREFIX = "forecast/zip"

  # Value object returned to the controller with forecast data and cache status.
  Result = Struct.new(:forecast, :zip_code, :city, :cached, keyword_init: true) do
    alias_method :cached?, :cached
  end

  def self.call(address)
    new(address).call
  end

  def initialize(address)
    @address = address
  end

  # Resolves the address, then returns cached or fresh forecast data.
  def call
    geocoding = AddressGeocodingService.call(@address)
    cache_key = build_cache_key(geocoding.zip_code)

    cached = Rails.cache.exist?(cache_key)

    forecast = Rails.cache.fetch(cache_key, expires_in: CACHE_DURATION) do
      WeatherForecastService.call(
        latitude: geocoding.latitude,
        longitude: geocoding.longitude
      )
    end

    Result.new(
      forecast: forecast,
      zip_code: geocoding.zip_code,
      city: geocoding.city,
      cached: cached
    )
  end

  private

  # Builds a namespaced cache key from the zip code.
  # Example: "forecast/zip/20500"
  def build_cache_key(zip_code)
    "#{CACHE_KEY_PREFIX}/#{zip_code}"
  end
end
