require "rails_helper"

RSpec.describe ForecastsHelper do
  describe "#weather_icon" do
    it "returns an <i> tag with the correct Bootstrap Icon class" do
      result = helper.weather_icon("Clear sky")

      expect(result).to include("bi-sun-fill")
      expect(result).to include('title="Clear sky"')
    end

    it "falls back to a question-circle icon for unknown descriptions" do
      result = helper.weather_icon("Alien weather")

      expect(result).to include("bi-question-circle")
    end

    it "appends an extra CSS class when provided" do
      result = helper.weather_icon("Clear sky", extra_class: "text-warning")

      expect(result).to include("text-warning")
    end
  end

  describe "#format_temperature" do
    it "rounds to the nearest integer and appends the degree symbol" do
      expect(helper.format_temperature(72.5)).to eq("73&deg;")
    end

    it "handles whole numbers" do
      expect(helper.format_temperature(60.0)).to eq("60&deg;")
    end

    it "returns an html_safe string" do
      expect(helper.format_temperature(70)).to be_html_safe
    end
  end

  describe "#weather_theme_class" do
    it "returns the correct theme for clear sky" do
      expect(helper.weather_theme_class("Clear sky")).to eq("theme-clear")
    end

    it "returns theme-rain for rain-related descriptions" do
      expect(helper.weather_theme_class("Moderate rain")).to eq("theme-rain")
      expect(helper.weather_theme_class("Light drizzle")).to eq("theme-rain")
      expect(helper.weather_theme_class("Slight rain showers")).to eq("theme-rain")
    end

    it "returns theme-snow for snow-related descriptions" do
      expect(helper.weather_theme_class("Heavy snowfall")).to eq("theme-snow")
    end

    it "returns theme-storm for thunderstorm descriptions" do
      expect(helper.weather_theme_class("Thunderstorm")).to eq("theme-storm")
    end

    it "falls back to theme-overcast for unrecognized descriptions" do
      expect(helper.weather_theme_class("Alien weather")).to eq("theme-overcast")
    end
  end

  describe "#temperature_bar_position" do
    it "returns 0 for the minimum temperature" do
      expect(helper.temperature_bar_position(50, 50, 100)).to eq(0.0)
    end

    it "returns 100 for the maximum temperature" do
      expect(helper.temperature_bar_position(100, 50, 100)).to eq(100.0)
    end

    it "returns 50 for the midpoint" do
      expect(helper.temperature_bar_position(75, 50, 100)).to eq(50.0)
    end

    it "returns 0 when min and max are equal" do
      expect(helper.temperature_bar_position(50, 50, 50)).to eq(0)
    end
  end
end
