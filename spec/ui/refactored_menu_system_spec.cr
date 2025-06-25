require "../spec_helper"
require "../../src/ui/refactored_menu_system"

describe PointClickEngine::UI::RefactoredMenuSystem do
  let(menu_system) { PointClickEngine::UI::RefactoredMenuSystem.new }

  before_each do
    # Mock Raylib functions for testing
    RL.stub(:measure_text) { |text, size| text.size * 6 }
    RL.stub(:draw_rectangle_rec) { }
    RL.stub(:draw_rectangle_lines_ex) { }
    RL.stub(:draw_text) { }
    RL.stub(:get_mouse_position) { RL::Vector2.new(0, 0) }
    RL.stub(:is_mouse_button_pressed) { false }
    RL.stub(:is_key_pressed) { false }
  end

  describe "initialization" do
    it "initializes with default components" do
      menu_system.input_handler.should be_a(PointClickEngine::UI::MenuInputHandler)
      menu_system.renderer.should be_a(PointClickEngine::UI::MenuRenderer)
      menu_system.navigator.should be_a(PointClickEngine::UI::MenuNavigator)
      menu_system.config_manager.should be_a(PointClickEngine::UI::ConfigurationManager)
    end

    it "sets up default menus" do
      menu_system.menu_items.should have_key("main")
      menu_system.menu_items.should have_key("pause")
      menu_system.menu_items.should have_key("options")
      menu_system.menu_items.should have_key("save")
      menu_system.menu_items.should have_key("load")
    end

    it "starts hidden with main menu selected" do
      menu_system.visible.should be_false
      menu_system.current_menu.should eq("main")
      menu_system.in_game.should be_false
    end

    it "sets up default menu content" do
      main_items = menu_system.menu_items["main"]
      main_items.should contain("New Game")
      main_items.should contain("Load Game")
      main_items.should contain("Options")
      main_items.should contain("Quit")
    end
  end

  describe "menu display management" do
    it "shows menu system" do
      menu_system.show("main")

      menu_system.visible.should be_true
      menu_system.current_menu.should eq("main")
    end

    it "hides menu system" do
      menu_system.show("main")
      menu_system.hide

      menu_system.visible.should be_false
    end

    it "updates layout when showing menu" do
      original_bounds = menu_system.menu_bounds
      menu_system.show("main")

      # Bounds should be updated (centered)
      menu_system.menu_bounds.x.should be >= 0
      menu_system.menu_bounds.y.should be >= 0
    end

    it "renders only when visible" do
      draw_calls = 0

      RL.stub(:draw_rectangle_rec) do |rect, color|
        draw_calls += 1
      end

      menu_system.render # Should not draw when hidden
      draw_calls.should eq(0)

      menu_system.show("main")
      menu_system.render # Should draw when visible
      draw_calls.should be > 0
    end
  end

  describe "menu navigation" do
    before_each do
      menu_system.show("main")
    end

    it "navigates through menu items" do
      initial_index = menu_system.navigator.get_selected_index

      # Simulate down key press
      RL.stub(:is_key_pressed) do |key|
        key == RL::Key::Down
      end

      menu_system.update(0.016)

      menu_system.navigator.get_selected_index.should eq(initial_index + 1)
    end

    it "wraps navigation at boundaries" do
      # Navigate to last item
      menu_system.navigator.navigate_to_last
      last_index = menu_system.navigator.get_selected_index

      # Navigate past last item
      RL.stub(:is_key_pressed) do |key|
        key == RL::Key::Down
      end

      menu_system.update(0.016)

      # Should wrap to first item
      menu_system.navigator.get_selected_index.should eq(0)
    end

    it "handles selection with Enter key" do
      action_called = false

      menu_system.on_new_game = -> {
        action_called = true
      }

      # Ensure "New Game" is selected
      menu_system.navigator.navigate_to(0)

      # Simulate Enter key press
      RL.stub(:is_key_pressed) do |key|
        key == RL::Key::Enter
      end

      menu_system.update(0.016)

      action_called.should be_true
    end

    it "handles cancel with Escape key" do
      # Switch to options menu first
      menu_system.switch_to_menu("options")

      # Simulate Escape key press
      RL.stub(:is_key_pressed) do |key|
        key == RL::Key::Escape
      end

      menu_system.update(0.016)

      # Should return to main menu
      menu_system.current_menu.should eq("main")
    end
  end

  describe "mouse interaction" do
    before_each do
      menu_system.show("main")
    end

    it "detects mouse hover over menu items" do
      # Position mouse over first item
      item_bounds = menu_system.renderer.get_item_bounds(menu_system.menu_bounds, "Main Menu", 0)
      mouse_pos = RL::Vector2.new(item_bounds.x + 10, item_bounds.y + 10)

      RL.stub(:get_mouse_position) { mouse_pos }

      menu_system.update(0.016)

      # Should select the hovered item
      menu_system.navigator.get_selected_index.should eq(0)
    end

    it "handles mouse clicks on menu items" do
      action_called = false

      menu_system.on_new_game = -> {
        action_called = true
      }

      # Position mouse over "New Game" item and click
      item_bounds = menu_system.renderer.get_item_bounds(menu_system.menu_bounds, "Main Menu", 0)
      mouse_pos = RL::Vector2.new(item_bounds.x + 10, item_bounds.y + 10)

      RL.stub(:get_mouse_position) { mouse_pos }
      RL.stub(:is_mouse_button_pressed) do |button|
        button == RL::MouseButton::Left
      end

      menu_system.update(0.016)

      action_called.should be_true
    end

    it "ignores clicks on disabled items" do
      # Disable first menu item
      menu_system.set_menu_item_enabled("main", 0, false)

      action_called = false
      menu_system.on_new_game = -> {
        action_called = true
      }

      # Click on disabled item
      item_bounds = menu_system.renderer.get_item_bounds(menu_system.menu_bounds, "Main Menu", 0)
      mouse_pos = RL::Vector2.new(item_bounds.x + 10, item_bounds.y + 10)

      RL.stub(:get_mouse_position) { mouse_pos }
      RL.stub(:is_mouse_button_pressed) do |button|
        button == RL::MouseButton::Left
      end

      menu_system.update(0.016)

      action_called.should be_false
    end
  end

  describe "menu switching" do
    it "switches between menus correctly" do
      menu_system.show("main")
      menu_system.switch_to_menu("options")

      menu_system.current_menu.should eq("options")
      menu_system.navigator.total_items.should eq(menu_system.menu_items["options"].size)
    end

    it "validates menu exists before switching" do
      original_menu = menu_system.current_menu
      menu_system.switch_to_menu("nonexistent")

      menu_system.current_menu.should eq(original_menu)
    end

    it "handles main menu to options navigation" do
      menu_system.show("main")
      menu_system.navigator.navigate_to(2) # "Options" item

      # Simulate selection
      RL.stub(:is_key_pressed) do |key|
        key == RL::Key::Enter
      end

      menu_system.update(0.016)

      menu_system.current_menu.should eq("options")
    end

    it "handles back navigation from options" do
      menu_system.show("options")
      options_items = menu_system.menu_items["options"]
      back_index = options_items.index("Back") || -1
      menu_system.navigator.navigate_to(back_index)

      # Simulate selection
      RL.stub(:is_key_pressed) do |key|
        key == RL::Key::Enter
      end

      menu_system.update(0.016)

      menu_system.current_menu.should eq("main")
    end
  end

  describe "game state management" do
    it "handles in-game vs main menu context" do
      menu_system.in_game = true
      menu_system.show("options")

      # Navigate to "Back" and select it
      options_items = menu_system.menu_items["options"]
      back_index = options_items.index("Back") || -1
      menu_system.navigator.navigate_to(back_index)

      RL.stub(:is_key_pressed) do |key|
        key == RL::Key::Enter
      end

      menu_system.update(0.016)

      # Should return to pause menu when in-game
      menu_system.current_menu.should eq("pause")
    end

    it "handles pause menu resume action" do
      resume_called = false

      menu_system.on_resume = -> {
        resume_called = true
      }

      menu_system.show("pause")
      menu_system.navigator.navigate_to(0) # "Resume" item

      RL.stub(:is_key_pressed) do |key|
        key == RL::Key::Enter
      end

      menu_system.update(0.016)

      resume_called.should be_true
    end
  end

  describe "custom menu management" do
    it "adds custom menus" do
      custom_items = ["Custom Item 1", "Custom Item 2"]
      menu_system.add_menu("custom", "Custom Menu", custom_items)

      menu_system.menu_items.should have_key("custom")
      menu_system.menu_items["custom"].should eq(custom_items)
      menu_system.menu_titles["custom"].should eq("Custom Menu")
    end

    it "manages item enabled states" do
      menu_system.set_menu_item_enabled("main", 0, false)

      enabled_items = menu_system.menu_enabled_items["main"]
      enabled_items[0].should be_false
    end

    it "gets current menu item correctly" do
      menu_system.show("main")
      menu_system.navigator.navigate_to(0)

      current_item = menu_system.get_current_item
      current_item.should eq("New Game")
    end

    it "returns nil for invalid current item" do
      menu_system.navigator.set_total_items(0)

      current_item = menu_system.get_current_item
      current_item.should be_nil
    end
  end

  describe "callback system" do
    it "calls new game callback" do
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
      config_manager = menu_system.get_configuration_manager
      config_manager.should be_a(PointClickEngine::UI::ConfigurationManager)
    end

    it "applies configuration to components" do
      # Change keyboard navigation setting
      menu_system.config_manager.config.keyboard_navigation = false
      menu_system.apply_configuration

      menu_system.input_handler.keyboard_navigation_enabled.should be_false
    end

    it "validates all system components" do
      issues = menu_system.validate_system
      issues.should be_a(Array(String))
      # With default settings, should have no issues
      issues.should be_empty
    end
  end

  describe "layout management" do
    it "auto-updates layout when enabled" do
      menu_system.auto_layout = true
      original_bounds = menu_system.menu_bounds

      menu_system.show("main")

      # Layout should be updated
      menu_system.menu_bounds.should_not eq(original_bounds)
    end

    it "centers menu on screen" do
      menu_system.show("main")

      # Menu should be roughly centered (assuming 1024x768 screen)
      menu_system.menu_bounds.x.should be > 100
      menu_system.menu_bounds.x.should be < 800
      menu_system.menu_bounds.y.should be > 50
      menu_system.menu_bounds.y.should be < 600
    end

    it "calculates appropriate menu size" do
      menu_system.show("main")

      # Menu should have reasonable dimensions
      menu_system.menu_bounds.width.should be > 200
      menu_system.menu_bounds.height.should be > 150
    end
  end

  describe "edge cases and error handling" do
    it "handles empty menu gracefully" do
      menu_system.add_menu("empty", "Empty Menu", [] of String)
      menu_system.show("empty")

      # Should not crash
      menu_system.update(0.016)
      menu_system.render
    end

    it "handles navigation with all items disabled" do
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
      menu_system.current_menu = "nonexistent"

      # Should not crash when executing action
      menu_system.execute_current_action
    end

    it "handles updates when not visible" do
      menu_system.visible = false

      # Should not process input when hidden
      RL.stub(:is_key_pressed) do |key|
        key == RL::Key::Enter
      end

      menu_system.update(0.016)

      # Navigation should not change
      menu_system.navigator.get_selected_index.should eq(0)
    end
  end

  describe "component integration" do
    it "coordinates input handler with navigator" do
      menu_system.show("main")

      # Input should affect navigation
      RL.stub(:is_key_pressed) do |key|
        key == RL::Key::Down
      end

      initial_index = menu_system.navigator.get_selected_index
      menu_system.update(0.016)

      menu_system.navigator.get_selected_index.should eq(initial_index + 1)
    end

    it "coordinates renderer with navigator selection" do
      menu_system.show("main")
      menu_system.navigator.navigate_to(2)

      # Renderer should use navigator's selected index
      selected_index = menu_system.navigator.get_selected_index
      selected_index.should eq(2)
    end

    it "coordinates all components during render" do
      menu_system.show("main")

      render_calls = 0
      RL.stub(:draw_text) do |text, x, y, size, color|
        render_calls += 1
      end

      menu_system.render

      # Should have rendered menu items
      render_calls.should be > 0
    end
  end
end
