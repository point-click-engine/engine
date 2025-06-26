require "../spec_helper"
require "../../src/ui/menu_input_handler"

describe PointClickEngine::UI::MenuInputHandler do
  describe "initialization" do
    it "initializes with default settings" do
      handler = PointClickEngine::UI::MenuInputHandler.new
      handler = PointClickEngine::UI::MenuInputHandler.new
      handler.keyboard_navigation_enabled.should be_true
      handler = PointClickEngine::UI::MenuInputHandler.new
      handler.mouse_navigation_enabled.should be_true
      handler = PointClickEngine::UI::MenuInputHandler.new
      handler.input_repeat_enabled.should be_true
      handler = PointClickEngine::UI::MenuInputHandler.new
      handler.input_repeat_delay.should eq(0.15)
    end

    it "starts with zero mouse position" do
      handler = PointClickEngine::UI::MenuInputHandler.new
      handler = PointClickEngine::UI::MenuInputHandler.new
      handler.mouse_position.x.should eq(0)
      handler = PointClickEngine::UI::MenuInputHandler.new
      handler.mouse_position.y.should eq(0)
    end
  end

  describe "input configuration" do
    it "enables and disables keyboard navigation" do
      handler = PointClickEngine::UI::MenuInputHandler.new
      handler = PointClickEngine::UI::MenuInputHandler.new
      handler.set_keyboard_navigation(false)
      handler = PointClickEngine::UI::MenuInputHandler.new
      handler.keyboard_navigation_enabled.should be_false

      handler = PointClickEngine::UI::MenuInputHandler.new
      handler.set_keyboard_navigation(true)
      handler = PointClickEngine::UI::MenuInputHandler.new
      handler.keyboard_navigation_enabled.should be_true
    end

    it "enables and disables mouse navigation" do
      handler = PointClickEngine::UI::MenuInputHandler.new
      handler = PointClickEngine::UI::MenuInputHandler.new
      handler.set_mouse_navigation(false)
      handler = PointClickEngine::UI::MenuInputHandler.new
      handler.mouse_navigation_enabled.should be_false

      handler = PointClickEngine::UI::MenuInputHandler.new
      handler.set_mouse_navigation(true)
      handler = PointClickEngine::UI::MenuInputHandler.new
      handler.mouse_navigation_enabled.should be_true
    end

    it "sets input repeat delay" do
      handler = PointClickEngine::UI::MenuInputHandler.new
      handler = PointClickEngine::UI::MenuInputHandler.new
      handler.set_input_repeat_delay(0.25)
      handler = PointClickEngine::UI::MenuInputHandler.new
      handler.input_repeat_delay.should eq(0.25)
    end

    it "enables and disables input repeat" do
      handler = PointClickEngine::UI::MenuInputHandler.new
      handler = PointClickEngine::UI::MenuInputHandler.new
      handler.set_input_repeat(false)
      handler = PointClickEngine::UI::MenuInputHandler.new
      handler.input_repeat_enabled.should be_false

      handler = PointClickEngine::UI::MenuInputHandler.new
      handler.set_input_repeat(true)
      handler = PointClickEngine::UI::MenuInputHandler.new
      handler.input_repeat_enabled.should be_true
    end
  end

  # Commented out - requires mocking library
  # describe "input processing" do
  #   before_each do
  #     # Mock Raylib input functions
  #     RL.stub(:get_mouse_position) { RL::Vector2.new(100, 200) }
  #   end
  #
  #   it "processes mouse position updates" do
  #     action = handler.process_input(0.016)
  #
  #     handler = PointClickEngine::UI::MenuInputHandler.new
  #     handler.mouse_position.x.should eq(100)
  #     handler = PointClickEngine::UI::MenuInputHandler.new
  #     handler.mouse_position.y.should eq(200)
  #   end
  #
  #   it "returns MouseHover action when mouse navigation enabled" do
  #     RL.stub(:is_mouse_button_pressed) { false }
  #     RL.stub(:is_key_pressed) { false }
  #
  #     action = handler.process_input(0.016)
  #     action.should eq(PointClickEngine::UI::MenuInputHandler::InputAction::MouseHover)
  #   end
  #
  #   it "returns MouseClick action when mouse clicked" do
  #     RL.stub(:is_mouse_button_pressed) do |button|
  #       button == RL::MouseButton::Left
  #     end
  #     RL.stub(:is_key_pressed) { false }
  #
  #     action = handler.process_input(0.016)
  #     action.should eq(PointClickEngine::UI::MenuInputHandler::InputAction::MouseClick)
  #   end
  #
  #   it "returns None when all navigation disabled" do
  #     handler = PointClickEngine::UI::MenuInputHandler.new
  #     handler.set_keyboard_navigation(false)
  #     handler = PointClickEngine::UI::MenuInputHandler.new
  #     handler.set_mouse_navigation(false)
  #
  #     action = handler.process_input(0.016)
  #     action.should eq(PointClickEngine::UI::MenuInputHandler::InputAction::None)
  #   end
  # end

  # Commented out - requires mocking library
  # describe "keyboard input processing" do
  #   before_each do
  #     RL.stub(:get_mouse_position) { RL::Vector2.new(0, 0) }
  #     RL.stub(:is_mouse_button_pressed) { false }
  #   end
  #
  #   it "detects up navigation keys" do
  #     RL.stub(:is_key_pressed) do |key|
  #       key == RL::Key::Up
  #     end
  #
  #     action = handler.process_input(0.016)
  #     action.should eq(PointClickEngine::UI::MenuInputHandler::InputAction::NavigateUp)
  #   end
  #
  #   it "detects down navigation keys" do
  #     RL.stub(:is_key_pressed) do |key|
  #       key == RL::Key::Down
  #     end
  #
  #     action = handler.process_input(0.016)
  #     action.should eq(PointClickEngine::UI::MenuInputHandler::InputAction::NavigateDown)
  #   end
  #
  #   it "detects left navigation keys" do
  #     RL.stub(:is_key_pressed) do |key|
  #       key == RL::Key::Left
  #     end
  #
  #     action = handler.process_input(0.016)
  #     action.should eq(PointClickEngine::UI::MenuInputHandler::InputAction::NavigateLeft)
  #   end
  #
  #   it "detects right navigation keys" do
  #     RL.stub(:is_key_pressed) do |key|
  #       key == RL::Key::Right
  #     end
  #
  #     action = handler.process_input(0.016)
  #     action.should eq(PointClickEngine::UI::MenuInputHandler::InputAction::NavigateRight)
  #   end
  #
  #   it "detects WASD navigation keys" do
  #     RL.stub(:is_key_pressed) do |key|
  #       key == RL::Key::W
  #     end
  #
  #     action = handler.process_input(0.016)
  #     action.should eq(PointClickEngine::UI::MenuInputHandler::InputAction::NavigateUp)
  #   end
  #
  #   it "detects select action keys" do
  #     RL.stub(:is_key_pressed) do |key|
  #       key == RL::Key::Enter
  #     end
  #
  #     action = handler.process_input(0.016)
  #     action.should eq(PointClickEngine::UI::MenuInputHandler::InputAction::Select)
  #   end
  #
  #   it "detects cancel action key" do
  #     RL.stub(:is_key_pressed) do |key|
  #       key == RL::Key::Escape
  #     end
  #
  #     action = handler.process_input(0.016)
  #     action.should eq(PointClickEngine::UI::MenuInputHandler::InputAction::Cancel)
  #   end
  # end

  # Commented out - requires mocking library
  # describe "input repeat handling" do
  #   it "respects input repeat delay" do
  #     RL.stub(:get_mouse_position) { RL::Vector2.new(0, 0) }
  #     RL.stub(:is_mouse_button_pressed) { false }
  #     RL.stub(:is_key_pressed) do |key|
  #       key == RL::Key::Down
  #     end
  #
  #     # First input should work
  #     action1 = handler.process_input(0.016)
  #     action1.should eq(PointClickEngine::UI::MenuInputHandler::InputAction::NavigateDown)
  #
  #     # Second input within delay should be ignored
  #     action2 = handler.process_input(0.016)
  #     action2.should eq(PointClickEngine::UI::MenuInputHandler::InputAction::MouseHover)
  #   end
  #
  #   it "allows input after delay period" do
  #     handler = PointClickEngine::UI::MenuInputHandler.new
  #     handler.set_input_repeat_delay(0.1)
  #
  #     RL.stub(:get_mouse_position) { RL::Vector2.new(0, 0) }
  #     RL.stub(:is_mouse_button_pressed) { false }
  #     RL.stub(:is_key_pressed) do |key|
  #       key == RL::Key::Down
  #     end
  #
  #     # Process first input
  #     handler = PointClickEngine::UI::MenuInputHandler.new
  #     handler.process_input(0.016)
  #
  #     # Process input after delay
  #     handler = PointClickEngine::UI::MenuInputHandler.new
  #     handler.process_input(0.2) # Total time > delay
  #     # Would need to simulate time passage for proper testing
  #   end
  #
  #   it "disables repeat when configured" do
  #     handler = PointClickEngine::UI::MenuInputHandler.new
  #     handler.set_input_repeat(false)
  #
  #     RL.stub(:get_mouse_position) { RL::Vector2.new(0, 0) }
  #     RL.stub(:is_mouse_button_pressed) { false }
  #     RL.stub(:is_key_pressed) do |key|
  #       key == RL::Key::Down
  #     end
  #
  #     # Both inputs should work when repeat is disabled
  #     action1 = handler.process_input(0.016)
  #     action1.should eq(PointClickEngine::UI::MenuInputHandler::InputAction::NavigateDown)
  #
  #     action2 = handler.process_input(0.016)
  #     action2.should eq(PointClickEngine::UI::MenuInputHandler::InputAction::NavigateDown)
  #   end
  # end

  describe "mouse interaction" do
    it "detects mouse over item" do
      handler = PointClickEngine::UI::MenuInputHandler.new
      handler.mouse_position = RL::Vector2.new(150, 115)
      item_bounds = RL::Rectangle.new(x: 50, y: 100, width: 200, height: 30)

      handler.mouse_over_item?(item_bounds).should be_true
    end

    it "detects mouse outside item" do
      handler = PointClickEngine::UI::MenuInputHandler.new
      handler.mouse_position = RL::Vector2.new(300, 115)
      item_bounds = RL::Rectangle.new(x: 50, y: 100, width: 200, height: 30)

      handler.mouse_over_item?(item_bounds).should be_false
    end

    # Commented out - requires mocking library
    # it "processes item interaction with click" do
    #   handler = PointClickEngine::UI::MenuInputHandler.new
    #   handler.mouse_position = RL::Vector2.new(150, 115)
    #
    #   RL.stub(:is_mouse_button_pressed) do |button|
    #     button == RL::MouseButton::Left
    #   end
    #
    #   clicked = handler.process_item_interaction(0, item_bounds, true)
    #   clicked.should be_true
    # end
    #
    # it "ignores interaction with disabled items" do
    #   handler = PointClickEngine::UI::MenuInputHandler.new
    #   handler.mouse_position = RL::Vector2.new(150, 115)
    #
    #   RL.stub(:is_mouse_button_pressed) do |button|
    #     button == RL::MouseButton::Left
    #   end
    #
    #   clicked = handler.process_item_interaction(0, item_bounds, false)
    #   clicked.should be_false
    # end

    it "checks point in rectangle correctly" do
      rect = RL::Rectangle.new(x: 10, y: 20, width: 100, height: 50)

      # Point inside
      handler = PointClickEngine::UI::MenuInputHandler.new
      handler.point_in_rect?(RL::Vector2.new(50, 40), rect).should be_true

      # Point outside
      handler = PointClickEngine::UI::MenuInputHandler.new
      handler.point_in_rect?(RL::Vector2.new(150, 40), rect).should be_false

      # Point on edge
      handler = PointClickEngine::UI::MenuInputHandler.new
      handler.point_in_rect?(RL::Vector2.new(10, 20), rect).should be_true
      handler = PointClickEngine::UI::MenuInputHandler.new
      handler.point_in_rect?(RL::Vector2.new(110, 70), rect).should be_true
    end
  end

  # Commented out - requires mocking library
  # describe "callback handling" do
  #   it "calls navigation callback" do
  #     navigation_action = nil.as(PointClickEngine::UI::MenuInputHandler::InputAction?)
  #
  #     handler = PointClickEngine::UI::MenuInputHandler.new
  #     handler.on_navigation do |action|
  #       navigation_action = action
  #     end
  #
  #     # Trigger navigation
  #     RL.stub(:get_mouse_position) { RL::Vector2.new(0, 0) }
  #     RL.stub(:is_mouse_button_pressed) { false }
  #     RL.stub(:is_key_pressed) do |key|
  #       key == RL::Key::Up
  #     end
  #
  #     handler = PointClickEngine::UI::MenuInputHandler.new
  #     handler.process_input(0.016)
  #     navigation_action.should eq(PointClickEngine::UI::MenuInputHandler::InputAction::NavigateUp)
  #   end
  #
  #   it "calls selection callback" do
  #     selected_index = -1
  #
  #     handler = PointClickEngine::UI::MenuInputHandler.new
  #     handler.on_selection do |index|
  #       selected_index = index
  #     end
  #
  #     # Trigger selection via item interaction
  #     handler = PointClickEngine::UI::MenuInputHandler.new
  #     handler.mouse_position = RL::Vector2.new(150, 115)
  #     item_bounds = RL::Rectangle.new(x: 50, y: 100, width: 200, height: 30)
  #
  #     RL.stub(:is_mouse_button_pressed) do |button|
  #       button == RL::MouseButton::Left
  #     end
  #
  #     handler = PointClickEngine::UI::MenuInputHandler.new
  #     handler.process_item_interaction(5, item_bounds, true)
  #     selected_index.should eq(5)
  #   end
  #
  #   it "calls cancel callback" do
  #     cancel_called = false
  #
  #     handler = PointClickEngine::UI::MenuInputHandler.new
  #     handler.on_cancellation do
  #       cancel_called = true
  #     end
  #
  #     # Trigger cancel
  #     RL.stub(:get_mouse_position) { RL::Vector2.new(0, 0) }
  #     RL.stub(:is_mouse_button_pressed) { false }
  #     RL.stub(:is_key_pressed) do |key|
  #       key == RL::Key::Escape
  #     end
  #
  #     handler = PointClickEngine::UI::MenuInputHandler.new
  #     handler.process_input(0.016)
  #     cancel_called.should be_true
  #   end
  #
  #   it "calls hover callback" do
  #     hovered_index = -1
  #
  #     handler = PointClickEngine::UI::MenuInputHandler.new
  #     handler.on_hover do |index|
  #       hovered_index = index
  #     end
  #
  #     # Trigger hover via item interaction
  #     handler = PointClickEngine::UI::MenuInputHandler.new
  #     handler.mouse_position = RL::Vector2.new(150, 115)
  #     item_bounds = RL::Rectangle.new(x: 50, y: 100, width: 200, height: 30)
  #
  #     RL.stub(:is_mouse_button_pressed) { false }
  #
  #     handler = PointClickEngine::UI::MenuInputHandler.new
  #     handler.process_item_interaction(3, item_bounds, true)
  #     hovered_index.should eq(3)
  #   end
  # end

  # Commented out - requires mocking library
  # describe "key state checking" do
  #   it "detects navigation keys held" do
  #     RL.stub(:is_key_down) do |key|
  #       key == RL::Key::Up
  #     end
  #
  #     handler = PointClickEngine::UI::MenuInputHandler.new
  #     handler.navigation_key_held?.should be_true
  #   end
  #
  #   it "detects no navigation keys held" do
  #     RL.stub(:is_key_down) { false }
  #
  #     handler = PointClickEngine::UI::MenuInputHandler.new
  #     handler.navigation_key_held?.should be_false
  #   end
  #
  #   it "detects action keys held" do
  #     RL.stub(:is_key_down) do |key|
  #       key == RL::Key::Enter
  #     end
  #
  #     handler = PointClickEngine::UI::MenuInputHandler.new
  #     handler.action_key_held?.should be_true
  #   end
  #
  #   it "detects no action keys held" do
  #     RL.stub(:is_key_down) { false }
  #
  #     handler = PointClickEngine::UI::MenuInputHandler.new
  #     handler.action_key_held?.should be_false
  #   end
  # end

  describe "state management" do
    it "resets input state" do
      handler = PointClickEngine::UI::MenuInputHandler.new
      handler.last_input_time = 123.45
      handler = PointClickEngine::UI::MenuInputHandler.new
      handler.mouse_position = RL::Vector2.new(300, 400)

      handler = PointClickEngine::UI::MenuInputHandler.new
      handler.reset_input_state

      handler = PointClickEngine::UI::MenuInputHandler.new
      handler.last_input_time.should eq(0.0)
      handler = PointClickEngine::UI::MenuInputHandler.new
      handler.mouse_position.x.should eq(0)
      handler = PointClickEngine::UI::MenuInputHandler.new
      handler.mouse_position.y.should eq(0)
    end

    it "updates from settings" do
      settings = {
        "input_repeat_delay"  => "0.25",
        "keyboard_navigation" => "false",
        "mouse_navigation"    => "true",
      }

      handler = PointClickEngine::UI::MenuInputHandler.new
      handler.update_from_settings(settings)

      handler = PointClickEngine::UI::MenuInputHandler.new
      handler.input_repeat_delay.should eq(0.25)
      handler = PointClickEngine::UI::MenuInputHandler.new
      handler.keyboard_navigation_enabled.should be_false
      handler = PointClickEngine::UI::MenuInputHandler.new
      handler.mouse_navigation_enabled.should be_true
    end

    it "provides input statistics" do
      handler = PointClickEngine::UI::MenuInputHandler.new
      stats = handler.get_input_stats

      stats["keyboard_enabled"].should be_true
      stats["mouse_enabled"].should be_true
      stats["repeat_enabled"].should be_true
      stats["repeat_delay"].should eq(0.15)
    end

    it "validates configuration" do
      handler = PointClickEngine::UI::MenuInputHandler.new
      issues = handler.validate_configuration
      issues.should be_empty
      handler.set_input_repeat_delay(-0.1)
      issues = handler.validate_configuration
      issues.should_not be_empty
      issues.first.should contain("negative")
    end
  end

  describe "edge cases" do
    it "handles very short repeat delays" do
      handler = PointClickEngine::UI::MenuInputHandler.new
      handler.set_input_repeat_delay(0.001)
      handler = PointClickEngine::UI::MenuInputHandler.new
      handler.input_repeat_delay.should eq(0.001)
    end

    it "handles very long repeat delays" do
      handler = PointClickEngine::UI::MenuInputHandler.new
      handler.set_input_repeat_delay(5.0)
      issues = handler.validate_configuration
      issues.any? { |issue| issue.includes?("high") }.should be_true
    end

    it "handles all input disabled" do
      handler = PointClickEngine::UI::MenuInputHandler.new
      handler.set_keyboard_navigation(false)
      handler = PointClickEngine::UI::MenuInputHandler.new
      handler.set_mouse_navigation(false)

      issues = handler.validate_configuration
      issues.any? { |issue| issue.includes?("disabled") }.should be_true
    end
  end
end
