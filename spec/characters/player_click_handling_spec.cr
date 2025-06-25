require "../spec_helper"
require "../../src/characters/player"
require "../../src/scenes/scene"
require "../../src/scenes/walkable_area"

describe PointClickEngine::Characters::Player do
  describe "#handle_click" do
    it "moves to walkable positions directly" do
      player = PointClickEngine::Characters::Player.new("TestPlayer", RL::Vector2.new(100, 100), RL::Vector2.new(56, 56))
      scene = PointClickEngine::Scenes::Scene.new("test_scene")
      scene.logical_width = 1024
      scene.logical_height = 768

      # Create walkable area
      walkable_area = PointClickEngine::Scenes::WalkableArea.new
      region = PointClickEngine::Scenes::PolygonRegion.new("main", true)
      region.vertices = [
        RL::Vector2.new(0, 0),
        RL::Vector2.new(1024, 0),
        RL::Vector2.new(1024, 768),
        RL::Vector2.new(0, 768),
      ]
      walkable_area.regions = [region]
      scene.walkable_area = walkable_area

      # Click on walkable position
      target = RL::Vector2.new(500, 500)
      player.handle_click(target, scene)

      # Player should be walking to the target
      player.state.should eq(PointClickEngine::Characters::CharacterState::Walking)
    end

    it "finds nearest walkable point when clicking on non-walkable area" do
      player = PointClickEngine::Characters::Player.new("TestPlayer", RL::Vector2.new(100, 400), RL::Vector2.new(56, 56))
      scene = PointClickEngine::Scenes::Scene.new("test_scene")
      scene.logical_width = 1024
      scene.logical_height = 768

      # Create walkable area with non-walkable obstacle
      walkable_area = PointClickEngine::Scenes::WalkableArea.new
      main_region = PointClickEngine::Scenes::PolygonRegion.new("main", true)
      main_region.vertices = [
        RL::Vector2.new(0, 350),
        RL::Vector2.new(1024, 350),
        RL::Vector2.new(1024, 768),
        RL::Vector2.new(0, 768),
      ]

      obstacle_region = PointClickEngine::Scenes::PolygonRegion.new("obstacle", false)
      obstacle_region.vertices = [
        RL::Vector2.new(400, 400),
        RL::Vector2.new(600, 400),
        RL::Vector2.new(600, 600),
        RL::Vector2.new(400, 600),
      ]

      walkable_area.regions = [main_region, obstacle_region]
      scene.walkable_area = walkable_area

      # Click on non-walkable position (above walkable area)
      target = RL::Vector2.new(500, 200) # Y=200 is above the walkable area (Y >= 350)
      player.handle_click(target, scene)

      # Player should be walking (to nearest walkable point)
      player.state.should eq(PointClickEngine::Characters::CharacterState::Walking)
    end

    it "does not move when clicking on current position" do
      player = PointClickEngine::Characters::Player.new("TestPlayer", RL::Vector2.new(100, 400), RL::Vector2.new(56, 56))
      scene = PointClickEngine::Scenes::Scene.new("test_scene")
      scene.logical_width = 1024
      scene.logical_height = 768

      # Create walkable area
      walkable_area = PointClickEngine::Scenes::WalkableArea.new
      region = PointClickEngine::Scenes::PolygonRegion.new("main", true)
      region.vertices = [
        RL::Vector2.new(0, 0),
        RL::Vector2.new(1024, 0),
        RL::Vector2.new(1024, 768),
        RL::Vector2.new(0, 768),
      ]
      walkable_area.regions = [region]
      scene.walkable_area = walkable_area

      # Click very close to current position
      target = RL::Vector2.new(100.5, 400.5)
      initial_state = player.state
      player.handle_click(target, scene)

      # Player should not have changed state
      player.state.should eq(initial_state)
    end

    it "respects movement_enabled flag" do
      player = PointClickEngine::Characters::Player.new("TestPlayer", RL::Vector2.new(100, 400), RL::Vector2.new(56, 56))
      player.movement_enabled = false
      scene = PointClickEngine::Scenes::Scene.new("test_scene")
      scene.logical_width = 1024
      scene.logical_height = 768

      # Create walkable area
      walkable_area = PointClickEngine::Scenes::WalkableArea.new
      region = PointClickEngine::Scenes::PolygonRegion.new("main", true)
      region.vertices = [
        RL::Vector2.new(0, 0),
        RL::Vector2.new(1024, 0),
        RL::Vector2.new(1024, 768),
        RL::Vector2.new(0, 768),
      ]
      walkable_area.regions = [region]
      scene.walkable_area = walkable_area

      # Try to click somewhere
      target = RL::Vector2.new(500, 500)
      initial_state = player.state
      player.handle_click(target, scene)

      # Player should not have moved
      player.state.should eq(initial_state)
    end
  end
end
