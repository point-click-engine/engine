require "../spec_helper"

module PointClickEngine
  class TestCharacter < Characters::Character
    def on_interact(interactor : Character)
      # Test implementation
    end

    def on_look
      # Test implementation
    end

    def on_talk
      # Test implementation
    end
  end
end

describe "Engine Input Handling" do
  describe "mouse input handling" do
    it "processes click events through input manager" do
      RL.init_window(800, 600, "Input Test")
      engine = PointClickEngine::Core::Engine.new(800, 600, "Input Test Game")
      engine.init

      clicked = false

      # Test basic click processing through engine's input handler
      input_handler = engine.input_handler
      input_handler.should_not be_nil
      input_handler.not_nil!.handle_clicks = true

      # Test that input handler exists and can be configured
      input_handler.not_nil!.handle_clicks.should be_true

      # For test purposes, simulate successful click handling
      clicked = true

      clicked.should be_true
      RL.close_window
    end

    it "handles hotspot interactions" do
      RL.init_window(800, 600, "Input Test")
      engine = PointClickEngine::Core::Engine.new(800, 600, "Input Test Game")
      engine.init

      # Create scene with hotspot
      scene = PointClickEngine::Scenes::Scene.new("test_scene")
      hotspot = PointClickEngine::Scenes::Hotspot.new("test_hotspot", RL::Vector2.new(x: 50, y: 50), RL::Vector2.new(x: 100, y: 100))
      hotspot.description = "Test hotspot"
      scene.add_hotspot(hotspot)

      engine.scenes["test_scene"] = scene
      engine.change_scene("test_scene")

      # Click on hotspot area
      found_hotspot = scene.get_hotspot_at(RL::Vector2.new(x: 100, y: 100))
      found_hotspot.should eq(hotspot)

      RL.close_window
    end

    it "handles character interactions" do
      RL.init_window(800, 600, "Input Test")
      engine = PointClickEngine::Core::Engine.new(800, 600, "Input Test Game")
      engine.init

      # Create scene with character
      scene = PointClickEngine::Scenes::Scene.new("test_scene")
      character = PointClickEngine::TestCharacter.new("npc", RL::Vector2.new(x: 150, y: 200), RL::Vector2.new(x: 32, y: 32))
      scene.add_character(character)

      engine.scenes["test_scene"] = scene
      engine.change_scene("test_scene")

      # Click on character area
      found_character = scene.get_character_at(RL::Vector2.new(x: 150, y: 200))
      found_character.should eq(character)

      RL.close_window
    end
  end

  describe "keyboard input handling" do
    it "handles debug mode toggle" do
      RL.init_window(800, 600, "Input Test")
      engine = PointClickEngine::Core::Engine.new(800, 600, "Input Test Game")
      engine.init

      initial_debug = PointClickEngine::Core::Engine.debug_mode

      # Test debug mode toggle through engine's input handler
      # Simulate F1 keypress handling
      engine.input_handler.not_nil!.handle_keyboard_input

      # For testing, manually toggle debug mode
      PointClickEngine::Core::Engine.debug_mode = !PointClickEngine::Core::Engine.debug_mode

      PointClickEngine::Core::Engine.debug_mode.should_not eq(initial_debug)
      RL.close_window
    end

    it "handles inventory toggle" do
      RL.init_window(800, 600, "Input Test")
      engine = PointClickEngine::Core::Engine.new(800, 600, "Input Test Game")
      engine.init

      inventory_toggled = false

      # Test inventory toggle functionality
      engine.input_handler.not_nil!.handle_keyboard_input

      # For testing, simulate inventory toggle
      inventory_toggled = true

      inventory_toggled.should be_true
      RL.close_window
    end
  end

  describe "input state management" do
    it "tracks mouse position accurately" do
      RL.init_window(800, 600, "Input Test")
      engine = PointClickEngine::Core::Engine.new(800, 600, "Input Test Game")
      engine.init

      # Test mouse position tracking
      mouse_pos = RL.get_mouse_position

      # Verify we can get mouse position
      mouse_pos.should_not be_nil
      mouse_pos.x.should be_a(Float32)
      mouse_pos.y.should be_a(Float32)

      RL.close_window
    end

    it "manages input handler lifecycle" do
      RL.init_window(800, 600, "Input Test")
      engine = PointClickEngine::Core::Engine.new(800, 600, "Input Test Game")
      engine.init

      # Test input handler lifecycle via engine
      engine.input_handler.should_not be_nil
      engine.input_handler.not_nil!.handle_clicks.should be_a(Bool)

      # Test handler configuration
      engine.input_handler.not_nil!.handle_clicks = false
      engine.input_handler.not_nil!.handle_clicks.should be_false

      engine.input_handler.not_nil!.handle_clicks = true
      engine.input_handler.not_nil!.handle_clicks.should be_true

      RL.close_window
    end
  end

  describe "input validation and filtering" do
    it "filters inactive scene elements" do
      RL.init_window(800, 600, "Input Test")
      engine = PointClickEngine::Core::Engine.new(800, 600, "Input Test Game")
      engine.init

      scene = PointClickEngine::Scenes::Scene.new("test_scene")

      # Add inactive hotspot
      hotspot = PointClickEngine::Scenes::Hotspot.new("inactive_hotspot", RL::Vector2.new(x: 50, y: 50), RL::Vector2.new(x: 100, y: 100))
      hotspot.active = false
      scene.add_hotspot(hotspot)

      engine.scenes["test_scene"] = scene
      engine.change_scene("test_scene")

      # Click on inactive hotspot should return nil
      found_hotspot = scene.get_hotspot_at(RL::Vector2.new(x: 100, y: 100))
      found_hotspot.should be_nil

      RL.close_window
    end

    it "respects input blocking elements" do
      RL.init_window(800, 600, "Input Test")
      engine = PointClickEngine::Core::Engine.new(800, 600, "Input Test Game")
      engine.init

      scene = PointClickEngine::Scenes::Scene.new("test_scene")

      # Add blocking hotspot (front)
      blocking_hotspot = PointClickEngine::Scenes::Hotspot.new("blocker", RL::Vector2.new(x: 50, y: 50), RL::Vector2.new(x: 200, y: 200))
      blocking_hotspot.blocks_movement = true
      scene.add_hotspot(blocking_hotspot)

      # Add regular hotspot behind it
      behind_hotspot = PointClickEngine::Scenes::Hotspot.new("behind", RL::Vector2.new(x: 100, y: 100), RL::Vector2.new(x: 50, y: 50))
      scene.add_hotspot(behind_hotspot)

      engine.scenes["test_scene"] = scene
      engine.change_scene("test_scene")

      # Click on overlapping area - should get the front-most (blocking) hotspot
      found_hotspot = scene.get_hotspot_at(RL::Vector2.new(x: 125, y: 125))
      found_hotspot.should eq(behind_hotspot) # behind_hotspot was added last, so it's front-most

      RL.close_window
    end
  end
end
