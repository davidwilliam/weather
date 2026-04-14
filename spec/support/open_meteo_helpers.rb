# Shared test helpers for stubbing the Open-Meteo weather API responses.
module OpenMeteoHelpers
  # Returns a realistic Open-Meteo API response body as a Hash.
  def sample_open_meteo_response
    {
      "current" => {
        "temperature_2m" => 72.5
      },
      "daily" => {
        "time" => %w[2026-04-13 2026-04-14 2026-04-15 2026-04-16 2026-04-17 2026-04-18 2026-04-19],
        "temperature_2m_max" => [78.0, 80.0, 75.0, 73.0, 77.0, 82.0, 79.0],
        "temperature_2m_min" => [62.0, 64.0, 58.0, 55.0, 60.0, 65.0, 63.0],
        "weather_code"       => [0, 1, 2, 61, 3, 0, 80]
      }
    }
  end

  # Stubs the Open-Meteo API to return a successful forecast response.
  def stub_open_meteo_success(latitude: 38.89, longitude: -77.03)
    stub_request(:get, "https://api.open-meteo.com/v1/forecast")
      .with(query: hash_including("latitude" => latitude.to_s, "longitude" => longitude.to_s))
      .to_return(
        status: 200,
        body: sample_open_meteo_response.to_json,
        headers: { "Content-Type" => "application/json" }
      )
  end

  # Stubs the Open-Meteo API to return an error.
  def stub_open_meteo_failure
    stub_request(:get, /api\.open-meteo\.com\/v1\/forecast/)
      .to_return(status: 500, body: "Internal Server Error")
  end
end

RSpec.configure do |config|
  config.include OpenMeteoHelpers
end
