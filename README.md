# Weather Forecast Application

A Ruby on Rails application that accepts an address, retrieves weather forecast data, and displays current conditions along with a 7-day extended forecast. Results are cached for 30 minutes by zip code.

**Live demo:** https://weather-forecast-showcase-7487a9a8afb5.herokuapp.com/

## Requirements

- Ruby 3.3+
- Rails 8.0
- Node.js / Yarn (for CSS asset compilation via Bootstrap)

## Setup

```bash
bundle install
yarn install
```

No database is required. This application uses no ActiveRecord.

## Running the Application

```bash
bin/rails server
```

Visit `http://localhost:3000` and enter an address to look up the forecast.

## Running Tests

```bash
bundle exec rspec
```

## Architecture & Object Decomposition

The application follows a service-oriented architecture with clear separation of concerns. Each class has a single responsibility and communicates through well-defined interfaces.

```
Request Flow:

  User enters address
        |
        v
  ForecastsController
        |
        v
  ForecastLookupService  (orchestrator)
        |
        +---> AddressGeocodingService  (address -> zip code + coordinates)
        |           |
        |           +---> Geocoder gem (Nominatim / OpenStreetMap)
        |
        +---> Rails.cache (check/store by zip code, 30-min TTL)
        |
        +---> WeatherForecastService   (coordinates -> forecast data)
                    |
                    +---> Open-Meteo API (free, no key required)
        |
        v
  View
    create.html.erb  (forecast results with cache indicator)
    error.html.erb   (error page with retry form)
```

### Key Classes

| Class | Responsibility |
|---|---|
| `ForecastsController` | Handles HTTP requests. Renders the search form (`new`), forecast results (`create`), and error page. Delegates all business logic to services. |
| `ForecastLookupService` | Orchestrates the full workflow: geocoding, cache lookup, and weather fetching. Returns a `Result` struct with forecast data, zip code, city, and cache-hit flag. |
| `AddressGeocodingService` | Resolves a free-form address string into a zip code, lat/lon coordinates, and city name using the Geocoder gem. Raises `AddressNotFoundError` on failure. |
| `WeatherForecastService` | Fetches current conditions and a 7-day extended forecast from the Open-Meteo API. Converts WMO weather codes to human-readable descriptions. Raises `FetchError` on failure. |
| `ForecastsHelper` | View helpers for weather icons, temperature formatting, dynamic background theming, and temperature bar positioning. |

### Value Objects (Structs)

| Struct | Fields | Purpose |
|---|---|---|
| `AddressGeocodingService::Result` | `zip_code`, `latitude`, `longitude`, `city` | Geocoding output passed to downstream services |
| `WeatherForecastService::Forecast` | `current_temperature`, `current_high`, `current_low`, `daily_forecasts` | Complete forecast response |
| `WeatherForecastService::DayForecast` | `date`, `high_temperature`, `low_temperature`, `weather_description` | Single day within the extended forecast |
| `ForecastLookupService::Result` | `forecast`, `zip_code`, `city`, `cached` | Final result delivered to the controller |

### Views

| View | Purpose |
|---|---|
| `forecasts/new.html.erb` | Landing page with search form |
| `forecasts/create.html.erb` | Forecast results with current conditions, 7-day forecast, and cache indicator |
| `forecasts/error.html.erb` | Dedicated error page with message and retry form |
| `forecasts/_form_loading.html.erb` | Shared partial for submit button loading state (spinner + disable) |

## Design Decisions

### Service Object Pattern
Business logic lives in service objects (`app/services/`) rather than in controllers or models. Each service follows the `.call` convention, accepts explicit dependencies, and returns value objects. This makes them easy to test in isolation and compose together.

### Caching Strategy
- Forecasts are cached using `Rails.cache.fetch` with a 30-minute TTL.
- Cache keys are namespaced by zip code (`forecast/zip/20500`), so any address that resolves to the same zip code shares a single cache entry.
- The `ForecastLookupService` checks `Rails.cache.exist?` before `fetch` to determine whether the result was served from cache, and passes that flag to the view for display.
- In development, caching uses the `:memory_store`. In production, this can be swapped to Redis or Memcached via `config.cache_store`.

### External APIs
- **Geocoding**: Uses the [Geocoder](https://github.com/alexreisner/geocoder) gem configured with Nominatim (OpenStreetMap). No API key required.
- **Weather**: Uses the [Open-Meteo API](https://open-meteo.com/), a free, open-source weather API with no API key required. Provides worldwide coverage with current conditions and daily forecasts.

### Error Handling
Custom exception classes (`AddressNotFoundError`, `FetchError`) bubble up from services and are rescued in the controller. Errors are rendered as a dedicated error page with a retry form rather than a redirect. The user is never shown raw API errors.

## Scalability Considerations

- **Cache backend**: Swap `:memory_store` for Redis/Memcached in production to share cache across multiple app servers.
- **Rate limiting**: Nominatim has a 1 req/sec policy. For high traffic, switch to a commercial geocoder (Google, Mapbox) via the Geocoder gem's pluggable lookup system.
- **API resilience**: Faraday is configured with connect/read timeouts. For further resilience, consider adding circuit breaker middleware (e.g., `faraday-retry`).
- **Background fetching**: For very high traffic, forecast data could be refreshed asynchronously via a background job rather than on-demand.
