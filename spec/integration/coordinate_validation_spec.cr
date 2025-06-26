require "../spec_helper"

describe "Coordinate validation integration" do
  it "validates scene coordinates against logical dimensions" do
    # This is an integration test that verifies the coordinate validation
    # works correctly with actual scene files

    # Test scene with logical dimensions
    scene = PointClickEngine::Scenes::Scene.new("test")
    scene.logical_width = 800
    scene.logical_height = 600

    # Create walkable area
    walkable_area = PointClickEngine::Scenes::WalkableArea.new
    region = PointClickEngine::Scenes::PolygonRegion.new("test_region", true)
    region.vertices = [
      RL::Vector2.new(x: 100, y: 100),
      RL::Vector2.new(x: 700, y: 100),
      RL::Vector2.new(x: 700, y: 500),
      RL::Vector2.new(x: 100, y: 500),
    ]
    walkable_area.regions << region
    walkable_area.update_bounds
    scene.walkable_area = walkable_area

    # Test that coordinates are properly validated
    # Point inside logical bounds and walkable area
    scene.is_walkable?(RL::Vector2.new(x: 400, y: 300)).should be_true

    # Point outside logical bounds
    scene.is_walkable?(RL::Vector2.new(x: 900, y: 300)).should be_false

    # Point inside logical bounds but outside walkable area
    scene.is_walkable?(RL::Vector2.new(x: 50, y: 50)).should be_false
  end

  it "ensures navigation grid respects logical dimensions" do
    scene = PointClickEngine::Scenes::Scene.new("test")
    scene.logical_width = 1024
    scene.logical_height = 768

    # Create walkable area that spans the entire logical space
    walkable_area = PointClickEngine::Scenes::WalkableArea.new
    region = PointClickEngine::Scenes::PolygonRegion.new("floor", true)
    region.vertices = [
      RL::Vector2.new(x: 0, y: 0),
      RL::Vector2.new(x: 1024, y: 0),
      RL::Vector2.new(x: 1024, y: 768),
      RL::Vector2.new(x: 0, y: 768),
    ]
    walkable_area.regions << region
    walkable_area.update_bounds
    scene.walkable_area = walkable_area

    # Generate navigation grid using logical dimensions
    grid = PointClickEngine::Navigation::NavigationGrid.from_scene(
      scene, scene.logical_width, scene.logical_height, 32
    )

    # Grid should cover the logical dimensions
    expected_width = (1024 / 32) + 1 # 33
    expected_height = (768 / 32) + 1 # 25

    grid.width.should eq(expected_width)
    grid.height.should eq(expected_height)

    # Center cell should be walkable
    center_x, center_y = grid.world_to_grid(512, 384)
    grid.is_walkable?(center_x, center_y).should be_true
  end

  it "maintains coordinate independence from texture size" do
    scene = PointClickEngine::Scenes::Scene.new("test")

    # Set logical dimensions different from typical texture sizes
    scene.logical_width = 1920
    scene.logical_height = 1080

    # Add a hotspot using logical coordinates
    hotspot = PointClickEngine::Scenes::Hotspot.new(
      "test_hotspot",
      RL::Vector2.new(x: 1000, y: 600), # Center
      RL::Vector2.new(x: 200, y: 100)   # Size
    )
    scene.hotspots << hotspot

    # Hotspot bounds should use logical coordinates
    bounds = hotspot.bounds
    bounds.x.should eq(900) # 1000 - 200/2
    bounds.y.should eq(550) # 600 - 100/2
    bounds.width.should eq(200)
    bounds.height.should eq(100)

    # Test point inside hotspot
    scene.get_hotspot_at(RL::Vector2.new(x: 1000, y: 600)).should eq(hotspot)

    # Test point outside hotspot but within logical bounds
    scene.get_hotspot_at(RL::Vector2.new(x: 500, y: 500)).should be_nil
  end
end
