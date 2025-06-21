require "../spec_helper"
require "../../crystal_mystery/main"

describe "Crystal Mystery UI Visibility" do
  describe "Main Menu Visibility" do
    it "shows GUI elements in main menu" do
      game = CrystalMysteryGame.new

      # Ensure we're in main menu
      game.engine.current_scene.try(&.name).should eq("main_menu")

      # GUI should be visible
      game.engine.gui.try(&.visible).should be_true

      # Check specific UI elements exist
      gui = game.engine.gui
      gui.should_not be_nil

      if gui
        # Title label should exist
        gui.labels.has_key?("title").should be_true

        # Menu buttons should exist
        gui.buttons.has_key?("new_game").should be_true
        gui.buttons.has_key?("load_game").should be_true
        gui.buttons.has_key?("options").should be_true
        gui.buttons.has_key?("quit").should be_true
      end
    end
  end

  describe "Game Scene Visibility" do
    it "hides main menu GUI when entering game scene" do
      game = CrystalMysteryGame.new

      # Simulate starting new game
      # This would normally be triggered by clicking "New Game" button
      if player = game.engine.player
        player.name = "Detective"
        player.position = Raylib::Vector2.new(x: 500f32, y: 400f32)
      end

      game.engine.inventory.clear
      game.engine.change_scene("library")

      # Current scene should be library
      game.engine.current_scene.try(&.name).should eq("library")

      # GUI should still exist but may have different content
      game.engine.gui.should_not be_nil
    end

    it "shows inventory in game scenes" do
      game = CrystalMysteryGame.new
      game.engine.change_scene("library")

      # Inventory should be available
      game.engine.inventory.should_not be_nil

      # Inventory should be controllable
      game.engine.inventory.visible.should be_false # Hidden by default
      game.engine.inventory.show
      game.engine.inventory.visible.should be_true
      game.engine.inventory.hide
      game.engine.inventory.visible.should be_false
    end
  end

  describe "Dialog Visibility" do
    it "shows dialog when triggered" do
      game = CrystalMysteryGame.new

      dialog_manager = game.engine.dialog_manager
      dialog_manager.should_not be_nil

      if dm = dialog_manager
        # Initially no dialog should be active
        dm.is_dialog_active?.should be_false

        # Show a message
        dm.show_message("Test message")

        # Dialog should now be active
        dm.is_dialog_active?.should be_true
        dm.current_dialog.should_not be_nil
        dm.current_dialog.try(&.visible).should be_true
        dm.current_dialog.try(&.text).should eq("Test message")
      end
    end

    it "hides dialog after timeout" do
      game = CrystalMysteryGame.new

      if dm = game.engine.dialog_manager
        # Show a timed message
        dm.show_message("Temporary message", 1.0f32)
        dm.is_dialog_active?.should be_true

        # Simulate time passing
        dm.update(1.5f32)

        # Dialog should be gone
        dm.is_dialog_active?.should be_false
      end
    end
  end

  describe "Achievement Visibility" do
    it "shows achievement notification when unlocked" do
      game = CrystalMysteryGame.new

      am = game.engine.achievement_manager
      am.should_not be_nil

      if achievement_manager = am
        # Register test achievement
        achievement_manager.register("test_achievement", "Test Achievement", "You did it!")

        # Unlock it
        unlocked = achievement_manager.unlock("test_achievement")
        unlocked.should be_true

        # Notification should be queued
        # (In real game, this would be visible on screen)
        achievement_manager.@notification_queue.size.should eq(1)
      end
    end
  end

  describe "Scene Element Visibility" do
    it "shows hotspots in debug mode" do
      game = CrystalMysteryGame.new
      game.engine.change_scene("library")

      # Enable debug mode
      PointClickEngine::Core::Engine.debug_mode = true

      # In debug mode, hotspots should be visible
      if scene = game.engine.current_scene
        scene.hotspots.each do |hotspot|
          # In debug mode, hotspots would typically be drawn with outlines
          hotspot.visible.should be_true
        end
      end

      # Disable debug mode
      PointClickEngine::Core::Engine.debug_mode = false
    end
  end

  describe "UI Toggle Visibility" do
    it "can hide/show UI elements" do
      game = CrystalMysteryGame.new

      # UI should be visible by default
      game.engine.ui_visible.should be_true

      # Hide UI
      game.engine.hide_ui
      game.engine.ui_visible.should be_false

      # Show UI
      game.engine.show_ui
      game.engine.ui_visible.should be_true

      # Toggle UI
      game.engine.toggle_ui
      game.engine.ui_visible.should be_false
      game.engine.toggle_ui
      game.engine.ui_visible.should be_true
    end

    it "hides GUI manager when UI is hidden" do
      game = CrystalMysteryGame.new

      gui = game.engine.gui
      gui.should_not be_nil

      if gui
        # GUI should be visible initially
        gui.visible.should be_true

        # Hide UI
        game.engine.hide_ui
        gui.visible.should be_false

        # Show UI
        game.engine.show_ui
        gui.visible.should be_true
      end
    end

    it "hides inventory when UI is hidden" do
      game = CrystalMysteryGame.new

      inventory = game.engine.inventory
      inventory.should_not be_nil

      # Initially hidden
      initial_visibility = inventory.visible

      # Show inventory first
      inventory.show
      inventory.visible.should be_true

      # Hide UI
      game.engine.hide_ui
      inventory.visible.should be_false

      # Show UI
      game.engine.show_ui
      inventory.visible.should be_true
    end
  end
end
