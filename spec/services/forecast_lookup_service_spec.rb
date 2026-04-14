require "rails_helper"

RSpec.describe ForecastLookupService do
  let(:geocoding_result) do
    AddressGeocodingService::Result.new(
      zip_code: "20500",
      latitude: 38.89,
      longitude: -77.03,
      city: "Washington"
    )
  end

  before do
    allow(AddressGeocodingService).to receive(:call).and_return(geocoding_result)
    stub_open_meteo_success
  end

  describe ".call" do
    it "returns a result with forecast data" do
      result = described_class.call("1600 Pennsylvania Ave, Washington, DC")

      expect(result.forecast).to be_a(WeatherForecastService::Forecast)
      expect(result.forecast.current_temperature).to eq(72.5)
    end

    it "includes the resolved zip code" do
      result = described_class.call("1600 Pennsylvania Ave, Washington, DC")

      expect(result.zip_code).to eq("20500")
    end

    it "reports cached as false on the first request" do
      result = described_class.call("1600 Pennsylvania Ave, Washington, DC")

      expect(result.cached?).to be false
    end

    it "reports cached as true on subsequent requests for the same zip code" do
      described_class.call("1600 Pennsylvania Ave, Washington, DC")
      result = described_class.call("1600 Pennsylvania Ave, Washington, DC")

      expect(result.cached?).to be true
    end

    it "does not call the weather API when the result is cached" do
      described_class.call("1600 Pennsylvania Ave, Washington, DC")

      # Reset WebMock to verify no new API calls are made
      WebMock.reset!
      allow(AddressGeocodingService).to receive(:call).and_return(geocoding_result)

      result = described_class.call("1600 Pennsylvania Ave, Washington, DC")
      expect(result.cached?).to be true
    end

    it "caches by zip code, not by address string" do
      described_class.call("1600 Pennsylvania Ave, Washington, DC")

      # Different address text, same zip code: should be cached
      result = described_class.call("White House, Washington, DC")
      expect(result.cached?).to be true
    end
  end
end
