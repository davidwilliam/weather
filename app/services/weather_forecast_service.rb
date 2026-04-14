# Fetches weather forecast data from the Open-Meteo API given geographic
# coordinates. Returns current conditions plus an extended 7-day forecast.
#
# Open-Meteo is free, requires no API key, and provides reliable worldwide
# coverage, making it ideal for this application.
#
# == Usage
#
#   forecast = WeatherForecastService.call(latitude: 38.89, longitude: -77.03)
#   forecast.current_temperature  # => 72.5
#   forecast.daily_forecasts      # => [DayForecast, ...]
#
class WeatherForecastService
  API_BASE_URL = "https://api.open-meteo.com/v1/forecast"

  # Raised when the external weather API returns an error or is unreachable.
  class FetchError < StandardError; end

  # Represents the full forecast response.
  Forecast = Struct.new(
    :current_temperature,
    :current_high,
    :current_low,
    :daily_forecasts,
    keyword_init: true
  )

  # Represents a single day in the extended forecast.
  DayForecast = Struct.new(
    :date,
    :high_temperature,
    :low_temperature,
    :weather_description,
    keyword_init: true
  )

  def self.call(latitude:, longitude:)
    new(latitude: latitude, longitude: longitude).call
  end

  def initialize(latitude:, longitude:)
    @latitude = latitude
    @longitude = longitude
  end

  # Fetches forecast data and returns a Forecast struct.
  def call
    response = fetch_forecast
    body = parse_response(response)
    build_forecast(body)
  end

  private

  # Performs the HTTP request to Open-Meteo with the required parameters.
  def fetch_forecast
    connection.get do |request|
      request.params = query_params
    end
  rescue Faraday::Error, Net::OpenTimeout, Net::ReadTimeout => e
    raise FetchError, "Weather API request failed: #{e.message}"
  end

  # Parses and validates the JSON response body.
  def parse_response(response)
    raise FetchError, "Weather API returned status #{response.status}" unless response.success?

    JSON.parse(response.body)
  rescue JSON::ParserError => e
    raise FetchError, "Invalid response from Weather API: #{e.message}"
  end

  # Constructs the Forecast value object from the parsed API response.
  def build_forecast(body)
    current = body.fetch("current")
    daily   = body.fetch("daily")

    Forecast.new(
      current_temperature: current["temperature_2m"],
      current_high: daily["temperature_2m_max"][0],
      current_low: daily["temperature_2m_min"][0],
      daily_forecasts: build_daily_forecasts(daily)
    )
  end

  # Maps the daily arrays from the API into an array of DayForecast structs.
  def build_daily_forecasts(daily)
    daily["time"].each_with_index.map do |date_string, index|
      DayForecast.new(
        date: Date.parse(date_string),
        high_temperature: daily["temperature_2m_max"][index],
        low_temperature: daily["temperature_2m_min"][index],
        weather_description: weather_code_to_description(daily["weather_code"][index])
      )
    end
  end

  def query_params
    {
      latitude: @latitude,
      longitude: @longitude,
      current: "temperature_2m",
      daily: "temperature_2m_max,temperature_2m_min,weather_code",
      temperature_unit: "fahrenheit",
      timezone: "auto"
    }
  end

  def connection
    @connection ||= Faraday.new(url: API_BASE_URL) do |f|
      f.request :url_encoded
      f.options.timeout = 10
      f.options.open_timeout = 5
    end
  end

  # Maps WMO weather codes to human-readable descriptions.
  # Reference: https://www.nodc.noaa.gov/archive/arc0021/0002199/1.1/data/0-data/HTML/WMO-CODE/WMO4677.HTM
  def weather_code_to_description(code)
    WMO_WEATHER_CODES.fetch(code, "Unknown")
  end

  WMO_WEATHER_CODES = {
    0  => "Clear sky",
    1  => "Mainly clear",
    2  => "Partly cloudy",
    3  => "Overcast",
    45 => "Foggy",
    48 => "Depositing rime fog",
    51 => "Light drizzle",
    53 => "Moderate drizzle",
    55 => "Dense drizzle",
    56 => "Light freezing drizzle",
    57 => "Dense freezing drizzle",
    61 => "Slight rain",
    63 => "Moderate rain",
    65 => "Heavy rain",
    66 => "Light freezing rain",
    67 => "Heavy freezing rain",
    71 => "Slight snowfall",
    73 => "Moderate snowfall",
    75 => "Heavy snowfall",
    77 => "Snow grains",
    80 => "Slight rain showers",
    81 => "Moderate rain showers",
    82 => "Violent rain showers",
    85 => "Slight snow showers",
    86 => "Heavy snow showers",
    95 => "Thunderstorm",
    96 => "Thunderstorm with slight hail",
    99 => "Thunderstorm with heavy hail"
  }.freeze
end
