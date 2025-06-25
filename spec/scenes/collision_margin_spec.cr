require "../spec_helper"
require "../../src/scenes/scene"
require "../../src/scenes/walkable_area"

module PointClickEngine::Scenes
  describe "Collision Margin" do
    it "allows movement near edges with collision margin" do
      scene = Scene.new("test")
      walkable = WalkableArea.new

      # Create a walkable area from 0,0 to 500,500
      floor = PolygonRegion.new("floor", true)
      floor.vertices = [
        RL::Vector2.new(x: 0, y: 0),
        RL::Vector2.new(x: 500, y: 0),
        RL::Vector2.new(x: 500, y: 500),
        RL::Vector2.new(x: 0, y: 500),
      ]
      walkable.regions = [floor]
      scene.walkable_area = walkable

      # Character with size 56x56 at scale 1.5 = 84x84 effective size
      character_size = RL::Vector2.new(x: 56, y: 56)
      scale = 1.5_f32

      # Position near the edge - center at (460, 250)
      # With 84x84 size, the right edge would be at 460 + 42 = 502
      # This would normally fail (502 > 500), but with 90% margin it should pass
      center_near_edge = RL::Vector2.new(x: 460, y: 250)

      # This should pass with collision margin
      scene.is_area_walkable?(center_near_edge, character_size, scale).should be_true

      # But a position clearly outside should still fail
      center_outside = RL::Vector2.new(x: 550, y: 250)
      scene.is_area_walkable?(center_outside, character_size, scale).should be_false
    end

    it "collision margin helps with edge detection" do
      scene = Scene.new("test")
      walkable = WalkableArea.new

      # Create a walkable area
      floor = PolygonRegion.new("floor", true)
      floor.vertices = [
        RL::Vector2.new(x: 100, y: 100),
        RL::Vector2.new(x: 400, y: 100),
        RL::Vector2.new(x: 400, y: 400),
        RL::Vector2.new(x: 100, y: 400),
      ]

      walkable.regions = [floor]
      scene.walkable_area = walkable

      # Character at the boundary
      character_size = RL::Vector2.new(x: 56, y: 56)
      scale = 1.5_f32
      effective_size = 84.0_f32        # 56 * 1.5
      half_size = effective_size / 2.0 # 42

      # Position where character's edge would exactly touch the boundary
      # Center at x=142 means left edge at 142-42=100 (exactly on boundary)
      center_at_left_edge = RL::Vector2.new(x: 142, y: 250)

      # Without margin, all 9 points must be inside, which would fail
      # With 90% margin, the check points are pulled in by 10%, allowing this position
      scene.is_area_walkable?(center_at_left_edge, character_size, scale).should be_true

      # But if we go further out, it should fail
      center_outside = RL::Vector2.new(x: 135, y: 250) # Too far left
      scene.is_area_walkable?(center_outside, character_size, scale).should be_false
    end
  end
end
