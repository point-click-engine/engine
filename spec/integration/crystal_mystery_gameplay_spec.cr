require "../spec_helper"
require "../../crystal_mystery/main"

describe "Crystal Mystery Gameplay" do
  describe "Game Flow" do
    it "starts in main menu and can navigate to game scenes" do
      game = CrystalMysteryGame.new

      # Should start in main menu
      game.engine.current_scene.try(&.name).should eq("main_menu")

      # Navigate to library scene
      game.engine.change_scene("library")
      game.engine.current_scene.try(&.name).should eq("library")

      # Navigate to laboratory
      game.engine.change_scene("laboratory")
      game.engine.current_scene.try(&.name).should eq("laboratory")

      # Navigate to garden
      game.engine.change_scene("garden")
      game.engine.current_scene.try(&.name).should eq("garden")
    end

    it "maintains player state across scenes" do
      game = CrystalMysteryGame.new

      player = game.engine.player
      player.should_not be_nil

      if player
        original_name = player.name

        # Change scene
        game.engine.change_scene("library")

        # Player should still exist and have same name
        game.engine.player.should_not be_nil
        game.engine.player.try(&.name).should eq(original_name)
      end
    end
  end

  describe "Inventory System" do
    it "can add and remove items" do
      game = CrystalMysteryGame.new
      inventory = game.engine.inventory

      # Start with empty inventory
      initial_count = inventory.items.size

      # Add an item
      test_item = PointClickEngine::Inventory::InventoryItem.new("test_key", "A test key")
      inventory.add_item(test_item)

      inventory.items.size.should eq(initial_count + 1)
      inventory.has_item?("test_key").should be_true

      # Remove the item
      inventory.remove_item("test_key")
      inventory.items.size.should eq(initial_count)
      inventory.has_item?("test_key").should be_false
    end

    it "handles item selection" do
      game = CrystalMysteryGame.new
      inventory = game.engine.inventory

      # Add items
      key = PointClickEngine::Inventory::InventoryItem.new("key", "A brass key")
      book = PointClickEngine::Inventory::InventoryItem.new("book", "An old book")

      inventory.add_item(key)
      inventory.add_item(book)

      # Select key
      inventory.select_item("key")
      inventory.selected_item.try(&.name).should eq("key")

      # Select book
      inventory.select_item("book")
      inventory.selected_item.try(&.name).should eq("book")

      # Deselect
      inventory.deselect_item
      inventory.selected_item.should be_nil
    end
  end

  describe "Dialog System" do
    it "can show simple messages" do
      game = CrystalMysteryGame.new
      dialog_manager = game.engine.dialog_manager

      dialog_manager.should_not be_nil

      if dm = dialog_manager
        # No dialog initially
        dm.is_dialog_active?.should be_false

        # Show message
        dm.show_message("Hello, detective!")
        dm.is_dialog_active?.should be_true

        # Check dialog content
        current_dialog = dm.current_dialog
        current_dialog.should_not be_nil
        current_dialog.try(&.text).should eq("Hello, detective!")
      end
    end

    it "handles timed messages" do
      game = CrystalMysteryGame.new

      if dm = game.engine.dialog_manager
        # Show timed message (2 seconds)
        dm.show_message("This will disappear soon", 2.0f32)
        dm.is_dialog_active?.should be_true

        # After 1 second, still active
        dm.update(1.0f32)
        dm.is_dialog_active?.should be_true

        # After another 1.5 seconds (total 2.5), should be gone
        dm.update(1.5f32)
        dm.is_dialog_active?.should be_false
      end
    end
  end

  describe "Achievement System" do
    it "can register and unlock achievements" do
      game = CrystalMysteryGame.new

      if am = game.engine.achievement_manager
        # Register achievement
        am.register("first_clue", "First Clue", "Found your first clue in the mystery")

        # Should not be unlocked initially
        am.is_unlocked?("first_clue").should be_false

        # Unlock it
        unlocked = am.unlock("first_clue")
        unlocked.should be_true

        # Should now be unlocked
        am.is_unlocked?("first_clue").should be_true

        # Trying to unlock again should return false
        unlocked_again = am.unlock("first_clue")
        unlocked_again.should be_false
      end
    end

    it "queues achievement notifications" do
      game = CrystalMysteryGame.new

      if am = game.engine.achievement_manager
        # Register multiple achievements
        am.register("explorer", "Explorer", "Visited all rooms")
        am.register("detective", "Detective", "Solved the mystery")

        # Unlock them
        am.unlock("explorer")
        am.unlock("detective")

        # Should have notifications queued
        am.@notification_queue.size.should eq(2)
      end
    end
  end

  describe "Scene Interactions" do
    it "has hotspots in each scene" do
      game = CrystalMysteryGame.new

      # Check library scene
      game.engine.change_scene("library")
      library_scene = game.engine.current_scene
      library_scene.should_not be_nil
      if scene = library_scene
        scene.hotspots.size.should be > 0
      end

      # Check laboratory scene
      game.engine.change_scene("laboratory")
      lab_scene = game.engine.current_scene
      lab_scene.should_not be_nil
      if scene = lab_scene
        scene.hotspots.size.should be > 0
      end

      # Check garden scene
      game.engine.change_scene("garden")
      garden_scene = game.engine.current_scene
      garden_scene.should_not be_nil
      if scene = garden_scene
        scene.hotspots.size.should be > 0
      end
    end

    it "can find hotspots by position" do
      game = CrystalMysteryGame.new
      game.engine.change_scene("library")

      scene = game.engine.current_scene
      scene.should_not be_nil

      if scene
        # Should have hotspots
        scene.hotspots.size.should be > 0

        # Get first hotspot
        first_hotspot = scene.hotspots.first

        # Check if we can find it by position
        center_point = Raylib::Vector2.new(
          x: first_hotspot.position.x + first_hotspot.size.x / 2,
          y: first_hotspot.position.y + first_hotspot.size.y / 2
        )

        found_hotspot = scene.get_hotspot_at(center_point)
        found_hotspot.should_not be_nil
        found_hotspot.try(&.name).should eq(first_hotspot.name)
      end
    end
  end

  describe "Configuration System" do
    it "can store and retrieve settings" do
      game = CrystalMysteryGame.new

      config = game.engine.config
      config.should_not be_nil

      if cfg = config
        # Set a setting
        cfg.set("test.value", "hello")

        # Retrieve it
        value = cfg.get("test.value", "default")
        value.should eq("hello")

        # Test with default
        missing = cfg.get("missing.key", "default_value")
        missing.should eq("default_value")
      end
    end

    it "handles different data types" do
      game = CrystalMysteryGame.new

      if cfg = game.engine.config
        # Test string
        cfg.set("string_key", "test_string")
        cfg.get("string_key", "").should eq("test_string")

        # Test number as string
        cfg.set("number_key", "42")
        cfg.get("number_key", "0").to_i.should eq(42)

        # Test boolean as string
        cfg.set("bool_key", "true")
        cfg.get("bool_key", "false").should eq("true")
      end
    end
  end

  describe "Scripting System" do
    it "can execute basic Lua scripts" do
      game = CrystalMysteryGame.new

      script_engine = game.engine.script_engine
      script_engine.should_not be_nil

      if se = script_engine
        # Execute simple script
        result = se.execute_script("return 2 + 2")
        result.should be_true

        # Test variable setting
        se.set_global("test_var", "hello")
        value = se.get_global("test_var")
        value.should eq("hello")
      end
    end

    it "handles script errors gracefully" do
      game = CrystalMysteryGame.new

      if se = game.engine.script_engine
        # Execute invalid script
        result = se.execute_script("invalid lua syntax ][")
        result.should be_false
      end
    end
  end
end
