require "../spec_helper"
require "../../src/core/resource_manager"

describe PointClickEngine::Core::ResourceManager do
  describe "#initialize" do
    it "creates a new ResourceManager instance" do
      manager = PointClickEngine::Core::ResourceManager.new
      manager.should be_a(PointClickEngine::Core::ResourceManager)
    end
  end

  describe "#add_asset_path" do
    it "adds a new asset search path" do
      manager = PointClickEngine::Core::ResourceManager.new
      manager.add_asset_path("test_assets/")
      # Test would verify the path was added
    end
  end

  describe "#get_memory_usage" do
    it "returns memory usage statistics" do
      manager = PointClickEngine::Core::ResourceManager.new
      usage = manager.get_memory_usage

      usage[:current].should be >= 0
      usage[:max].should be > 0
      usage[:percentage].should be >= 0.0
    end
  end

  describe "#set_memory_limit" do
    it "sets the memory limit" do
      manager = PointClickEngine::Core::ResourceManager.new
      manager.set_memory_limit(50 * 1024 * 1024) # 50 MB

      usage = manager.get_memory_usage
      usage[:max].should eq(50 * 1024 * 1024)
    end
  end

  describe "#enable_hot_reload" do
    it "enables hot reloading" do
      manager = PointClickEngine::Core::ResourceManager.new
      manager.enable_hot_reload
      # Test would verify hot reload is enabled
    end
  end

  describe "#disable_hot_reload" do
    it "disables hot reloading" do
      manager = PointClickEngine::Core::ResourceManager.new
      manager.disable_hot_reload
      # Test would verify hot reload is disabled
    end
  end

  describe "#cleanup_all_resources" do
    it "cleans up all loaded resources" do
      manager = PointClickEngine::Core::ResourceManager.new
      manager.cleanup_all_resources

      usage = manager.get_memory_usage
      usage[:current].should eq(0)
    end
  end
end
