require "../spec_helper"
require "../../src/ui/cursor_manager"
require "../../src/scenes/scene"
require "../../src/scenes/hotspot"
require "../../src/characters/character"

describe PointClickEngine::UI::CursorManager do
  it "initializes with default values" do
    cursor_manager = PointClickEngine::UI::CursorManager.new

    cursor_manager.current_verb.should eq PointClickEngine::UI::VerbType::Walk
    cursor_manager.current_hotspot.should be_nil
    cursor_manager.current_character.should be_nil
    cursor_manager.show_tooltip.should be_true
    cursor_manager.manual_verb_mode.should be_false
  end

  it "detects hotspots and sets appropriate verb" do
    cursor_manager = PointClickEngine::UI::CursorManager.new
    scene = MockScene.new

    # Create a hotspot
    hotspot = MockHotspot.new("door", RL::Vector2.new(x: 100, y: 100), RL::Vector2.new(x: 50, y: 100))
    scene.add_hotspot(hotspot)

    # Update cursor at hotspot position
    cursor_manager.update(RL::Vector2.new(x: 110, y: 110), scene)

    cursor_manager.current_hotspot.should eq hotspot
    cursor_manager.current_character.should be_nil
    # Door should default to open verb
    cursor_manager.current_verb.should eq PointClickEngine::UI::VerbType::Open
  end

  it "detects characters and sets talk verb" do
    cursor_manager = PointClickEngine::UI::CursorManager.new
    scene = MockScene.new

    # Create a character
    character = MockCharacter.new("butler", RL::Vector2.new(x: 200, y: 200))
    scene.add_character(character)

    # Update cursor at character position
    cursor_manager.update(RL::Vector2.new(x: 200, y: 200), scene)

    cursor_manager.current_hotspot.should be_nil
    cursor_manager.current_character.should eq character
    cursor_manager.current_verb.should eq PointClickEngine::UI::VerbType::Talk
  end

  it "prioritizes hotspots over characters" do
    cursor_manager = PointClickEngine::UI::CursorManager.new
    scene = MockScene.new

    # Create overlapping hotspot and character
    hotspot = MockHotspot.new("desk", RL::Vector2.new(x: 150, y: 150), RL::Vector2.new(x: 100, y: 100))
    character = MockCharacter.new("butler", RL::Vector2.new(x: 200, y: 200))
    scene.add_hotspot(hotspot)
    scene.add_character(character)

    # Update cursor at overlapping position
    cursor_manager.update(RL::Vector2.new(x: 200, y: 200), scene)

    # Hotspot should take priority
    cursor_manager.current_hotspot.should eq hotspot
    cursor_manager.current_character.should be_nil
  end

  it "defaults to walk verb on empty background" do
    cursor_manager = PointClickEngine::UI::CursorManager.new
    scene = MockScene.new

    # Update cursor at empty position
    cursor_manager.update(RL::Vector2.new(x: 500, y: 500), scene)

    cursor_manager.current_hotspot.should be_nil
    cursor_manager.current_character.should be_nil
    cursor_manager.current_verb.should eq PointClickEngine::UI::VerbType::Walk
  end

  it "maintains manual verb mode" do
    cursor_manager = PointClickEngine::UI::CursorManager.new
    scene = MockScene.new

    # Set manual verb
    cursor_manager.set_verb(PointClickEngine::UI::VerbType::Look)
    cursor_manager.manual_verb_mode.should be_true

    # Create a door hotspot
    hotspot = MockHotspot.new("door", RL::Vector2.new(x: 100, y: 100), RL::Vector2.new(x: 50, y: 100))
    scene.add_hotspot(hotspot)

    # Update cursor - should keep Look verb
    cursor_manager.update(RL::Vector2.new(x: 110, y: 110), scene)

    cursor_manager.current_verb.should eq PointClickEngine::UI::VerbType::Look
    cursor_manager.manual_verb_mode.should be_true
  end

  it "cycles through verbs correctly" do
    cursor_manager = PointClickEngine::UI::CursorManager.new

    initial_verb = cursor_manager.current_verb

    # Cycle forward
    cursor_manager.cycle_verb_forward
    cursor_manager.current_verb.should_not eq initial_verb
    cursor_manager.manual_verb_mode.should be_true

    # Cycle backward
    cursor_manager.cycle_verb_backward
    cursor_manager.current_verb.should eq initial_verb
  end

  it "resets manual mode" do
    cursor_manager = PointClickEngine::UI::CursorManager.new

    cursor_manager.set_verb(PointClickEngine::UI::VerbType::Look)
    cursor_manager.manual_verb_mode.should be_true

    cursor_manager.reset_manual_mode
    cursor_manager.manual_verb_mode.should be_false
  end

  it "determines correct verb for hotspot names" do
    cursor_manager = PointClickEngine::UI::CursorManager.new
    scene = MockScene.new

    # Test various hotspot types
    test_cases = [
      {"butler", PointClickEngine::UI::VerbType::Talk},
      {"door", PointClickEngine::UI::VerbType::Open},
      {"key", PointClickEngine::UI::VerbType::Take},
      {"chest", PointClickEngine::UI::VerbType::Open},
      {"painting", PointClickEngine::UI::VerbType::Look},
    ]

    test_cases.each do |name, expected_verb|
      hotspot = MockHotspot.new(name, RL::Vector2.new(x: 100, y: 100), RL::Vector2.new(x: 50, y: 50))
      scene.hotspots.clear
      scene.add_hotspot(hotspot)

      cursor_manager.update(RL::Vector2.new(x: 110, y: 110), scene)
      cursor_manager.current_verb.should eq expected_verb
    end
  end
end

# Mock classes for testing
class MockScene < PointClickEngine::Scenes::Scene
  def initialize
    super("test_scene")
  end

  def get_hotspot_at(pos : RL::Vector2) : PointClickEngine::Scenes::Hotspot?
    @hotspots.find { |hotspot| hotspot.contains_point?(pos) }
  end

  def get_character_at(pos : RL::Vector2) : PointClickEngine::Characters::Character?
    @characters.find { |character|
      character.active && character.visible && character.contains_point?(pos) && character != @player
    }
  end
end

class MockHotspot < PointClickEngine::Scenes::Hotspot
  def initialize(name : String, position : RL::Vector2, size : RL::Vector2)
    super(name, position, size)
    @description = "A #{name}"
    @active = true
    @visible = true
  end
end

class MockCharacter < PointClickEngine::Characters::Character
  def initialize(name : String, position : RL::Vector2)
    super()
    @name = name
    @position = position
    @size = RL::Vector2.new(x: 50, y: 100)
    @active = true
    @visible = true
  end

  def contains_point?(point : RL::Vector2) : Bool
    # Simple rectangular bounds check for character
    point.x >= @position.x - @size.x / 2 &&
      point.x <= @position.x + @size.x / 2 &&
      point.y >= @position.y - @size.y &&
      point.y <= @position.y
  end

  def update(dt : Float32)
    # Mock update
  end

  def draw
    # Mock draw
  end

  def on_interact(interactor : PointClickEngine::Characters::Character)
    # Mock interaction
  end

  def on_look
    # Mock look
  end

  def on_talk
    # Mock talk
  end

  def on_use
    # Mock use
  end
end
