# Geocoder configuration for address-to-coordinates resolution.
# Uses the free Nominatim (OpenStreetMap) lookup by default.
# For production, consider a commercial provider with higher rate limits.
#
# Nominatim requires a valid, identifiable User-Agent header. Requests with
# generic or placeholder emails (e.g. dev@example.com) are rejected with 403.
Geocoder.configure(
  lookup: :nominatim,
  http_headers: { "User-Agent" => "ForecastApp/1.0 (contact@forecast-app.dev)" },
  units: :mi,
  cache: Rails.cache,
  cache_options: { expiration: 1.day }
)
