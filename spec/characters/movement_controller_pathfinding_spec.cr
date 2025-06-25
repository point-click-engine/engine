require "../spec_helper"
require "../../src/characters/movement_controller"
require "../../src/characters/character"
require "../../src/scenes/scene"
require "../../src/scenes/walkable_area"
require "../../src/navigation/pathfinding"
require "../../src/core/engine"

# Test character implementation
class TestCharacterWithPath < PointClickEngine::Characters::Character
  property test_path : Array(RL::Vector2)?

  def on_interact(interactor : PointClickEngine::Characters::Character)
  end

  def on_look
  end

  def on_talk
  end
end

# Mock scene that can provide custom pathfinding results
class MockSceneWithPath < PointClickEngine::Scenes::Scene
  property mock_path : Array(RL::Vector2)?

  def find_path(from_x : Float32, from_y : Float32, to_x : Float32, to_y : Float32) : Array(RL::Vector2)?
    @mock_path
  end
end

describe PointClickEngine::Characters::MovementController do
  describe "immediate pathfinding behavior" do
    it "uses pathfinding immediately when enabled" do
      # Create test character
      character = TestCharacterWithPath.new("TestChar", RL::Vector2.new(100, 100), RL::Vector2.new(32, 32))
      character.use_pathfinding = true
      controller = PointClickEngine::Characters::MovementController.new(character)

      # Create mock scene with pathfinding
      scene = MockSceneWithPath.new("test_scene")
      scene.logical_width = 800
      scene.logical_height = 600

      # Set up expected path
      scene.mock_path = [
        RL::Vector2.new(100, 100),
        RL::Vector2.new(200, 100),
        RL::Vector2.new(300, 200),
        RL::Vector2.new(400, 300),
      ]

      # Mock the engine to return our scene
      engine = PointClickEngine::Core::Engine.instance
      engine.current_scene = scene

      # Move with pathfinding enabled
      target = RL::Vector2.new(400, 300)
      controller.move_to(target, use_pathfinding: true)

      # Should be following the path
      controller.following_path?.should be_true
      controller.path.should eq(scene.mock_path)
      character.state.should eq(PointClickEngine::Characters::CharacterState::Walking)

      # Clean up
      engine.current_scene = nil
    end

    it "falls back to direct movement when no path is found" do
      # Create test character
      character = TestCharacterWithPath.new("TestChar", RL::Vector2.new(100, 100), RL::Vector2.new(32, 32))
      character.use_pathfinding = true
      controller = PointClickEngine::Characters::MovementController.new(character)

      # Create mock scene that returns no path
      scene = MockSceneWithPath.new("test_scene")
      scene.mock_path = nil

      # Mock the engine
      engine = PointClickEngine::Core::Engine.instance
      engine.current_scene = scene

      # Move with pathfinding enabled but no path available
      target = RL::Vector2.new(400, 300)
      controller.move_to(target, use_pathfinding: true)

      # Should fall back to direct movement
      controller.following_path?.should be_false
      controller.target_position.should eq(target)
      character.state.should eq(PointClickEngine::Characters::CharacterState::Walking)

      # Clean up
      engine.current_scene = nil
    end

    it "uses direct movement when pathfinding is explicitly disabled" do
      # Create test character
      character = TestCharacterWithPath.new("TestChar", RL::Vector2.new(100, 100), RL::Vector2.new(32, 32))
      character.use_pathfinding = true # Character defaults to pathfinding
      controller = PointClickEngine::Characters::MovementController.new(character)

      # Create mock scene with a path available
      scene = MockSceneWithPath.new("test_scene")
      scene.mock_path = [
        RL::Vector2.new(100, 100),
        RL::Vector2.new(400, 300),
      ]

      # Mock the engine
      engine = PointClickEngine::Core::Engine.instance
      engine.current_scene = scene

      # Move with pathfinding explicitly disabled
      target = RL::Vector2.new(400, 300)
      controller.move_to(target, use_pathfinding: false)

      # Should use direct movement despite path being available
      controller.following_path?.should be_false
      controller.target_position.should eq(target)
      character.state.should eq(PointClickEngine::Characters::CharacterState::Walking)

      # Clean up
      engine.current_scene = nil
    end

    it "respects character's default pathfinding preference when not specified" do
      # Create test character with pathfinding enabled by default
      character = TestCharacterWithPath.new("TestChar", RL::Vector2.new(100, 100), RL::Vector2.new(32, 32))
      character.use_pathfinding = true
      controller = PointClickEngine::Characters::MovementController.new(character)

      # Create mock scene with a path
      scene = MockSceneWithPath.new("test_scene")
      scene.mock_path = [
        RL::Vector2.new(100, 100),
        RL::Vector2.new(200, 200),
        RL::Vector2.new(400, 300),
      ]

      # Mock the engine
      engine = PointClickEngine::Core::Engine.instance
      engine.current_scene = scene

      # Move without specifying pathfinding preference
      target = RL::Vector2.new(400, 300)
      controller.move_to(target)

      # Should use pathfinding based on character's preference
      controller.following_path?.should be_true
      controller.path.should eq(scene.mock_path)

      # Clean up
      engine.current_scene = nil
    end

    it "handles no scene gracefully" do
      # Create test character
      character = TestCharacterWithPath.new("TestChar", RL::Vector2.new(100, 100), RL::Vector2.new(32, 32))
      character.use_pathfinding = true
      controller = PointClickEngine::Characters::MovementController.new(character)

      # Clear the engine's scene
      engine = PointClickEngine::Core::Engine.instance
      engine.current_scene = nil

      # Move with pathfinding enabled but no scene
      target = RL::Vector2.new(400, 300)
      controller.move_to(target, use_pathfinding: true)

      # Should fall back to direct movement
      controller.following_path?.should be_false
      controller.target_position.should eq(target)
      character.state.should eq(PointClickEngine::Characters::CharacterState::Walking)
    end
  end

  # Skip tests that require Engine.instance for now
  # These tests need a proper Engine mock setup
  pending "pathfinding integration" do
    it "automatically uses pathfinding when direct movement is blocked" do
      # Create scene with obstacle
      scene = PointClickEngine::Scenes::Scene.new("test")
      walkable_area = PointClickEngine::Scenes::WalkableArea.new

      # Floor
      floor = PointClickEngine::Scenes::PolygonRegion.new("floor", true)
      floor.vertices = [
        RL::Vector2.new(x: 0, y: 0),
        RL::Vector2.new(x: 800, y: 0),
        RL::Vector2.new(x: 800, y: 600),
        RL::Vector2.new(x: 0, y: 600),
      ]

      # Wall blocking direct path
      wall = PointClickEngine::Scenes::PolygonRegion.new("wall", false)
      wall.vertices = [
        RL::Vector2.new(x: 350, y: 200),
        RL::Vector2.new(x: 450, y: 200),
        RL::Vector2.new(x: 450, y: 400),
        RL::Vector2.new(x: 350, y: 400),
      ]

      walkable_area.regions << floor
      walkable_area.regions << wall
      walkable_area.update_bounds
      scene.walkable_area = walkable_area
      scene.enable_pathfinding = true

      # Setup navigation grid with mock texture
      texture = RL::Texture2D.new
      texture.width = 800
      texture.height = 600
      scene.background = texture
      scene.setup_navigation

      # Create character
      character = PointClickEngine::Characters::Player.new(
        "TestPlayer",
        RL::Vector2.new(x: 200, y: 300),
        RL::Vector2.new(x: 64, y: 64)
      )
      character.use_pathfinding = true

      controller = PointClickEngine::Characters::MovementController.new(character)
      character.movement_controller = controller

      # No need to mock engine - using singleton instance

      # Try to move to other side of wall
      target = RL::Vector2.new(x: 600, y: 300)
      controller.move_to(target)

      # Should be following a path, not direct movement
      controller.following_path?.should be_true
      controller.moving?.should be_true
    end

    it "recalculates path when encountering unexpected obstacles" do
      scene = PointClickEngine::Scenes::Scene.new("test")
      walkable_area = PointClickEngine::Scenes::WalkableArea.new

      # Simple floor
      floor = PointClickEngine::Scenes::PolygonRegion.new("floor", true)
      floor.vertices = [
        RL::Vector2.new(x: 0, y: 0),
        RL::Vector2.new(x: 800, y: 0),
        RL::Vector2.new(x: 800, y: 600),
        RL::Vector2.new(x: 0, y: 600),
      ]

      # Small obstacle
      obstacle = PointClickEngine::Scenes::PolygonRegion.new("obstacle", false)
      obstacle.vertices = [
        RL::Vector2.new(x: 380, y: 280),
        RL::Vector2.new(x: 420, y: 280),
        RL::Vector2.new(x: 420, y: 320),
        RL::Vector2.new(x: 380, y: 320),
      ]

      walkable_area.regions << floor
      walkable_area.regions << obstacle
      walkable_area.update_bounds
      scene.walkable_area = walkable_area
      scene.enable_pathfinding = true

      # Setup navigation
      scene.background = RL::Texture2D.new(width: 800, height: 600)
      scene.setup_navigation

      # Character with size that won't fit through tight spaces
      character = PointClickEngine::Characters::Player.new(
        "TestPlayer",
        RL::Vector2.new(x: 300, y: 300),
        RL::Vector2.new(x: 60, y: 60)
      )
      character.use_pathfinding = true

      controller = PointClickEngine::Characters::MovementController.new(character)
      character.movement_controller = controller

      # No need to mock engine - using singleton instance

      # Move character close to obstacle
      character.position = RL::Vector2.new(x: 340, y: 300)

      # Try to move through obstacle (should trigger pathfinding)
      target = RL::Vector2.new(x: 500, y: 300)
      controller.move_to(target)

      # Update once to trigger collision detection
      controller.update(0.016f32)

      # Should now be following a path
      controller.following_path?.should be_true
    end

    it "stops movement if no path can be found" do
      scene = PointClickEngine::Scenes::Scene.new("test")
      walkable_area = PointClickEngine::Scenes::WalkableArea.new

      # Two disconnected areas
      area1 = PointClickEngine::Scenes::PolygonRegion.new("area1", true)
      area1.vertices = [
        RL::Vector2.new(x: 0, y: 0),
        RL::Vector2.new(x: 300, y: 0),
        RL::Vector2.new(x: 300, y: 600),
        RL::Vector2.new(x: 0, y: 600),
      ]

      area2 = PointClickEngine::Scenes::PolygonRegion.new("area2", true)
      area2.vertices = [
        RL::Vector2.new(x: 500, y: 0),
        RL::Vector2.new(x: 800, y: 0),
        RL::Vector2.new(x: 800, y: 600),
        RL::Vector2.new(x: 500, y: 600),
      ]

      walkable_area.regions << area1
      walkable_area.regions << area2
      walkable_area.update_bounds
      scene.walkable_area = walkable_area
      scene.enable_pathfinding = true

      scene.background = RL::Texture2D.new(width: 800, height: 600)
      scene.setup_navigation

      character = PointClickEngine::Characters::Player.new(
        "TestPlayer",
        RL::Vector2.new(x: 150, y: 300),
        RL::Vector2.new(x: 64, y: 64)
      )
      character.use_pathfinding = true

      controller = PointClickEngine::Characters::MovementController.new(character)
      character.movement_controller = controller

      # No need to mock engine - using singleton instance

      # Try to move to unreachable area
      target = RL::Vector2.new(x: 650, y: 300)
      controller.move_to(target)

      # Should not be moving (no valid path)
      controller.moving?.should be_false
      character.state.should eq(PointClickEngine::Characters::CharacterState::Idle)
    end

    it "respects character size in pathfinding" do
      scene = PointClickEngine::Scenes::Scene.new("test")
      walkable_area = PointClickEngine::Scenes::WalkableArea.new

      # Floor with narrow passage
      floor = PointClickEngine::Scenes::PolygonRegion.new("floor", true)
      floor.vertices = [
        RL::Vector2.new(x: 0, y: 0),
        RL::Vector2.new(x: 800, y: 0),
        RL::Vector2.new(x: 800, y: 600),
        RL::Vector2.new(x: 0, y: 600),
      ]

      # Two obstacles creating narrow passage
      obstacle1 = PointClickEngine::Scenes::PolygonRegion.new("obstacle1", false)
      obstacle1.vertices = [
        RL::Vector2.new(x: 300, y: 0),
        RL::Vector2.new(x: 400, y: 0),
        RL::Vector2.new(x: 400, y: 280),
        RL::Vector2.new(x: 300, y: 280),
      ]

      obstacle2 = PointClickEngine::Scenes::PolygonRegion.new("obstacle2", false)
      obstacle2.vertices = [
        RL::Vector2.new(x: 300, y: 320),
        RL::Vector2.new(x: 400, y: 320),
        RL::Vector2.new(x: 400, y: 600),
        RL::Vector2.new(x: 300, y: 600),
      ]

      walkable_area.regions << floor
      walkable_area.regions << obstacle1
      walkable_area.regions << obstacle2
      walkable_area.update_bounds
      scene.walkable_area = walkable_area
      scene.enable_pathfinding = true

      scene.background = RL::Texture2D.new(width: 800, height: 600)
      scene.setup_navigation

      # Large character that won't fit through passage
      character = PointClickEngine::Characters::Player.new(
        "TestPlayer",
        RL::Vector2.new(x: 100, y: 300),
        RL::Vector2.new(x: 100, y: 100) # Too large for 40-pixel gap
      )
      character.use_pathfinding = true

      controller = PointClickEngine::Characters::MovementController.new(character)
      character.movement_controller = controller

      # No need to mock engine - using singleton instance

      # Try to move to other side
      target = RL::Vector2.new(x: 700, y: 300)
      controller.move_to(target)

      # Should not find a path through the narrow gap
      controller.moving?.should be_false
    end
  end

  # These tests don't require Engine.instance
  describe "collision detection with character bounds" do
    it "uses full character bounds for collision, not just center point" do
      scene = PointClickEngine::Scenes::Scene.new("test")
      walkable_area = PointClickEngine::Scenes::WalkableArea.new

      # Floor with edge
      floor = PointClickEngine::Scenes::PolygonRegion.new("floor", true)
      floor.vertices = [
        RL::Vector2.new(x: 100, y: 100),
        RL::Vector2.new(x: 700, y: 100),
        RL::Vector2.new(x: 700, y: 500),
        RL::Vector2.new(x: 100, y: 500),
      ]

      walkable_area.regions << floor
      walkable_area.update_bounds
      scene.walkable_area = walkable_area

      # Character near edge
      character = PointClickEngine::Characters::Player.new(
        "TestPlayer",
        RL::Vector2.new(x: 110, y: 300), # Center is inside floor
        RL::Vector2.new(x: 50, y: 50)
      )

      controller = PointClickEngine::Characters::MovementController.new(character)
      character.movement_controller = controller

      # No need to mock engine - using singleton instance

      # Try to move left (would put character partially off floor)
      new_pos = RL::Vector2.new(x: 90, y: 300)

      # The movement should be blocked
      can_move = scene.is_area_walkable?(new_pos, character.size, character.scale)
      can_move.should be_false
    end

    it "accounts for character scale in collision detection" do
      scene = PointClickEngine::Scenes::Scene.new("test")
      walkable_area = PointClickEngine::Scenes::WalkableArea.new

      # Small walkable area
      floor = PointClickEngine::Scenes::PolygonRegion.new("floor", true)
      floor.vertices = [
        RL::Vector2.new(x: 200, y: 200),
        RL::Vector2.new(x: 600, y: 200),
        RL::Vector2.new(x: 600, y: 400),
        RL::Vector2.new(x: 200, y: 400),
      ]

      walkable_area.regions << floor
      walkable_area.update_bounds
      scene.walkable_area = walkable_area

      center_pos = RL::Vector2.new(x: 400, y: 300)
      char_size = RL::Vector2.new(x: 50, y: 50)

      # Scale 1.0 should fit
      scene.is_area_walkable?(center_pos, char_size, 1.0).should be_true

      # Scale 5.0 makes character too large for the area
      scene.is_area_walkable?(center_pos, char_size, 5.0).should be_false
    end
  end
end
