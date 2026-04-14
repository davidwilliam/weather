require "rails_helper"

RSpec.describe AddressGeocodingService do
  describe ".call" do
    context "with a valid address that resolves to a location with a zip code" do
      before do
        result = double(
          "Geocoder::Result",
          latitude: 38.8977,
          longitude: -77.0365,
          postal_code: "20500",
          city: "Washington",
          data: {}
        )
        allow(Geocoder).to receive(:search).and_return([result])
      end

      it "returns a Result with zip code, coordinates, and city" do
        result = described_class.call("1600 Pennsylvania Ave, Washington, DC")

        expect(result.zip_code).to eq("20500")
        expect(result.latitude).to eq(38.8977)
        expect(result.longitude).to eq(-77.0365)
        expect(result.city).to eq("Washington")
      end
    end

    context "with a valid address resolved via data hash fallback" do
      before do
        result = double(
          "Geocoder::Result",
          latitude: 40.7128,
          longitude: -74.0060,
          postal_code: nil,
          city: "New York",
          data: { "address" => { "postcode" => "10007" } }
        )
        allow(Geocoder).to receive(:search).and_return([result])
      end

      it "extracts the zip code from the data hash" do
        result = described_class.call("New York, NY")

        expect(result.zip_code).to eq("10007")
      end
    end

    context "when city is only available in the data hash" do
      before do
        result = double(
          "Geocoder::Result",
          latitude: 40.7128,
          longitude: -74.0060,
          postal_code: "10007",
          city: nil,
          data: { "address" => { "postcode" => "10007", "town" => "Springfield" } }
        )
        allow(Geocoder).to receive(:search).and_return([result])
      end

      it "extracts the city from the data hash town field" do
        result = described_class.call("Springfield")

        expect(result.city).to eq("Springfield")
      end
    end

    context "when the address cannot be geocoded" do
      before do
        allow(Geocoder).to receive(:search).and_return([])
      end

      it "raises AddressNotFoundError" do
        expect {
          described_class.call("Xyzzy Nonexistent Place")
        }.to raise_error(
          AddressGeocodingService::AddressNotFoundError,
          /Could not find a location/
        )
      end
    end

    context "when the geocoded result has no zip code" do
      before do
        result = double(
          "Geocoder::Result",
          latitude: 0.0,
          longitude: 0.0,
          postal_code: nil,
          city: nil,
          data: {}
        )
        allow(Geocoder).to receive(:search).and_return([result])
      end

      it "raises AddressNotFoundError mentioning the missing zip code" do
        expect {
          described_class.call("Middle of the Ocean")
        }.to raise_error(
          AddressGeocodingService::AddressNotFoundError,
          /No zip code found/
        )
      end
    end

    context "with a blank address" do
      it "raises AddressNotFoundError" do
        expect {
          described_class.call("   ")
        }.to raise_error(
          AddressGeocodingService::AddressNotFoundError,
          /Address cannot be blank/
        )
      end
    end
  end
end
