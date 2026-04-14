# View helpers for forecast display: weather icons, formatting, and theming.
module ForecastsHelper
  # Maps a weather description to a Bootstrap Icon class for visual display.
  WEATHER_ICONS = {
    "Clear sky"              => "bi-sun-fill",
    "Mainly clear"           => "bi-sun-fill",
    "Partly cloudy"          => "bi-cloud-sun-fill",
    "Overcast"               => "bi-clouds-fill",
    "Foggy"                  => "bi-cloud-fog-fill",
    "Depositing rime fog"    => "bi-cloud-fog2-fill",
    "Light drizzle"          => "bi-cloud-drizzle-fill",
    "Moderate drizzle"       => "bi-cloud-drizzle-fill",
    "Dense drizzle"          => "bi-cloud-drizzle-fill",
    "Light freezing drizzle" => "bi-cloud-sleet-fill",
    "Dense freezing drizzle" => "bi-cloud-sleet-fill",
    "Slight rain"            => "bi-cloud-rain-fill",
    "Moderate rain"          => "bi-cloud-rain-fill",
    "Heavy rain"             => "bi-cloud-rain-heavy-fill",
    "Light freezing rain"    => "bi-cloud-sleet-fill",
    "Heavy freezing rain"    => "bi-cloud-sleet-fill",
    "Slight snowfall"        => "bi-cloud-snow-fill",
    "Moderate snowfall"      => "bi-cloud-snow-fill",
    "Heavy snowfall"         => "bi-cloud-snow-fill",
    "Snow grains"            => "bi-cloud-snow-fill",
    "Slight rain showers"    => "bi-cloud-rain-fill",
    "Moderate rain showers"  => "bi-cloud-rain-fill",
    "Violent rain showers"   => "bi-cloud-rain-heavy-fill",
    "Slight snow showers"    => "bi-cloud-snow-fill",
    "Heavy snow showers"     => "bi-cloud-snow-fill",
    "Thunderstorm"           => "bi-cloud-lightning-fill",
    "Thunderstorm with slight hail" => "bi-cloud-lightning-rain-fill",
    "Thunderstorm with heavy hail"  => "bi-cloud-lightning-rain-fill"
  }.freeze

  # Maps weather descriptions to background gradient CSS classes.
  # Inspired by Apple Weather's dynamic backgrounds.
  WEATHER_THEMES = {
    "Clear sky"     => "theme-clear",
    "Mainly clear"  => "theme-clear",
    "Partly cloudy" => "theme-partly-cloudy",
    "Overcast"      => "theme-overcast",
    "Foggy"         => "theme-fog",
    "Depositing rime fog" => "theme-fog"
  }.freeze

  # Returns a Bootstrap Icon <i> tag for the given weather description.
  def weather_icon(description, extra_class: nil)
    icon_class = WEATHER_ICONS.fetch(description, "bi-question-circle")
    css = ["bi", icon_class, extra_class].compact.join(" ")
    tag.i(class: css, title: description, aria: { label: description })
  end

  # Formats a temperature value for display with degree symbol.
  def format_temperature(value)
    "#{value.round}&deg;".html_safe
  end

  # Returns the CSS class for the weather-condition-based background theme.
  def weather_theme_class(description)
    return "theme-rain"  if description.match?(/rain|drizzle|shower/i)
    return "theme-snow"  if description.match?(/snow|sleet|hail/i)
    return "theme-storm" if description.match?(/thunder/i)

    WEATHER_THEMES.fetch(description, "theme-overcast")
  end

  # Computes the position (0-100%) of a temperature within a global min/max
  # range across all 7 days. Used to render Apple-style temperature bars.
  def temperature_bar_position(temp, global_min, global_max)
    range = global_max - global_min
    return 0 if range.zero?

    ((temp - global_min).to_f / range * 100).round(1)
  end
end
