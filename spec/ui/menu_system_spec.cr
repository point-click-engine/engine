require "../spec_helper"
require "../../src/ui/menu_system"

describe PointClickEngine::UI::MenuSystem do
  describe "initialization" do
    it "initializes with default components" do
      menu_system = PointClickEngine::UI::MenuSystem.new
      menu_system.input_handler.should be_a(PointClickEngine::UI::MenuInputHandler)
      menu_system.renderer.should be_a(PointClickEngine::UI::MenuRenderer)
      menu_system.navigator.should be_a(PointClickEngine::UI::MenuNavigator)
      menu_system.config_manager.should be_a(PointClickEngine::UI::ConfigurationManager)
    end

    it "sets up default menus" do
      menu_system = PointClickEngine::UI::MenuSystem.new
      menu_system.menu_items.has_key?("main").should be_true
      menu_system.menu_items.has_key?("pause").should be_true
      menu_system.menu_items.has_key?("options").should be_true
      menu_system.menu_items.has_key?("save").should be_true
      menu_system.menu_items.has_key?("load").should be_true
    end

    it "starts hidden with main menu selected" do
      menu_system = PointClickEngine::UI::MenuSystem.new
      menu_system.visible.should be_false
      menu_system.current_menu.should eq("main")
      menu_system.in_game.should be_false
    end

    it "sets up default menu content" do
      menu_system = PointClickEngine::UI::MenuSystem.new
      main_items = menu_system.menu_items["main"]
      main_items.should contain("New Game")
      main_items.should contain("Load Game")
      main_items.should contain("Options")
      main_items.should contain("Quit")
    end
  end

  describe "menu display management" do
    it "shows menu system" do
      menu_system = PointClickEngine::UI::MenuSystem.new
      menu_system.show("main")

      menu_system.visible.should be_true
      menu_system.current_menu.should eq("main")
    end

    it "hides menu system" do
      menu_system = PointClickEngine::UI::MenuSystem.new
      menu_system.show("main")
      menu_system.hide

      menu_system.visible.should be_false
    end

    it "updates layout when showing menu" do
      menu_system = PointClickEngine::UI::MenuSystem.new
      original_bounds = menu_system.menu_bounds
      menu_system.show("main")

      # Bounds should be updated (centered)
      menu_system.menu_bounds.x.should be >= 0
      menu_system.menu_bounds.y.should be >= 0
    end
  end

  describe "menu switching" do
    it "switches between menus correctly" do
      menu_system = PointClickEngine::UI::MenuSystem.new
      menu_system.show("main")
      menu_system.switch_to_menu("options")

      menu_system.current_menu.should eq("options")
      menu_system.navigator.total_items.should eq(menu_system.menu_items["options"].size)
    end

    it "validates menu exists before switching" do
      menu_system = PointClickEngine::UI::MenuSystem.new
      original_menu = menu_system.current_menu
      menu_system.switch_to_menu("nonexistent")

      menu_system.current_menu.should eq(original_menu)
    end
  end

  describe "custom menu management" do
    it "adds custom menus" do
      menu_system = PointClickEngine::UI::MenuSystem.new
      custom_items = ["Custom Item 1", "Custom Item 2"]
      menu_system.add_menu("custom", "Custom Menu", custom_items)

      menu_system.menu_items.has_key?("custom").should be_true
      menu_system.menu_items["custom"].should eq(custom_items)
      menu_system.menu_titles["custom"].should eq("Custom Menu")
    end

    it "manages item enabled states" do
      menu_system = PointClickEngine::UI::MenuSystem.new
      menu_system.set_menu_item_enabled("main", 0, false)

      enabled_items = menu_system.menu_enabled_items["main"]
      enabled_items[0].should be_false
    end

    it "gets current menu item correctly" do
      menu_system = PointClickEngine::UI::MenuSystem.new
      menu_system.show("main")
      menu_system.navigator.navigate_to(0)

      current_item = menu_system.get_current_item
      current_item.should eq("New Game")
    end

    it "returns nil for invalid current item" do
      menu_system = PointClickEngine::UI::MenuSystem.new
      # Show a non-existent menu
      menu_system.show("non_existent")

      current_item = menu_system.get_current_item
      current_item.should be_nil
    end
  end

  describe "callback system" do
    it "calls new game callback" do
      menu_system = PointClickEngine::UI::MenuSystem.new
      callback_called = false

      menu_system.on_new_game = -> {
        callback_called = true
      }

      menu_system.show("main")
      menu_system.navigator.navigate_to(0) # "New Game"
      menu_system.execute_current_action

      callback_called.should be_true
    end

    it "calls quit callback" do
      menu_system = PointClickEngine::UI::MenuSystem.new
      callback_called = false

      menu_system.on_quit = -> {
        callback_called = true
      }

      menu_system.show("main")
      quit_index = menu_system.menu_items["main"].index("Quit") || -1
      menu_system.navigator.navigate_to(quit_index)
      menu_system.execute_current_action

      callback_called.should be_true
    end

    it "calls save game callback" do
      menu_system = PointClickEngine::UI::MenuSystem.new
      callback_called = false

      menu_system.on_save_game = -> {
        callback_called = true
      }

      menu_system.show("save")
      menu_system.navigator.navigate_to(0) # First save slot
      menu_system.execute_current_action

      callback_called.should be_true
    end

    it "calls load game callback" do
      menu_system = PointClickEngine::UI::MenuSystem.new
      callback_called = false

      menu_system.on_load_game = -> {
        callback_called = true
      }

      menu_system.show("load")
      menu_system.navigator.navigate_to(0) # First load slot
      menu_system.execute_current_action

      callback_called.should be_true
    end
  end

  describe "configuration integration" do
    it "provides access to configuration manager" do
      menu_system = PointClickEngine::UI::MenuSystem.new
      config_manager = menu_system.get_configuration_manager
      config_manager.should be_a(PointClickEngine::UI::ConfigurationManager)
    end

    it "applies configuration to components" do
      menu_system = PointClickEngine::UI::MenuSystem.new
      # Change keyboard navigation setting
      menu_system.config_manager.config.keyboard_navigation = false
      menu_system.apply_configuration

      menu_system.input_handler.keyboard_navigation_enabled.should be_false
    end

    it "validates all system components" do
      menu_system = PointClickEngine::UI::MenuSystem.new
      # Show a menu first so navigator has items
      menu_system.show("main")

      issues = menu_system.validate_system
      issues.should be_a(Array(String))
      # With default settings, should have no issues
      issues.should be_empty
    end
  end

  describe "layout management" do
    it "auto-updates layout when enabled" do
      menu_system = PointClickEngine::UI::MenuSystem.new
      menu_system.auto_layout = true
      original_bounds = menu_system.menu_bounds

      menu_system.show("main")

      # Layout should be updated
      menu_system.menu_bounds.should_not eq(original_bounds)
    end

    it "centers menu on screen" do
      menu_system = PointClickEngine::UI::MenuSystem.new
      menu_system.show("main")

      # Menu should be roughly centered (assuming 1024x768 screen)
      menu_system.menu_bounds.x.should be > 100
      menu_system.menu_bounds.x.should be < 800
      menu_system.menu_bounds.y.should be > 50
      menu_system.menu_bounds.y.should be < 600
    end

    it "calculates appropriate menu size" do
      RaylibContext.with_window do
        menu_system = PointClickEngine::UI::MenuSystem.new
        menu_system.auto_layout = true
        menu_system.show("main")

        # Menu should have reasonable dimensions
        menu_system.menu_bounds.width.should be > 100
        menu_system.menu_bounds.height.should be > 100
      end
    end
  end

  describe "edge cases and error handling" do
    it "handles empty menu gracefully" do
      RaylibContext.with_window do
        menu_system = PointClickEngine::UI::MenuSystem.new
        menu_system.add_menu("empty", "Empty Menu", [] of String)
        menu_system.show("empty")

        # Should not crash
        menu_system.update(0.016)
        menu_system.render
      end
    end

    it "handles navigation with all items disabled" do
      menu_system = PointClickEngine::UI::MenuSystem.new
      # Disable all main menu items
      main_items = menu_system.menu_items["main"]
      main_items.size.times do |i|
        menu_system.set_menu_item_enabled("main", i, false)
      end

      menu_system.show("main")

      # Should handle gracefully
      menu_system.navigator.has_enabled_items?.should be_false
    end

    it "handles invalid menu actions gracefully" do
      menu_system = PointClickEngine::UI::MenuSystem.new
      menu_system.current_menu = "nonexistent"

      # Should not crash when executing action
      menu_system.execute_current_action
    end
  end

  describe "menu callback integration" do
    it "executes new game callback when New Game is selected" do
      menu_system = PointClickEngine::UI::MenuSystem.new
      callback_called = false

      menu_system.on_new_game = -> {
        callback_called = true
      }

      menu_system.show("main")
      new_game_index = menu_system.menu_items["main"].index("New Game") || -1
      menu_system.navigator.navigate_to(new_game_index)
      menu_system.execute_current_action

      callback_called.should be_true
    end

    it "allows callbacks to be nil without crashing" do
      menu_system = PointClickEngine::UI::MenuSystem.new
      menu_system.on_new_game = nil

      menu_system.show("main")
      new_game_index = menu_system.menu_items["main"].index("New Game") || -1
      menu_system.navigator.navigate_to(new_game_index)

      # Should not crash when callback is nil
      menu_system.execute_current_action
    end

    it "calls appropriate callback for each main menu action" do
      menu_system = PointClickEngine::UI::MenuSystem.new
      callbacks_called = [] of String

      menu_system.on_new_game = -> { callbacks_called << "new_game" }
      menu_system.on_load_game = -> { callbacks_called << "load_game" }
      menu_system.on_options = -> { callbacks_called << "options" }
      menu_system.on_quit = -> { callbacks_called << "quit" }

      menu_system.show("main")

      # Test New Game
      new_game_index = menu_system.menu_items["main"].index("New Game") || -1
      menu_system.navigator.navigate_to(new_game_index)
      menu_system.execute_current_action

      # Test Quit
      quit_index = menu_system.menu_items["main"].index("Quit") || -1
      menu_system.navigator.navigate_to(quit_index)
      menu_system.execute_current_action

      callbacks_called.should contain("new_game")
      callbacks_called.should contain("quit")
    end
  end
end
