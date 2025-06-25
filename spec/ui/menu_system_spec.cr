require "../spec_helper"

describe PointClickEngine::UI::MenuSystem do
  describe "initialization" do
    it "creates all menu types" do
      engine = PointClickEngine::Core::Engine.new(800, 600, "Test")
      menu_system = PointClickEngine::UI::MenuSystem.new(engine)

      menu_system.main_menu.should_not be_nil
      menu_system.pause_menu.should_not be_nil
      menu_system.options_menu.should_not be_nil
      menu_system.save_menu.should_not be_nil
      menu_system.load_menu.should_not be_nil
    end
  end

  describe "#show_main_menu" do
    it "shows the main menu and sets current menu" do
      engine = PointClickEngine::Core::Engine.new(800, 600, "Test")
      menu_system = PointClickEngine::UI::MenuSystem.new(engine)

      menu_system.show_main_menu

      menu_system.current_menu.should eq(menu_system.main_menu)
      menu_system.main_menu.visible.should be_true
    end
  end

  describe "#toggle_pause_menu" do
    it "shows pause menu when in game" do
      engine = PointClickEngine::Core::Engine.new(800, 600, "Test")
      menu_system = PointClickEngine::UI::MenuSystem.new(engine)

      menu_system.enter_game
      menu_system.toggle_pause_menu

      menu_system.current_menu.should eq(menu_system.pause_menu)
      menu_system.game_paused.should be_true
    end

    it "hides pause menu when already visible" do
      engine = PointClickEngine::Core::Engine.new(800, 600, "Test")
      menu_system = PointClickEngine::UI::MenuSystem.new(engine)

      menu_system.enter_game
      menu_system.show_pause_menu
      menu_system.toggle_pause_menu

      menu_system.current_menu.should be_nil
      menu_system.game_paused.should be_false
    end
  end
end

describe PointClickEngine::UI::BaseMenu do
  describe "menu functionality" do
    it "starts with first item selected" do
      menu = PointClickEngine::UI::MainMenu.new(
        RL::Vector2.new(x: 100, y: 100),
        RL::Vector2.new(x: 400, y: 500)
      )

      menu.show
      menu.selected_index.should eq(0)
    end

    it "highlights selected item" do
      menu = PointClickEngine::UI::MainMenu.new(
        RL::Vector2.new(x: 100, y: 100),
        RL::Vector2.new(x: 400, y: 500)
      )

      menu.show
      menu.items[0].highlighted.should be_true
      menu.items[1].highlighted.should be_false
    end

    it "can show and hide" do
      menu = PointClickEngine::UI::MainMenu.new(
        RL::Vector2.new(x: 100, y: 100),
        RL::Vector2.new(x: 400, y: 500)
      )

      menu.visible.should be_false
      menu.show
      menu.visible.should be_true
      menu.hide
      menu.visible.should be_false
    end
  end

  describe "#add_item" do
    it "adds menu items with callbacks" do
      menu = PointClickEngine::UI::MainMenu.new(
        RL::Vector2.new(x: 100, y: 100),
        RL::Vector2.new(x: 400, y: 500)
      )

      called = false
      menu.add_item("Test") { called = true }

      menu.items.last.text.should eq("Test")
      menu.items.last.action.not_nil!.call
      called.should be_true
    end
  end
end

describe PointClickEngine::UI::OptionsMenu do
  it "updates volume controls" do
    engine = PointClickEngine::Core::Engine.new(800, 600, "Test")
    engine.init

    menu = PointClickEngine::UI::OptionsMenu.new(
      RL::Vector2.new(x: 100, y: 100),
      RL::Vector2.new(x: 400, y: 500),
      engine
    )

    # Should have volume controls
    menu.items[0].text.includes?("Master Volume:").should be_true
    menu.items[1].text.should eq("Volume -")
    menu.items[2].text.should eq("Volume +")
  end

  it "toggles debug mode" do
    engine = PointClickEngine::Core::Engine.new(800, 600, "Test")
    engine.init

    menu = PointClickEngine::UI::OptionsMenu.new(
      RL::Vector2.new(x: 100, y: 100),
      RL::Vector2.new(x: 400, y: 500),
      engine
    )

    initial_debug = PointClickEngine::Core::Engine.debug_mode

    # Find and activate debug toggle
    debug_item = menu.items.find { |item| item.text.includes?("Debug Mode") }
    debug_item.not_nil!.action.not_nil!.call

    PointClickEngine::Core::Engine.debug_mode.should eq(!initial_debug)
  end
end

describe PointClickEngine::UI::SaveLoadMenu do
  describe "save mode" do
    it "shows all save slots" do
      menu = PointClickEngine::UI::SaveLoadMenu.new(
        RL::Vector2.new(x: 100, y: 100),
        RL::Vector2.new(x: 400, y: 500),
        true # Save mode
      )

      menu.refresh_slots

      # Should have 5 slots + quick save + back
      menu.items.size.should eq(7)
      menu.items[0].text.includes?("Slot 1").should be_true
      menu.items[5].text.should eq("Quick Save")
      menu.items[6].text.should eq("Back")
    end
  end

  describe "load mode" do
    it "only shows existing saves" do
      menu = PointClickEngine::UI::SaveLoadMenu.new(
        RL::Vector2.new(x: 100, y: 100),
        RL::Vector2.new(x: 400, y: 500),
        false # Load mode
      )

      menu.refresh_slots

      # Without any saves, should only show "No saved games" + Back
      if menu.items.first.text == "No saved games found"
        menu.items.size.should eq(2)
        menu.items.first.enabled.should be_false
      end
    end
  end
end
