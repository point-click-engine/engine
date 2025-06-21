require "../spec_helper"
require "../../src/core/config_manager"

describe PointClickEngine::Core::ConfigManager do
  describe "#initialize" do
    it "loads default settings" do
      config = PointClickEngine::Core::ConfigManager.new

      config.get("game.version").should eq("1.0.0")
      config.get("game.debug").should eq("false")
      config.get("audio.master_volume").should eq("1.0")
      config.get("graphics.fullscreen").should eq("false")
    end

    it "accepts a custom config file path" do
      config = PointClickEngine::Core::ConfigManager.new("custom_config.yaml")
      config.config_file.should eq("custom_config.yaml")
    end
  end

  describe "#get and #set" do
    it "gets and sets string values" do
      config = PointClickEngine::Core::ConfigManager.new

      config.get("custom.key").should be_nil
      config.set("custom.key", "custom value")
      config.get("custom.key").should eq("custom value")
    end

    it "returns default value when key doesn't exist" do
      config = PointClickEngine::Core::ConfigManager.new
      config.get("missing.key", "default").should eq("default")
    end
  end

  describe "#get_int" do
    it "converts string to integer" do
      config = PointClickEngine::Core::ConfigManager.new
      config.set("test.number", "42")
      config.get_int("test.number").should eq(42)
    end

    it "returns default for invalid integer" do
      config = PointClickEngine::Core::ConfigManager.new
      config.set("test.invalid", "not a number")
      config.get_int("test.invalid", 10).should eq(10)
    end

    it "returns default for missing key" do
      config = PointClickEngine::Core::ConfigManager.new
      config.get_int("missing.number", 5).should eq(5)
    end
  end

  describe "#get_float" do
    it "converts string to float" do
      config = PointClickEngine::Core::ConfigManager.new
      config.set("test.float", "3.14")
      config.get_float("test.float").should eq(3.14f32)
    end

    it "returns default for invalid float" do
      config = PointClickEngine::Core::ConfigManager.new
      config.set("test.invalid", "not a float")
      config.get_float("test.invalid", 1.5f32).should eq(1.5f32)
    end
  end

  describe "#get_bool" do
    it "converts various true values" do
      config = PointClickEngine::Core::ConfigManager.new

      ["true", "True", "TRUE", "yes", "Yes", "1", "on", "ON"].each do |value|
        config.set("test.bool", value)
        config.get_bool("test.bool").should be_true
      end
    end

    it "converts various false values" do
      config = PointClickEngine::Core::ConfigManager.new

      ["false", "False", "FALSE", "no", "No", "0", "off", "OFF"].each do |value|
        config.set("test.bool", value)
        config.get_bool("test.bool").should be_false
      end
    end

    it "returns default for invalid bool" do
      config = PointClickEngine::Core::ConfigManager.new
      config.set("test.bool", "maybe")
      config.get_bool("test.bool", true).should be_true
      config.get_bool("test.bool", false).should be_false
    end
  end

  describe "#save_to_file and #load_from_file" do
    it "saves and loads configuration" do
      # Save config
      config1 = PointClickEngine::Core::ConfigManager.new("test_config.yaml")
      config1.set("test.save", "saved value")
      config1.set("test.number", "123")
      config1.save_to_file

      # Load in new instance
      config2 = PointClickEngine::Core::ConfigManager.new("test_config.yaml")
      config2.get("test.save").should eq("saved value")
      config2.get("test.number").should eq("123")

      # Clean up
      File.delete("test_config.yaml") if File.exists?("test_config.yaml")
    end

    it "handles missing config file gracefully" do
      config = PointClickEngine::Core::ConfigManager.new("non_existent.yaml")
      config.get("game.version").should eq("1.0.0") # Should still have defaults
    end
  end

  describe "default values" do
    it "has all expected default values" do
      config = PointClickEngine::Core::ConfigManager.new

      # Game defaults
      config.get("game.version").should_not be_nil
      config.get("game.debug").should_not be_nil

      # Graphics defaults
      config.get("graphics.fullscreen").should_not be_nil
      config.get("graphics.vsync").should_not be_nil
      config.get("graphics.resolution.width").should_not be_nil
      config.get("graphics.resolution.height").should_not be_nil

      # Audio defaults
      config.get("audio.master_volume").should_not be_nil
      config.get("audio.music_volume").should_not be_nil
      config.get("audio.sfx_volume").should_not be_nil
      config.get("audio.mute").should_not be_nil

      # Gameplay defaults
      config.get("gameplay.text_speed").should_not be_nil
      config.get("gameplay.auto_save").should_not be_nil
      config.get("gameplay.language").should_not be_nil
    end
  end
end
