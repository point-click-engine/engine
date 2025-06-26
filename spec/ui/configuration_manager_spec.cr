require "../spec_helper"
require "../../src/ui/configuration_manager"

describe PointClickEngine::UI::ConfigurationManager do
  describe "initialization" do
    it "initializes with default configuration" do
      manager = PointClickEngine::UI::ConfigurationManager.new
      manager.config.resolution.width.should eq(1024)
      manager.config.resolution.height.should eq(768)
      manager.config.fullscreen.should be_false
      manager.config.vsync.should be_true
      manager.config.master_volume.should eq(1.0)
      manager.config.music_volume.should eq(0.8_f32)
      manager.config.text_speed.should eq(1.0)
      manager.config.difficulty.should eq("normal")
      manager.config.language.should eq("en")
    end

    it "sets up available options" do
      manager = PointClickEngine::UI::ConfigurationManager.new
      manager.available_resolutions.should_not be_empty
      manager.available_languages.should contain("en")
      manager.available_languages.should contain("es")
      manager.available_difficulties.should contain("easy")
      manager.available_difficulties.should contain("normal")
      manager.available_difficulties.should contain("hard")
    end

    it "starts with no unsaved changes" do
      manager = PointClickEngine::UI::ConfigurationManager.new
      manager.has_unsaved_changes.should be_false
    end
  end

  describe "resolution management" do
    it "sets resolution and marks changes" do
      manager = PointClickEngine::UI::ConfigurationManager.new
      new_resolution = PointClickEngine::UI::ConfigurationManager::Resolution.new(1920, 1080)
      manager.set_resolution(new_resolution)

      manager.config.resolution.width.should eq(1920)
      manager.config.resolution.height.should eq(1080)
      manager.has_unsaved_changes.should be_true
    end

    it "doesn't mark changes for same resolution" do
      manager = PointClickEngine::UI::ConfigurationManager.new
      original_resolution = manager.config.resolution
      manager.has_unsaved_changes = false

      manager.set_resolution(original_resolution)
      manager.has_unsaved_changes.should be_false
    end

    it "sets resolution by index" do
      manager = PointClickEngine::UI::ConfigurationManager.new
      manager.set_resolution_by_index(1) # Should be 1024x768

      manager.config.resolution.width.should eq(1024)
      manager.config.resolution.height.should eq(768)
    end

    it "ignores invalid resolution index" do
      manager = PointClickEngine::UI::ConfigurationManager.new
      original_resolution = manager.config.resolution
      manager.set_resolution_by_index(100) # Invalid index

      manager.config.resolution.should eq(original_resolution)
    end

    it "gets current resolution index" do
      manager = PointClickEngine::UI::ConfigurationManager.new
      # Set to known resolution
      target_resolution = manager.available_resolutions[2]
      manager.set_resolution(target_resolution)

      index = manager.get_resolution_index
      index.should eq(2)
    end
  end

  describe "display settings" do
    it "sets fullscreen mode" do
      manager = PointClickEngine::UI::ConfigurationManager.new
      manager.set_fullscreen(true)

      manager.config.fullscreen.should be_true
      manager.has_unsaved_changes.should be_true
    end

    it "sets vsync setting" do
      manager = PointClickEngine::UI::ConfigurationManager.new
      manager.set_vsync(false)

      manager.config.vsync.should be_false
      manager.has_unsaved_changes.should be_true
    end

    it "doesn't mark changes for same values" do
      manager = PointClickEngine::UI::ConfigurationManager.new
      manager.has_unsaved_changes = false
      manager.set_fullscreen(false) # Already false

      manager.has_unsaved_changes.should be_false
    end
  end

  describe "audio settings" do
    it "sets master volume with clamping" do
      manager = PointClickEngine::UI::ConfigurationManager.new
      manager.set_master_volume(1.5) # Above max
      manager.config.master_volume.should eq(1.0)

      manager.set_master_volume(-0.5) # Below min
      manager.config.master_volume.should eq(0.0)

      manager.set_master_volume(0.7) # Valid value
      manager.config.master_volume.should eq(0.7_f32)
      manager.has_unsaved_changes.should be_true
    end

    it "sets music volume with validation" do
      manager = PointClickEngine::UI::ConfigurationManager.new
      manager.set_music_volume(0.5)

      manager.config.music_volume.should eq(0.5)
      manager.has_unsaved_changes.should be_true
    end

    it "sets sfx volume with validation" do
      manager = PointClickEngine::UI::ConfigurationManager.new
      manager.set_sfx_volume(0.9)

      manager.config.sfx_volume.should eq(0.9_f32)
      manager.has_unsaved_changes.should be_true
    end

    it "sets voice volume with validation" do
      manager = PointClickEngine::UI::ConfigurationManager.new
      manager.set_voice_volume(0.6)

      manager.config.voice_volume.should eq(0.6_f32)
      manager.has_unsaved_changes.should be_true
    end

    it "doesn't mark changes for same volume values" do
      manager = PointClickEngine::UI::ConfigurationManager.new
      manager.has_unsaved_changes = false
      original_volume = manager.config.master_volume

      manager.set_master_volume(original_volume)
      manager.has_unsaved_changes.should be_false
    end
  end

  describe "gameplay settings" do
    it "sets text speed with clamping" do
      manager = PointClickEngine::UI::ConfigurationManager.new
      manager.set_text_speed(5.0) # Above max
      manager.config.text_speed.should eq(3.0)

      manager.set_text_speed(0.05) # Below min
      manager.config.text_speed.should eq(0.1_f32)

      manager.set_text_speed(1.5) # Valid value
      manager.config.text_speed.should eq(1.5)
      manager.has_unsaved_changes.should be_true
    end

    it "sets auto save setting" do
      manager = PointClickEngine::UI::ConfigurationManager.new
      manager.set_auto_save(false)

      manager.config.auto_save.should be_false
      manager.has_unsaved_changes.should be_true
    end

    it "sets difficulty level" do
      manager = PointClickEngine::UI::ConfigurationManager.new
      manager.set_difficulty("hard")

      manager.config.difficulty.should eq("hard")
      manager.has_unsaved_changes.should be_true
    end

    it "ignores invalid difficulty" do
      manager = PointClickEngine::UI::ConfigurationManager.new
      original_difficulty = manager.config.difficulty
      manager.set_difficulty("impossible") # Not in available list

      manager.config.difficulty.should eq(original_difficulty)
    end
  end

  describe "language and localization" do
    it "sets language" do
      manager = PointClickEngine::UI::ConfigurationManager.new
      manager.set_language("es")

      manager.config.language.should eq("es")
      manager.has_unsaved_changes.should be_true
    end

    it "ignores invalid language" do
      manager = PointClickEngine::UI::ConfigurationManager.new
      original_language = manager.config.language
      manager.set_language("invalid") # Not in available list

      manager.config.language.should eq(original_language)
    end
  end

  describe "configuration retrieval" do
    it "gets setting by key" do
      manager = PointClickEngine::UI::ConfigurationManager.new
      manager.get_setting("resolution").should eq("1024x768")
      manager.get_setting("fullscreen").should eq("false")
      manager.get_setting("master_volume").should eq("1.0")
      manager.get_setting("difficulty").should eq("normal")
      manager.get_setting("language").should eq("en")
    end

    it "returns empty string for unknown key" do
      manager = PointClickEngine::UI::ConfigurationManager.new
      manager.get_setting("unknown_key").should eq("")
    end

    it "provides configuration summary" do
      manager = PointClickEngine::UI::ConfigurationManager.new
      summary = manager.get_config_summary

      summary["Resolution"].should eq("1024x768")
      summary["Fullscreen"].should eq("No")
      summary["Master Volume"].should eq("100%")
      summary["Difficulty"].should eq("Normal")
      summary["Language"].should eq("EN")
    end
  end

  describe "configuration reset" do
    it "resets to defaults" do
      manager = PointClickEngine::UI::ConfigurationManager.new
      # Change some settings
      manager.set_fullscreen(true)
      manager.set_master_volume(0.5)
      manager.set_difficulty("hard")

      manager.reset_to_defaults

      manager.config.fullscreen.should be_false
      manager.config.master_volume.should eq(1.0)
      manager.config.difficulty.should eq("normal")
      manager.has_unsaved_changes.should be_true
    end

    it "resets display category to defaults" do
      manager = PointClickEngine::UI::ConfigurationManager.new
      manager.set_fullscreen(true)
      manager.set_vsync(false)

      manager.reset_category_to_defaults(PointClickEngine::UI::ConfigurationManager::ConfigCategory::Display)

      manager.config.fullscreen.should be_false
      manager.config.vsync.should be_true
      manager.has_unsaved_changes.should be_true
    end

    it "resets audio category to defaults" do
      manager = PointClickEngine::UI::ConfigurationManager.new
      manager.set_master_volume(0.5)
      manager.set_music_volume(0.3)

      manager.reset_category_to_defaults(PointClickEngine::UI::ConfigurationManager::ConfigCategory::Audio)

      manager.config.master_volume.should eq(1.0)
      manager.config.music_volume.should eq(0.8_f32)
      manager.has_unsaved_changes.should be_true
    end

    it "resets gameplay category to defaults" do
      manager = PointClickEngine::UI::ConfigurationManager.new
      manager.set_text_speed(2.0)
      manager.set_auto_save(false)
      manager.set_difficulty("hard")

      manager.reset_category_to_defaults(PointClickEngine::UI::ConfigurationManager::ConfigCategory::Gameplay)

      manager.config.text_speed.should eq(1.0)
      manager.config.auto_save.should be_true
      manager.config.difficulty.should eq("normal")
      manager.has_unsaved_changes.should be_true
    end
  end

  describe "configuration validation" do
    it "validates correct configuration" do
      manager = PointClickEngine::UI::ConfigurationManager.new
      issues = manager.validate_configuration
      issues.should be_empty
    end

    it "detects invalid resolution" do
      manager = PointClickEngine::UI::ConfigurationManager.new
      manager.config.resolution = PointClickEngine::UI::ConfigurationManager::Resolution.new(-100, -200)
      issues = manager.validate_configuration

      issues.should_not be_empty
      issues.any? { |issue| issue.includes?("resolution") }.should be_true
    end

    it "detects volume out of range" do
      manager = PointClickEngine::UI::ConfigurationManager.new
      manager.config.master_volume = 2.0 # Above max
      issues = manager.validate_configuration

      issues.should_not be_empty
      issues.any? { |issue| issue.includes?("Master volume") }.should be_true
    end

    it "detects invalid difficulty" do
      manager = PointClickEngine::UI::ConfigurationManager.new
      manager.config.difficulty = "invalid_difficulty"
      issues = manager.validate_configuration

      issues.should_not be_empty
      issues.any? { |issue| issue.includes?("difficulty") }.should be_true
    end

    it "detects invalid language" do
      manager = PointClickEngine::UI::ConfigurationManager.new
      manager.config.language = "invalid_language"
      issues = manager.validate_configuration

      issues.should_not be_empty
      issues.any? { |issue| issue.includes?("language") }.should be_true
    end
  end

  describe "file operations" do
    temp_config_file = "test_config.json"

    before_each do
      manager = PointClickEngine::UI::ConfigurationManager.new
      manager.config_file_path = temp_config_file
      # Clean up any existing test file
      File.delete(temp_config_file) if File.exists?(temp_config_file)
    end

    after_each do
      # Clean up test file
      File.delete(temp_config_file) if File.exists?(temp_config_file)
    end

    it "saves configuration to file" do
      manager = PointClickEngine::UI::ConfigurationManager.new
      manager.config_file_path = temp_config_file
      manager.set_fullscreen(true)
      manager.set_master_volume(0.7)

      success = manager.save_configuration
      success.should be_true
      manager.has_unsaved_changes.should be_false
      File.exists?(temp_config_file).should be_true
    end

    it "loads configuration from file" do
      manager = PointClickEngine::UI::ConfigurationManager.new
      manager.config_file_path = temp_config_file
      # Save a configuration first
      manager.set_fullscreen(true)
      manager.set_master_volume(0.7)
      manager.set_difficulty("hard")
      manager.save_configuration

      # Reset and load
      manager.reset_to_defaults
      success = manager.load_configuration

      success.should be_true
      manager.config.fullscreen.should be_true
      manager.config.master_volume.should be_close(0.7, 0.01)
      manager.config.difficulty.should eq("hard")
      manager.has_unsaved_changes.should be_false
    end

    it "handles missing configuration file" do
      manager = PointClickEngine::UI::ConfigurationManager.new
      manager.config_file_path = temp_config_file
      success = manager.load_configuration
      success.should be_false
    end

    it "handles malformed configuration file" do
      manager = PointClickEngine::UI::ConfigurationManager.new
      manager.config_file_path = temp_config_file
      # Create invalid JSON file
      File.write(temp_config_file, "invalid json content")

      success = manager.load_configuration
      success.should be_false
    end
  end

  describe "callbacks" do
    it "calls resolution changed callback" do
      manager = PointClickEngine::UI::ConfigurationManager.new
      callback_called = false
      new_resolution = nil.as(PointClickEngine::UI::ConfigurationManager::Resolution?)

      manager.on_resolution_changed = ->(resolution : PointClickEngine::UI::ConfigurationManager::Resolution) {
        callback_called = true
        new_resolution = resolution
      }

      target_resolution = PointClickEngine::UI::ConfigurationManager::Resolution.new(1920, 1080)
      manager.set_resolution(target_resolution)

      callback_called.should be_true
      new_resolution.should eq(target_resolution)
    end

    it "calls volume changed callback" do
      manager = PointClickEngine::UI::ConfigurationManager.new
      callback_called = false
      volume_type = ""
      volume_value = 0.0_f32

      manager.on_volume_changed = ->(type : String, value : Float32) {
        callback_called = true
        volume_type = type
        volume_value = value
      }

      manager.set_master_volume(0.6)

      callback_called.should be_true
      volume_type.should eq("master")
      volume_value.should eq(0.6_f32)
    end

    it "calls setting changed callback" do
      manager = PointClickEngine::UI::ConfigurationManager.new
      callback_called = false
      setting_key = ""
      setting_value = ""

      manager.on_setting_changed = ->(key : String, value : String) {
        callback_called = true
        setting_key = key
        setting_value = value
      }

      manager.set_fullscreen(true)

      callback_called.should be_true
      setting_key.should eq("fullscreen")
      setting_value.should eq("true")
    end
  end

  describe "resolution struct" do
    it "creates resolution with automatic name" do
      resolution = PointClickEngine::UI::ConfigurationManager::Resolution.new(1920, 1080)
      resolution.name.should eq("1920x1080")
    end

    it "creates resolution with custom name" do
      resolution = PointClickEngine::UI::ConfigurationManager::Resolution.new(1920, 1080, "Full HD")
      resolution.name.should eq("Full HD")
    end

    it "converts to string representation" do
      resolution = PointClickEngine::UI::ConfigurationManager::Resolution.new(1280, 720, "HD")
      resolution.to_s.should eq("HD")
    end
  end

  describe "edge cases and error handling" do
    it "handles zero volume settings" do
      manager = PointClickEngine::UI::ConfigurationManager.new
      manager.set_master_volume(0.0)
      manager.config.master_volume.should eq(0.0)
    end

    it "handles maximum volume settings" do
      manager = PointClickEngine::UI::ConfigurationManager.new
      manager.set_master_volume(1.0)
      manager.config.master_volume.should eq(1.0)
    end

    it "handles minimum text speed" do
      manager = PointClickEngine::UI::ConfigurationManager.new
      manager.set_text_speed(0.1)
      manager.config.text_speed.should eq(0.1_f32)
    end

    it "handles maximum text speed" do
      manager = PointClickEngine::UI::ConfigurationManager.new
      manager.set_text_speed(3.0)
      manager.config.text_speed.should eq(3.0)
    end

    it "maintains configuration integrity after multiple operations" do
      manager = PointClickEngine::UI::ConfigurationManager.new
      # Perform many operations
      manager.set_resolution_by_index(3)
      manager.set_fullscreen(true)
      manager.set_master_volume(0.8)
      manager.set_music_volume(0.6)
      manager.set_text_speed(1.5)
      manager.set_difficulty("hard")
      manager.set_language("es")

      # Validate everything is still consistent
      issues = manager.validate_configuration
      issues.should be_empty
      manager.has_unsaved_changes.should be_true
    end
  end
end
