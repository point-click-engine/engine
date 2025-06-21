require "../spec_helper"

describe "Engine Headless Tests" do
  describe "Basic Engine Creation" do
    it "can create an engine without Raylib window" do
      # Test that we can at least create the engine components
      engine = PointClickEngine::Core::Engine.new(800, 600, "Test Game")
      engine.should_not be_nil

      # Add a scene
      scene = PointClickEngine::Scenes::Scene.new("test_scene")
      engine.add_scene(scene)
      engine.scenes.size.should eq(1)

      # Create managers
      dialog_manager = PointClickEngine::UI::DialogManager.new
      dialog_manager.should_not be_nil

      gui_manager = PointClickEngine::UI::GUIManager.new
      gui_manager.should_not be_nil

      achievement_manager = PointClickEngine::Core::AchievementManager.new
      achievement_manager.should_not be_nil
    end
  end

  describe "Dialog System Tests" do
    it "shows and hides dialogs correctly" do
      dm = PointClickEngine::UI::DialogManager.new

      # No dialog initially
      dm.is_dialog_active?.should be_false

      # Show a message
      dm.show_message("Test message")
      dm.is_dialog_active?.should be_true

      # Message should timeout
      dm.update(4.0f32)
      dm.is_dialog_active?.should be_false
    end
  end

  describe "Achievement System Tests" do
    it "unlocks achievements" do
      am = PointClickEngine::Core::AchievementManager.new

      # Register achievement
      am.register("test", "Test Achievement", "Description")

      # Unlock it
      unlocked = am.unlock("test")
      unlocked.should be_true

      # Check it's unlocked
      am.is_unlocked?("test").should be_true

      # Can't unlock again
      unlocked = am.unlock("test")
      unlocked.should be_false
    end
  end

  describe "Inventory System Tests" do
    it "manages items correctly" do
      inv = PointClickEngine::Inventory::InventorySystem.new

      # Add items
      item1 = PointClickEngine::Inventory::InventoryItem.new("key", "A key")
      item2 = PointClickEngine::Inventory::InventoryItem.new("book", "A book")

      inv.add_item(item1)
      inv.add_item(item2)

      inv.items.size.should eq(2)
      inv.has_item?("key").should be_true
      inv.has_item?("book").should be_true

      # Clear inventory
      inv.clear
      inv.items.size.should eq(0)
    end
  end

  describe "Scene Management Tests" do
    it "manages scenes and hotspots" do
      scene = PointClickEngine::Scenes::Scene.new("library")

      # Add hotspots
      hotspot1 = PointClickEngine::Scenes::Hotspot.new(
        "door",
        Raylib::Vector2.new(x: 100f32, y: 100f32),
        Raylib::Vector2.new(x: 50f32, y: 100f32)
      )

      hotspot2 = PointClickEngine::Scenes::Hotspot.new(
        "bookshelf",
        Raylib::Vector2.new(x: 200f32, y: 50f32),
        Raylib::Vector2.new(x: 100f32, y: 200f32)
      )

      scene.add_hotspot(hotspot1)
      scene.add_hotspot(hotspot2)

      scene.hotspots.size.should eq(2)

      # Test contains_point
      hotspot1.contains_point?(Raylib::Vector2.new(x: 125f32, y: 150f32)).should be_true
      hotspot1.contains_point?(Raylib::Vector2.new(x: 0f32, y: 0f32)).should be_false
    end
  end

  describe "GUI System Tests" do
    it "manages UI elements" do
      gui = PointClickEngine::UI::GUIManager.new

      # Add label
      gui.add_label("title", "Test Game", Raylib::Vector2.new(x: 100f32, y: 50f32))
      gui.labels.size.should eq(1)

      # Add button
      clicked = false
      gui.add_button("test", "Click Me",
        Raylib::Vector2.new(x: 100f32, y: 100f32),
        Raylib::Vector2.new(x: 100f32, y: 50f32)
      ) do
        clicked = true
      end

      gui.buttons.size.should eq(1)

      # Simulate button click
      button = gui.buttons["test"]
      button.should_not be_nil
      button.callback.call
      clicked.should be_true
    end
  end
end
