require "../spec_helper"
require "colorize"

describe PointClickEngine::Core::ErrorReporter do
  describe ".report_loading_error" do
    it "reports a ConfigError" do
      error = PointClickEngine::Core::ConfigError.new("Invalid window size", "game.yaml", "window.width")

      # Just verify it doesn't crash - we can't easily capture output in Crystal tests
      PointClickEngine::Core::ErrorReporter.report_loading_error(error, "Loading configuration")
    end

    it "reports an AssetError" do
      error = PointClickEngine::Core::AssetError.new("File not found", "sprites/missing.png", "scene1.yaml")

      # Just verify it doesn't crash
      PointClickEngine::Core::ErrorReporter.report_loading_error(error)
    end

    it "reports a SceneError" do
      error = PointClickEngine::Core::SceneError.new("Invalid hotspot definition", "intro_scene", "hotspots[0]")

      # Just verify it doesn't crash
      PointClickEngine::Core::ErrorReporter.report_loading_error(error)
    end

    it "reports a ValidationError" do
      errors = ["Error 1", "Error 2", "Error 3"]
      error = PointClickEngine::Core::ValidationError.new(errors, "config.yaml")

      # Just verify it doesn't crash
      PointClickEngine::Core::ErrorReporter.report_loading_error(error)
    end

    it "reports generic exceptions" do
      error = Exception.new("Something went wrong")

      # Just verify it doesn't crash
      PointClickEngine::Core::ErrorReporter.report_loading_error(error)
    end

    it "handles DEBUG environment variable" do
      error = Exception.new("Test error")

      ENV.delete("DEBUG") # Ensure DEBUG is not set

      # Just verify it doesn't crash
      PointClickEngine::Core::ErrorReporter.report_loading_error(error)
    end
  end

  describe ".report_warning" do
    it "reports a warning message" do
      # Just verify it doesn't crash
      PointClickEngine::Core::ErrorReporter.report_warning("Asset file is very large", "Loading assets")
    end

    it "reports warning without context" do
      # Just verify it doesn't crash
      PointClickEngine::Core::ErrorReporter.report_warning("No start scene specified")
    end
  end

  describe ".report_info" do
    it "reports an info message" do
      # Just verify it doesn't crash
      PointClickEngine::Core::ErrorReporter.report_info("Loading game configuration...")
    end
  end

  describe ".report_success" do
    it "reports a success message" do
      # Just verify it doesn't crash
      PointClickEngine::Core::ErrorReporter.report_success("All assets loaded successfully")
    end
  end

  describe ".report_progress" do
    it "reports progress and completion" do
      # Just verify it doesn't crash
      PointClickEngine::Core::ErrorReporter.report_progress("Loading scene 'intro'")
      PointClickEngine::Core::ErrorReporter.report_progress_done(true)
    end

    it "reports progress and failure" do
      # Just verify it doesn't crash
      PointClickEngine::Core::ErrorReporter.report_progress("Loading corrupted file")
      PointClickEngine::Core::ErrorReporter.report_progress_done(false)
    end
  end

  describe ".format_list" do
    it "formats a list of items" do
      items = ["Item 1", "Item 2", "Item 3"]

      # Just verify it doesn't crash
      PointClickEngine::Core::ErrorReporter.format_list("Found issues", items)
    end
  end

  describe ".separator" do
    it "creates a separator line" do
      # Just verify it doesn't crash
      PointClickEngine::Core::ErrorReporter.separator("=", 10)
    end

    it "uses default parameters" do
      # Just verify it doesn't crash
      PointClickEngine::Core::ErrorReporter.separator
    end
  end

  describe ".report_multiple_errors" do
    it "reports multiple errors" do
      errors = [
        PointClickEngine::Core::ConfigError.new("Invalid value", "config.yaml"),
        PointClickEngine::Core::AssetError.new("Not found", "sprite.png"),
        Exception.new("Generic error"),
      ]

      # Just verify it doesn't crash
      PointClickEngine::Core::ErrorReporter.report_multiple_errors(errors, "Validation Failed")
    end
  end
end
