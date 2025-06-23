require "../spec_helper"
require "colorize"

# Helper to capture console output
def capture_output(&block)
  output = IO::Memory.new
  original_stdout = STDOUT.dup
  
  begin
    # Redirect STDOUT to our memory buffer
    STDOUT.reopen(IO::MultiWriter.new(output))
    yield
    output.rewind
    output.gets_to_end
  rescue ex
    # Make sure we restore STDOUT even if an error occurs
    STDOUT.reopen(original_stdout)
    raise ex
  ensure
    STDOUT.reopen(original_stdout)
  end
end

describe PointClickEngine::Core::ErrorReporter do

  describe ".report_loading_error" do
    it "reports a ConfigError" do
      error = PointClickEngine::Core::ConfigError.new("Invalid window size", "game.yaml", "window.width")
      
      output = capture_output do
        PointClickEngine::Core::ErrorReporter.report_loading_error(error, "Loading configuration")
      end
      
      output.should contain("LOADING ERROR")
      output.should contain("Context: Loading configuration")
      output.should contain("Type: Configuration Error")
      output.should contain("File: game.yaml")
      output.should contain("Field: window.width")
      output.should contain("Error: Configuration Error: Invalid window size")
    end

    it "reports an AssetError" do
      error = PointClickEngine::Core::AssetError.new("File not found", "sprites/missing.png", "scene1.yaml")
      
      output = capture_output do
        PointClickEngine::Core::ErrorReporter.report_loading_error(error)
      end
      
      output.should contain("Type: Asset Loading Error")
      output.should contain("Asset: sprites/missing.png")
      output.should contain("Referenced in: scene1.yaml")
    end

    it "reports a SceneError" do
      error = PointClickEngine::Core::SceneError.new("Invalid hotspot definition", "intro_scene", "hotspots[0]")
      
      output = capture_output do
        PointClickEngine::Core::ErrorReporter.report_loading_error(error)
      end
      
      output.should contain("Type: Scene Loading Error")
      output.should contain("Scene: intro_scene")
      output.should contain("Field: hotspots[0]")
    end

    it "reports a ValidationError" do
      errors = ["Error 1", "Error 2", "Error 3"]
      error = PointClickEngine::Core::ValidationError.new(errors, "config.yaml")
      
      output = capture_output do
        PointClickEngine::Core::ErrorReporter.report_loading_error(error)
      end
      
      output.should contain("Type: Validation Error")
      output.should contain("File: config.yaml")
      output.should contain("Validation failed with 3 error(s):")
      output.should contain("1. Error 1")
      output.should contain("2. Error 2")
      output.should contain("3. Error 3")
    end

    it "reports generic exceptions" do
      error = Exception.new("Something went wrong")
      
      output = capture_output do
        PointClickEngine::Core::ErrorReporter.report_loading_error(error)
      end
      
      output.should contain("Type: Exception")
      output.should contain("Error: Something went wrong")
    end

    it "includes stack trace tip when DEBUG not set" do
      error = Exception.new("Test error")
      
      ENV.delete("DEBUG") # Ensure DEBUG is not set
      
      output = capture_output do
        PointClickEngine::Core::ErrorReporter.report_loading_error(error)
      end
      
      output.should contain("Tip: Set DEBUG=1 environment variable to see stack trace")
    end
  end

  describe ".report_warning" do
    it "reports a warning message" do
      output = capture_output do
        PointClickEngine::Core::ErrorReporter.report_warning("Asset file is very large", "Loading assets")
      end
      
      output.should contain("⚠️  WARNING: Asset file is very large")
      output.should contain("Context: Loading assets")
    end

    it "reports warning without context" do
      output = capture_output do
        PointClickEngine::Core::ErrorReporter.report_warning("No start scene specified")
      end
      
      output.should contain("⚠️  WARNING: No start scene specified")
      output.should_not contain("Context:")
    end
  end

  describe ".report_info" do
    it "reports an info message" do
      output = capture_output do
        PointClickEngine::Core::ErrorReporter.report_info("Loading game configuration...")
      end
      
      output.should contain("ℹ️  Loading game configuration...")
    end
  end

  describe ".report_success" do
    it "reports a success message" do
      output = capture_output do
        PointClickEngine::Core::ErrorReporter.report_success("All assets loaded successfully")
      end
      
      output.should contain("✅ All assets loaded successfully")
    end
  end

  describe ".report_progress" do
    it "reports progress and completion" do
      output = capture_output do
        PointClickEngine::Core::ErrorReporter.report_progress("Loading scene 'intro'")
        PointClickEngine::Core::ErrorReporter.report_progress_done(true)
      end
      
      output.should contain("⏳ Loading scene 'intro'...")
      output.should contain("✓")
    end

    it "reports progress and failure" do
      output = capture_output do
        PointClickEngine::Core::ErrorReporter.report_progress("Loading corrupted file")
        PointClickEngine::Core::ErrorReporter.report_progress_done(false)
      end
      
      output.should contain("⏳ Loading corrupted file...")
      output.should contain("✗")
    end
  end

  describe ".format_list" do
    it "formats a list of items" do
      items = ["Item 1", "Item 2", "Item 3"]
      
      output = capture_output do
        PointClickEngine::Core::ErrorReporter.format_list("Found issues", items)
      end
      
      output.should contain("Found issues:")
      output.should contain("  • Item 1")
      output.should contain("  • Item 2")
      output.should contain("  • Item 3")
    end
  end

  describe ".separator" do
    it "creates a separator line" do
      output = capture_output do
        PointClickEngine::Core::ErrorReporter.separator("=", 10)
      end
      
      output.strip.should eq("==========")
    end

    it "uses default parameters" do
      output = capture_output do
        PointClickEngine::Core::ErrorReporter.separator
      end
      
      output.strip.should eq("=" * 60)
    end
  end

  describe ".report_multiple_errors" do
    it "reports multiple errors" do
      errors = [
        PointClickEngine::Core::ConfigError.new("Invalid value", "config.yaml"),
        PointClickEngine::Core::AssetError.new("Not found", "sprite.png"),
        Exception.new("Generic error")
      ]
      
      output = capture_output do
        PointClickEngine::Core::ErrorReporter.report_multiple_errors(errors, "Validation Failed")
      end
      
      output.should contain("❌ Validation Failed")
      output.should contain("Error 1:")
      output.should contain("File: config.yaml")
      output.should contain("Message: Configuration Error: Invalid value")
      output.should contain("Error 2:")
      output.should contain("Message: Asset Error: Not found (asset: sprite.png)")
      output.should contain("Error 3:")
      output.should contain("Generic error")
    end
  end
end