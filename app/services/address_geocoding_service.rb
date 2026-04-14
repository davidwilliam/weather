# Resolves a free-form address string into geographic coordinates and a postal
# (zip) code. The zip code is the cache key for downstream forecast lookups.
#
# Uses the Geocoder gem, which is configured in config/initializers/geocoder.rb.
#
# == Usage
#
#   result = AddressGeocodingService.call("1600 Pennsylvania Ave, Washington, DC")
#   result.zip_code   # => "20500"
#   result.latitude   # => 38.8977
#   result.longitude  # => -77.0365
#
class AddressGeocodingService
  # Value object returned on successful geocoding.
  Result = Struct.new(:zip_code, :latitude, :longitude, :city, keyword_init: true)

  # Raised when the address cannot be resolved to a location.
  class AddressNotFoundError < StandardError; end

  # Entry point following the Rails service-object convention.
  def self.call(address)
    new(address).call
  end

  def initialize(address)
    @address = address.to_s.strip
  end

  # Geocodes the address and returns a Result with zip code and coordinates.
  #
  # Raises AddressNotFoundError if no results are found or the result lacks a
  # postal code (which is required for cache-keyed forecast lookups).
  def call
    validate_input!

    location = Geocoder.search(@address).first

    raise AddressNotFoundError, "Could not find a location for '#{@address}'" if location.nil?

    zip_code = extract_zip_code(location)

    raise AddressNotFoundError, "No zip code found for '#{@address}'. Please include a zip code or a more specific address." if zip_code.blank?

    Result.new(
      zip_code: zip_code,
      latitude: location.latitude,
      longitude: location.longitude,
      city: extract_city(location)
    )
  end

  private

  def validate_input!
    raise AddressNotFoundError, "Address cannot be blank" if @address.blank?
  end

  # Extracts the postal/zip code from a Geocoder result object.
  # Different lookup providers store this in different attributes.
  def extract_zip_code(location)
    location.postal_code.presence || location.data.dig("address", "postcode").presence
  end

  # Extracts the city/locality name for display purposes.
  def extract_city(location)
    location.city.presence ||
      location.data.dig("address", "city").presence ||
      location.data.dig("address", "town").presence ||
      location.data.dig("address", "county").presence
  end
end
