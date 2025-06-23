require "../spec_helper"
require "../../src/ui/cursor_manager"
require "../../src/ui/status_bar"
require "../../src/scenes/scene"
require "../../src/scenes/hotspot"
require "../../src/characters/character"

describe "Tooltip System" do
  describe "CursorManager tooltip display" do
    it "tracks hotspot for tooltip display" do
      cursor_manager = PointClickEngine::UI::CursorManager.new
      scene = MockScene.new

      # Create a bookshelf hotspot
      hotspot = MockHotspot.new("bookshelf", RL::Vector2.new(x: 100, y: 100), RL::Vector2.new(x: 150, y: 300))
      scene.add_hotspot(hotspot)

      # Update cursor at hotspot
      cursor_manager.update(RL::Vector2.new(x: 120, y: 150), scene)

      # Verify hotspot is tracked for tooltip
      cursor_manager.current_hotspot.should eq hotspot
      cursor_manager.current_hotspot.not_nil!.name.should eq "bookshelf"
    end

    it "tracks character for tooltip display" do
      cursor_manager = PointClickEngine::UI::CursorManager.new
      scene = MockScene.new

      # Create a butler character
      character = MockCharacter.new("butler", RL::Vector2.new(x: 300, y: 450))
      scene.add_character(character)

      # Update cursor at character
      cursor_manager.update(RL::Vector2.new(x: 300, y: 450), scene)

      # Verify character is tracked for tooltip
      cursor_manager.current_character.should eq character
      cursor_manager.current_character.not_nil!.name.should eq "butler"
    end

    it "clears tracking when cursor moves away" do
      cursor_manager = PointClickEngine::UI::CursorManager.new
      scene = MockScene.new

      # Create hotspot and character
      hotspot = MockHotspot.new("door", RL::Vector2.new(x: 100, y: 100), RL::Vector2.new(x: 50, y: 100))
      character = MockCharacter.new("guard", RL::Vector2.new(x: 300, y: 300))
      scene.add_hotspot(hotspot)
      scene.add_character(character)

      # First hover over hotspot
      cursor_manager.update(RL::Vector2.new(x: 110, y: 110), scene)
      cursor_manager.current_hotspot.should_not be_nil
      cursor_manager.current_character.should be_nil

      # Move to empty space
      cursor_manager.update(RL::Vector2.new(x: 500, y: 500), scene)
      cursor_manager.current_hotspot.should be_nil
      cursor_manager.current_character.should be_nil

      # Move to character
      cursor_manager.update(RL::Vector2.new(x: 300, y: 300), scene)
      cursor_manager.current_hotspot.should be_nil
      cursor_manager.current_character.should_not be_nil
    end

    it "tooltip can be disabled" do
      cursor_manager = PointClickEngine::UI::CursorManager.new

      cursor_manager.show_tooltip.should be_true

      # Disable tooltips
      cursor_manager.show_tooltip = false
      cursor_manager.show_tooltip.should be_false
    end
  end

  describe "StatusBar integration" do
    it "displays hotspot name in status bar" do
      cursor_manager = PointClickEngine::UI::CursorManager.new
      status_bar = PointClickEngine::UI::StatusBar.new(1024, 768)
      scene = MockScene.new

      # Create a desk hotspot
      hotspot = MockHotspot.new("desk", RL::Vector2.new(x: 400, y: 400), RL::Vector2.new(x: 200, y: 150))
      scene.add_hotspot(hotspot)

      # Update cursor at hotspot
      cursor_manager.update(RL::Vector2.new(x: 450, y: 450), scene)

      # Update status bar
      status_bar.update(cursor_manager)

      status_bar.current_object.should eq "desk"
      status_bar.current_verb.should eq PointClickEngine::UI::VerbType::Open
    end

    it "displays character name in status bar" do
      cursor_manager = PointClickEngine::UI::CursorManager.new
      status_bar = PointClickEngine::UI::StatusBar.new(1024, 768)
      scene = MockScene.new

      # Create a scientist character
      character = MockCharacter.new("scientist", RL::Vector2.new(x: 400, y: 400))
      scene.add_character(character)

      # Update cursor at character
      cursor_manager.update(RL::Vector2.new(x: 400, y: 400), scene)

      # Update status bar
      status_bar.update(cursor_manager)

      status_bar.current_object.should eq "scientist"
      status_bar.current_verb.should eq PointClickEngine::UI::VerbType::Talk
    end

    it "clears object name when hovering over background" do
      cursor_manager = PointClickEngine::UI::CursorManager.new
      status_bar = PointClickEngine::UI::StatusBar.new(1024, 768)
      scene = MockScene.new

      # Update cursor at empty position
      cursor_manager.update(RL::Vector2.new(x: 600, y: 600), scene)

      # Update status bar
      status_bar.update(cursor_manager)

      status_bar.current_object.should eq ""
      status_bar.current_verb.should eq PointClickEngine::UI::VerbType::Walk
    end
  end

  describe "Tooltip text generation" do
    it "generates correct tooltip text for hotspots" do
      cursor_manager = PointClickEngine::UI::CursorManager.new
      scene = MockScene.new

      # Test various hotspot verbs
      test_cases = [
        {"bookshelf", "Look", "Look bookshelf"},
        {"door", "Open", "Open door"},
        {"mysterious crystal", "Take", "Take mysterious crystal"},
      ]

      test_cases.each do |name, verb_name, expected_text|
        hotspot = MockHotspot.new(name, RL::Vector2.new(x: 100, y: 100), RL::Vector2.new(x: 50, y: 50))
        scene.hotspots.clear
        scene.add_hotspot(hotspot)

        cursor_manager.update(RL::Vector2.new(x: 110, y: 110), scene)

        # Construct expected tooltip text
        verb_text = cursor_manager.current_verb.to_s.capitalize
        object_text = cursor_manager.current_hotspot.not_nil!.name
        tooltip_text = "#{verb_text} #{object_text}"

        tooltip_text.should eq expected_text
      end
    end

    it "generates correct tooltip text for characters" do
      cursor_manager = PointClickEngine::UI::CursorManager.new
      scene = MockScene.new

      # Create characters
      characters = ["butler", "scientist", "mysterious stranger"]

      characters.each do |name|
        character = MockCharacter.new(name, RL::Vector2.new(x: 200, y: 200))
        scene.characters.clear
        scene.add_character(character)

        cursor_manager.update(RL::Vector2.new(x: 200, y: 200), scene)

        # Verify talk verb is set for characters
        cursor_manager.current_verb.should eq PointClickEngine::UI::VerbType::Talk

        # Construct expected tooltip text
        verb_text = cursor_manager.current_verb.to_s.capitalize
        object_text = cursor_manager.current_character.not_nil!.name
        tooltip_text = "#{verb_text} #{object_text}"

        tooltip_text.should eq "Talk #{name}"
      end
    end
  end
end

# Mock classes (reuse from cursor_manager_spec.cr)
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
