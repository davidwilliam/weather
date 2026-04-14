require "rails_helper"

RSpec.describe "Forecasts", type: :request do
  let(:geocoding_result) do
    AddressGeocodingService::Result.new(
      zip_code: "20500",
      latitude: 38.89,
      longitude: -77.03,
      city: "Washington"
    )
  end

  describe "GET / (new)" do
    it "renders the search form" do
      get root_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Weather")
      expect(response.body).to include("Get Forecast")
    end
  end

  describe "POST /forecast (create)" do
    before do
      allow(AddressGeocodingService).to receive(:call).and_return(geocoding_result)
      stub_open_meteo_success
    end

    it "displays the current temperature" do
      post forecast_path, params: { address: "1600 Pennsylvania Ave, Washington, DC" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("73&deg;")
    end

    it "displays high and low temperatures" do
      post forecast_path, params: { address: "1600 Pennsylvania Ave, Washington, DC" }

      expect(response.body).to include("H:78&deg;")
      expect(response.body).to include("L:62&deg;")
    end

    it "displays the 7-day extended forecast" do
      post forecast_path, params: { address: "1600 Pennsylvania Ave, Washington, DC" }

      expect(response.body).to include("7-DAY FORECAST")
      expect(response.body).to include("Clear sky")
    end

    it "displays the city name" do
      post forecast_path, params: { address: "1600 Pennsylvania Ave, Washington, DC" }

      expect(response.body).to include("Washington")
    end

    it "displays the zip code" do
      post forecast_path, params: { address: "1600 Pennsylvania Ave, Washington, DC" }

      expect(response.body).to include("20500")
    end

    it "shows the cache indicator on subsequent requests" do
      post forecast_path, params: { address: "1600 Pennsylvania Ave, Washington, DC" }
      post forecast_path, params: { address: "1600 Pennsylvania Ave, Washington, DC" }

      expect(response.body).to include("Cached")
    end

    it "does not show the cache indicator on the first request" do
      post forecast_path, params: { address: "1600 Pennsylvania Ave, Washington, DC" }

      expect(response.body).not_to include("cache-badge")
    end

    context "with a blank address" do
      it "renders the error page with a message" do
        post forecast_path, params: { address: "" }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("Please enter an address")
        expect(response.body).to include("Location Not Found")
      end
    end

    context "when the address cannot be geocoded" do
      before do
        allow(AddressGeocodingService).to receive(:call)
          .and_raise(AddressGeocodingService::AddressNotFoundError, "Could not find a location")
      end

      it "renders the error page with the geocoding error" do
        post forecast_path, params: { address: "Xyzzy" }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("Could not find a location")
        expect(response.body).to include("Try Again")
      end
    end

    context "when the weather API fails" do
      before do
        allow(AddressGeocodingService).to receive(:call).and_return(geocoding_result)
        stub_open_meteo_failure
        Rails.cache.clear
      end

      it "renders the error page with a friendly message" do
        post forecast_path, params: { address: "1600 Pennsylvania Ave, Washington, DC" }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("Unable to retrieve forecast data")
      end
    end
  end
end
