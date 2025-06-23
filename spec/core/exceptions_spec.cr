require "../spec_helper"

describe PointClickEngine::Core do
  describe "LoadingError" do
    it "creates a base loading error" do
      error = PointClickEngine::Core::LoadingError.new("Test error", "test.yaml", "field_name")
      error.message.should eq("Test error")
      error.filename.should eq("test.yaml")
      error.field.should eq("field_name")
    end

    it "allows nil values" do
      error = PointClickEngine::Core::LoadingError.new
      error.message.should be_nil
      error.filename.should be_nil
      error.field.should be_nil
    end
  end

  describe "ConfigError" do
    it "creates a configuration error with prefixed message" do
      error = PointClickEngine::Core::ConfigError.new("Invalid value", "config.yaml", "window.width")
      error.message.should eq("Configuration Error: Invalid value")
      error.filename.should eq("config.yaml")
      error.field.should eq("window.width")
    end
  end

  describe "AssetError" do
    it "creates an asset error with asset path" do
      error = PointClickEngine::Core::AssetError.new("File not found", "sprites/player.png", "scene1.yaml")
      error.message.should eq("Asset Error: File not found (asset: sprites/player.png)")
      error.asset_path.should eq("sprites/player.png")
      error.filename.should eq("scene1.yaml")
    end
  end

  describe "SceneError" do
    it "creates a scene error with scene name" do
      error = PointClickEngine::Core::SceneError.new("Invalid hotspot", "intro_scene", "hotspots[0]")
      error.message.should eq("Scene Error in 'intro_scene': Invalid hotspot")
      error.scene_name.should eq("intro_scene")
      error.filename.should eq("intro_scene.yaml")
      error.field.should eq("hotspots[0]")
    end
  end

  describe "ValidationError" do
    it "creates a validation error with multiple errors" do
      errors = ["Missing field 'name'", "Invalid value for 'width'", "Asset not found"]
      error = PointClickEngine::Core::ValidationError.new(errors, "game.yaml")
      
      error.errors.should eq(errors)
      error.filename.should eq("game.yaml")
      error.message.not_nil!.should contain("Validation failed with 3 error(s):")
      error.message.not_nil!.should contain("Missing field 'name'")
      error.message.not_nil!.should contain("Invalid value for 'width'")
      error.message.not_nil!.should contain("Asset not found")
    end
  end

  describe "SaveGameError" do
    it "creates a save game error" do
      error = PointClickEngine::Core::SaveGameError.new("Corrupted save data", "save1.dat")
      error.message.should eq("Save Game Error: Corrupted save data")
      error.filename.should eq("save1.dat")
    end
  end
end