require "../spec_helper"

describe PointClickEngine::Core::ErrorReporter do
  # Since the ErrorReporter is mainly about console output formatting,
  # we'll test that methods can be called without errors rather than
  # trying to capture and validate the exact output

  describe ".report_loading_error" do
    it "handles ConfigError" do
      error = PointClickEngine::Core::ConfigError.new("Invalid window size", "game.yaml", "window.width")
      # Should not raise
      PointClickEngine::Core::ErrorReporter.report_loading_error(error, "Loading configuration")
    end

    it "handles AssetError" do
      error = PointClickEngine::Core::AssetError.new("File not found", "sprites/missing.png", "scene1.yaml")
      # Should not raise
      PointClickEngine::Core::ErrorReporter.report_loading_error(error)
    end

    it "handles SceneError" do
      error = PointClickEngine::Core::SceneError.new("Invalid hotspot definition", "intro_scene", "hotspots[0]")
      # Should not raise
      PointClickEngine::Core::ErrorReporter.report_loading_error(error)
    end

    it "handles ValidationError" do
      errors = ["Error 1", "Error 2", "Error 3"]
      error = PointClickEngine::Core::ValidationError.new(errors, "config.yaml")
      # Should not raise
      PointClickEngine::Core::ErrorReporter.report_loading_error(error)
    end

    it "handles generic exceptions" do
      error = Exception.new("Something went wrong")
      # Should not raise
      PointClickEngine::Core::ErrorReporter.report_loading_error(error)
    end
  end

  describe ".report_warning" do
    it "reports warnings with context" do
      # Should not raise
      PointClickEngine::Core::ErrorReporter.report_warning("Asset file is very large", "Loading assets")
    end

    it "reports warnings without context" do
      # Should not raise
      PointClickEngine::Core::ErrorReporter.report_warning("No start scene specified")
    end
  end

  describe ".report_info" do
    it "reports info messages" do
      # Should not raise
      PointClickEngine::Core::ErrorReporter.report_info("Loading game configuration...")
    end
  end

  describe ".report_success" do
    it "reports success messages" do
      # Should not raise
      PointClickEngine::Core::ErrorReporter.report_success("All assets loaded successfully")
    end
  end

  describe ".report_progress" do
    it "reports progress with success" do
      # Should not raise
      PointClickEngine::Core::ErrorReporter.report_progress("Loading scene 'intro'")
      PointClickEngine::Core::ErrorReporter.report_progress_done(true)
    end

    it "reports progress with failure" do
      # Should not raise
      PointClickEngine::Core::ErrorReporter.report_progress("Loading corrupted file")
      PointClickEngine::Core::ErrorReporter.report_progress_done(false)
    end
  end

  describe ".format_list" do
    it "formats a list of items" do
      items = ["Item 1", "Item 2", "Item 3"]
      # Should not raise
      PointClickEngine::Core::ErrorReporter.format_list("Found issues", items)
    end
  end

  describe ".separator" do
    it "creates separators" do
      # Should not raise
      PointClickEngine::Core::ErrorReporter.separator("=", 10)
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
      # Should not raise
      PointClickEngine::Core::ErrorReporter.report_multiple_errors(errors, "Validation Failed")
    end
  end
end
