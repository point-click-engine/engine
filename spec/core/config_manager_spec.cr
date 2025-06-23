require "../spec_helper"
require "../../src/core/config_manager"

describe PointClickEngine::Core::ConfigManager do
  describe "#initialize" do
    it "creates a new ConfigManager instance" do
      manager = PointClickEngine::Core::ConfigManager.new("test_config.yml")
      manager.should be_a(PointClickEngine::Core::ConfigManager)
    end
  end

  describe "#set and #get" do
    it "stores and retrieves configuration values" do
      manager = PointClickEngine::Core::ConfigManager.new("test_config.yml")

      manager.set("test.key", "test_value")
      manager.get("test.key").should eq("test_value")
    end

    it "returns default value when key doesn't exist" do
      manager = PointClickEngine::Core::ConfigManager.new("test_config.yml")

      manager.get("nonexistent.key", "default").should eq("default")
    end
  end

  describe "#has_key?" do
    it "returns true for existing keys" do
      manager = PointClickEngine::Core::ConfigManager.new("test_config.yml")

      manager.set("test.key", "value")
      manager.has_key?("test.key").should be_true
    end
  end
end
