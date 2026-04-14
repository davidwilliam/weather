require "rails_helper"

RSpec.describe WeatherForecastService do
  describe ".call" do
    context "with a successful API response" do
      before { stub_open_meteo_success }

      it "returns a Forecast with current temperature" do
        forecast = described_class.call(latitude: 38.89, longitude: -77.03)

        expect(forecast.current_temperature).to eq(72.5)
      end

      it "returns today's high and low temperatures" do
        forecast = described_class.call(latitude: 38.89, longitude: -77.03)

        expect(forecast.current_high).to eq(78.0)
        expect(forecast.current_low).to eq(62.0)
      end

      it "returns 7 days of extended forecast data" do
        forecast = described_class.call(latitude: 38.89, longitude: -77.03)

        expect(forecast.daily_forecasts.length).to eq(7)
      end

      it "maps weather codes to human-readable descriptions" do
        forecast = described_class.call(latitude: 38.89, longitude: -77.03)

        descriptions = forecast.daily_forecasts.map(&:weather_description)
        expect(descriptions.first).to eq("Clear sky")
        expect(descriptions[3]).to eq("Slight rain")
      end

      it "parses dates correctly in daily forecasts" do
        forecast = described_class.call(latitude: 38.89, longitude: -77.03)

        expect(forecast.daily_forecasts.first.date).to eq(Date.new(2026, 4, 13))
      end
    end

    context "when the API returns an error status" do
      before { stub_open_meteo_failure }

      it "raises a FetchError" do
        expect {
          described_class.call(latitude: 38.89, longitude: -77.03)
        }.to raise_error(WeatherForecastService::FetchError, /status 500/)
      end
    end

    context "when the API is unreachable" do
      before do
        stub_request(:get, /api\.open-meteo\.com\/v1\/forecast/)
          .to_raise(Faraday::ConnectionFailed.new("connection refused"))
      end

      it "raises a FetchError with a descriptive message" do
        expect {
          described_class.call(latitude: 38.89, longitude: -77.03)
        }.to raise_error(WeatherForecastService::FetchError, /request failed/)
      end
    end
  end
end
