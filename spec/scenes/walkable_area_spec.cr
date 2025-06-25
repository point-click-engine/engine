require "../spec_helper"

describe PointClickEngine::Scenes::WalkableArea do
  it "initializes with empty regions" do
    area = PointClickEngine::Scenes::WalkableArea.new

    area.regions.should be_empty
    area.walk_behind_regions.should be_empty
    area.scale_zones.should be_empty
  end

  describe "#is_point_walkable?" do
    it "returns true when no regions defined" do
      area = PointClickEngine::Scenes::WalkableArea.new
      point = RL::Vector2.new(x: 100f32, y: 100f32)

      area.is_point_walkable?(point).should be_true
    end

    it "checks walkable regions correctly" do
      area = PointClickEngine::Scenes::WalkableArea.new

      # Create a walkable square region
      walkable = PointClickEngine::Scenes::PolygonRegion.new("floor", true)
      walkable.vertices = [
        RL::Vector2.new(x: 0f32, y: 0f32),
        RL::Vector2.new(x: 100f32, y: 0f32),
        RL::Vector2.new(x: 100f32, y: 100f32),
        RL::Vector2.new(x: 0f32, y: 100f32),
      ]
      area.regions << walkable

      # Points inside should be walkable
      area.is_point_walkable?(RL::Vector2.new(x: 50f32, y: 50f32)).should be_true
      area.is_point_walkable?(RL::Vector2.new(x: 10f32, y: 10f32)).should be_true
      area.is_point_walkable?(RL::Vector2.new(x: 90f32, y: 90f32)).should be_true

      # Points outside should not be walkable
      area.is_point_walkable?(RL::Vector2.new(x: 150f32, y: 50f32)).should be_false
      area.is_point_walkable?(RL::Vector2.new(x: -10f32, y: 50f32)).should be_false
    end

    it "handles non-walkable regions as obstacles" do
      area = PointClickEngine::Scenes::WalkableArea.new

      # Create a walkable floor
      floor = PointClickEngine::Scenes::PolygonRegion.new("floor", true)
      floor.vertices = [
        RL::Vector2.new(x: 0f32, y: 0f32),
        RL::Vector2.new(x: 200f32, y: 0f32),
        RL::Vector2.new(x: 200f32, y: 200f32),
        RL::Vector2.new(x: 0f32, y: 200f32),
      ]
      area.regions << floor

      # Add an obstacle in the middle
      obstacle = PointClickEngine::Scenes::PolygonRegion.new("table", false)
      obstacle.vertices = [
        RL::Vector2.new(x: 50f32, y: 50f32),
        RL::Vector2.new(x: 150f32, y: 50f32),
        RL::Vector2.new(x: 150f32, y: 150f32),
        RL::Vector2.new(x: 50f32, y: 150f32),
      ]
      area.regions << obstacle

      # Floor area should be walkable
      area.is_point_walkable?(RL::Vector2.new(x: 10f32, y: 10f32)).should be_true
      area.is_point_walkable?(RL::Vector2.new(x: 190f32, y: 190f32)).should be_true

      # Obstacle area should not be walkable
      area.is_point_walkable?(RL::Vector2.new(x: 100f32, y: 100f32)).should be_false
      area.is_point_walkable?(RL::Vector2.new(x: 60f32, y: 60f32)).should be_false
    end

    it "gives non-walkable regions precedence over walkable ones" do
      area = PointClickEngine::Scenes::WalkableArea.new

      # Create overlapping regions
      walkable = PointClickEngine::Scenes::PolygonRegion.new("floor", true)
      walkable.vertices = [
        RL::Vector2.new(x: 0f32, y: 0f32),
        RL::Vector2.new(x: 100f32, y: 0f32),
        RL::Vector2.new(x: 100f32, y: 100f32),
        RL::Vector2.new(x: 0f32, y: 100f32),
      ]

      non_walkable = PointClickEngine::Scenes::PolygonRegion.new("wall", false)
      non_walkable.vertices = [
        RL::Vector2.new(x: 50f32, y: 0f32),
        RL::Vector2.new(x: 150f32, y: 0f32),
        RL::Vector2.new(x: 150f32, y: 100f32),
        RL::Vector2.new(x: 50f32, y: 100f32),
      ]

      area.regions << walkable
      area.regions << non_walkable

      # Overlapping area should be non-walkable
      area.is_point_walkable?(RL::Vector2.new(x: 75f32, y: 50f32)).should be_false

      # Non-overlapping walkable area should still be walkable
      area.is_point_walkable?(RL::Vector2.new(x: 25f32, y: 50f32)).should be_true
    end
  end

  describe "#get_scale_at_y" do
    it "returns 1.0 when no scale zones defined" do
      area = PointClickEngine::Scenes::WalkableArea.new
      area.get_scale_at_y(100f32).should eq(1.0f32)
    end

    it "calculates scale within a zone" do
      area = PointClickEngine::Scenes::WalkableArea.new

      # Add scale zone from y=100 to y=300
      zone = PointClickEngine::Scenes::ScaleZone.new(100f32, 300f32, 0.5f32, 1.0f32)
      area.scale_zones << zone

      # At minimum Y
      area.get_scale_at_y(100f32).should eq(0.5f32)

      # At maximum Y
      area.get_scale_at_y(300f32).should eq(1.0f32)

      # At middle (linear interpolation)
      area.get_scale_at_y(200f32).should eq(0.75f32)

      # Outside zone
      area.get_scale_at_y(50f32).should eq(1.0f32)
      area.get_scale_at_y(350f32).should eq(1.0f32)
    end

    it "handles multiple scale zones" do
      area = PointClickEngine::Scenes::WalkableArea.new

      # Add two zones
      zone1 = PointClickEngine::Scenes::ScaleZone.new(0f32, 100f32, 0.3f32, 0.5f32)
      zone2 = PointClickEngine::Scenes::ScaleZone.new(200f32, 300f32, 0.8f32, 1.0f32)

      area.scale_zones << zone1
      area.scale_zones << zone2

      # First zone
      area.get_scale_at_y(50f32).should eq(0.4f32)

      # Between zones (default)
      area.get_scale_at_y(150f32).should eq(1.0f32)

      # Second zone
      area.get_scale_at_y(250f32).should eq(0.9f32)
    end
  end

  describe "#get_walk_behind_at_y" do
    it "returns empty array when no walk-behind regions" do
      area = PointClickEngine::Scenes::WalkableArea.new
      area.get_walk_behind_at_y(100f32).should be_empty
    end

    it "returns regions based on Y threshold" do
      area = PointClickEngine::Scenes::WalkableArea.new

      # Create walk-behind regions
      region1 = PointClickEngine::Scenes::WalkBehindRegion.new("pillar1", 100f32)
      region2 = PointClickEngine::Scenes::WalkBehindRegion.new("pillar2", 200f32)
      region3 = PointClickEngine::Scenes::WalkBehindRegion.new("pillar3", 300f32)

      area.walk_behind_regions << region1
      area.walk_behind_regions << region2
      area.walk_behind_regions << region3

      # Y=50: Character is above all thresholds, no regions
      area.get_walk_behind_at_y(50f32).should be_empty

      # Y=150: Character is below first threshold
      behind = area.get_walk_behind_at_y(150f32)
      behind.size.should eq(1)
      behind.first.name.should eq("pillar1")

      # Y=250: Character is below first two thresholds
      behind = area.get_walk_behind_at_y(250f32)
      behind.size.should eq(2)
      behind.map(&.name).should contain("pillar1")
      behind.map(&.name).should contain("pillar2")

      # Y=350: Character is below all thresholds
      behind = area.get_walk_behind_at_y(350f32)
      behind.size.should eq(3)
    end
  end

  describe "#constrain_to_walkable" do
    it "returns destination if walkable" do
      area = PointClickEngine::Scenes::WalkableArea.new

      # Create walkable region
      walkable = PointClickEngine::Scenes::PolygonRegion.new("floor", true)
      walkable.vertices = [
        RL::Vector2.new(x: 0f32, y: 0f32),
        RL::Vector2.new(x: 200f32, y: 0f32),
        RL::Vector2.new(x: 200f32, y: 200f32),
        RL::Vector2.new(x: 0f32, y: 200f32),
      ]
      area.regions << walkable

      from = RL::Vector2.new(x: 50f32, y: 50f32)
      to = RL::Vector2.new(x: 150f32, y: 150f32)

      result = area.constrain_to_walkable(from, to)
      result.should eq(to)
    end

    it "finds closest walkable point along path" do
      area = PointClickEngine::Scenes::WalkableArea.new

      # Create walkable region with limited area
      walkable = PointClickEngine::Scenes::PolygonRegion.new("floor", true)
      walkable.vertices = [
        RL::Vector2.new(x: 0f32, y: 0f32),
        RL::Vector2.new(x: 100f32, y: 0f32),
        RL::Vector2.new(x: 100f32, y: 100f32),
        RL::Vector2.new(x: 0f32, y: 100f32),
      ]
      area.regions << walkable

      from = RL::Vector2.new(x: 50f32, y: 50f32)
      to = RL::Vector2.new(x: 200f32, y: 200f32) # Outside walkable area

      result = area.constrain_to_walkable(from, to)

      # Result should be somewhere between from and to
      result.x.should be >= from.x
      result.x.should be <= to.x
      result.y.should be >= from.y
      result.y.should be <= to.y

      # Result should be walkable
      area.is_point_walkable?(result).should be_true
    end

    it "returns start position if no walkable path exists" do
      area = PointClickEngine::Scenes::WalkableArea.new

      # Create small walkable region
      walkable = PointClickEngine::Scenes::PolygonRegion.new("island", true)
      walkable.vertices = [
        RL::Vector2.new(x: 0f32, y: 0f32),
        RL::Vector2.new(x: 50f32, y: 0f32),
        RL::Vector2.new(x: 50f32, y: 50f32),
        RL::Vector2.new(x: 0f32, y: 50f32),
      ]
      area.regions << walkable

      from = RL::Vector2.new(x: 25f32, y: 25f32)
      to = RL::Vector2.new(x: 200f32, y: 200f32) # Far outside

      result = area.constrain_to_walkable(from, to)

      # Should not reach destination
      result.should_not eq(to)

      # Should still be walkable
      area.is_point_walkable?(result).should be_true
    end
  end

  describe "#update_bounds" do
    it "calculates bounds from all regions" do
      area = PointClickEngine::Scenes::WalkableArea.new

      # Add regions
      region1 = PointClickEngine::Scenes::PolygonRegion.new("r1", true)
      region1.vertices = [
        RL::Vector2.new(x: 0f32, y: 0f32),
        RL::Vector2.new(x: 100f32, y: 0f32),
        RL::Vector2.new(x: 100f32, y: 100f32),
        RL::Vector2.new(x: 0f32, y: 100f32),
      ]

      region2 = PointClickEngine::Scenes::PolygonRegion.new("r2", true)
      region2.vertices = [
        RL::Vector2.new(x: 50f32, y: 50f32),
        RL::Vector2.new(x: 200f32, y: 50f32),
        RL::Vector2.new(x: 200f32, y: 150f32),
        RL::Vector2.new(x: 50f32, y: 150f32),
      ]

      area.regions << region1
      area.regions << region2

      area.update_bounds

      bounds = area.bounds
      bounds.x.should eq(0f32)
      bounds.y.should eq(0f32)
      bounds.width.should eq(200f32)
      bounds.height.should eq(150f32)
    end

    it "handles empty regions" do
      area = PointClickEngine::Scenes::WalkableArea.new
      area.update_bounds # Should not crash

      bounds = area.bounds
      bounds.width.should eq(0f32)
      bounds.height.should eq(0f32)
    end
  end
end

describe PointClickEngine::Scenes::PolygonRegion do
  it "initializes with name and walkable state" do
    region = PointClickEngine::Scenes::PolygonRegion.new("test", true)

    region.name.should eq("test")
    region.walkable.should be_true
    region.vertices.should be_empty
  end

  describe "#contains_point?" do
    it "returns false for regions with less than 3 vertices" do
      region = PointClickEngine::Scenes::PolygonRegion.new
      point = RL::Vector2.new(x: 50f32, y: 50f32)

      # No vertices
      region.contains_point?(point).should be_false

      # One vertex
      region.vertices << RL::Vector2.new(x: 0f32, y: 0f32)
      region.contains_point?(point).should be_false

      # Two vertices
      region.vertices << RL::Vector2.new(x: 100f32, y: 0f32)
      region.contains_point?(point).should be_false
    end

    it "correctly detects points inside triangle" do
      region = PointClickEngine::Scenes::PolygonRegion.new
      region.vertices = [
        RL::Vector2.new(x: 0f32, y: 0f32),
        RL::Vector2.new(x: 100f32, y: 0f32),
        RL::Vector2.new(x: 50f32, y: 100f32),
      ]

      # Inside
      region.contains_point?(RL::Vector2.new(x: 50f32, y: 30f32)).should be_true

      # Outside
      region.contains_point?(RL::Vector2.new(x: 0f32, y: 50f32)).should be_false
      region.contains_point?(RL::Vector2.new(x: 100f32, y: 50f32)).should be_false
    end

    it "correctly detects points inside rectangle" do
      region = PointClickEngine::Scenes::PolygonRegion.new
      region.vertices = [
        RL::Vector2.new(x: 10f32, y: 10f32),
        RL::Vector2.new(x: 90f32, y: 10f32),
        RL::Vector2.new(x: 90f32, y: 90f32),
        RL::Vector2.new(x: 10f32, y: 90f32),
      ]

      # Inside corners
      region.contains_point?(RL::Vector2.new(x: 15f32, y: 15f32)).should be_true
      region.contains_point?(RL::Vector2.new(x: 85f32, y: 85f32)).should be_true

      # Center
      region.contains_point?(RL::Vector2.new(x: 50f32, y: 50f32)).should be_true

      # Outside
      region.contains_point?(RL::Vector2.new(x: 5f32, y: 50f32)).should be_false
      region.contains_point?(RL::Vector2.new(x: 95f32, y: 50f32)).should be_false
      region.contains_point?(RL::Vector2.new(x: 50f32, y: 5f32)).should be_false
      region.contains_point?(RL::Vector2.new(x: 50f32, y: 95f32)).should be_false
    end

    it "handles complex polygons" do
      # L-shaped polygon
      region = PointClickEngine::Scenes::PolygonRegion.new
      region.vertices = [
        RL::Vector2.new(x: 0f32, y: 0f32),
        RL::Vector2.new(x: 100f32, y: 0f32),
        RL::Vector2.new(x: 100f32, y: 50f32),
        RL::Vector2.new(x: 50f32, y: 50f32),
        RL::Vector2.new(x: 50f32, y: 100f32),
        RL::Vector2.new(x: 0f32, y: 100f32),
      ]

      # Inside L shape
      region.contains_point?(RL::Vector2.new(x: 25f32, y: 25f32)).should be_true
      region.contains_point?(RL::Vector2.new(x: 75f32, y: 25f32)).should be_true
      region.contains_point?(RL::Vector2.new(x: 25f32, y: 75f32)).should be_true

      # In the cut-out area
      region.contains_point?(RL::Vector2.new(x: 75f32, y: 75f32)).should be_false
    end
  end
end

describe PointClickEngine::Scenes::WalkBehindRegion do
  it "initializes with y threshold and z order" do
    region = PointClickEngine::Scenes::WalkBehindRegion.new("pillar", 200f32, 5)

    region.name.should eq("pillar")
    region.y_threshold.should eq(200f32)
    region.z_order.should eq(5)
    region.walkable.should be_true # Inherited from PolygonRegion
  end

  it "inherits polygon functionality" do
    region = PointClickEngine::Scenes::WalkBehindRegion.new("column", 150f32)
    region.vertices = [
      RL::Vector2.new(x: 40f32, y: 40f32),
      RL::Vector2.new(x: 60f32, y: 40f32),
      RL::Vector2.new(x: 60f32, y: 60f32),
      RL::Vector2.new(x: 40f32, y: 60f32),
    ]

    # Should work like a polygon
    region.contains_point?(RL::Vector2.new(x: 50f32, y: 50f32)).should be_true
    region.contains_point?(RL::Vector2.new(x: 30f32, y: 50f32)).should be_false
  end
end

describe PointClickEngine::Scenes::ScaleZone do
  it "initializes with Y range and scale values" do
    zone = PointClickEngine::Scenes::ScaleZone.new(100f32, 300f32, 0.5f32, 1.0f32)

    zone.min_y.should eq(100f32)
    zone.max_y.should eq(300f32)
    zone.min_scale.should eq(0.5f32)
    zone.max_scale.should eq(1.0f32)
  end

  it "uses default scale values" do
    zone = PointClickEngine::Scenes::ScaleZone.new(0f32, 100f32)

    zone.min_scale.should eq(0.5f32)
    zone.max_scale.should eq(1.0f32)
  end

  it "can have inverted scales for special effects" do
    # Larger at top, smaller at bottom
    zone = PointClickEngine::Scenes::ScaleZone.new(0f32, 100f32, 1.5f32, 0.8f32)

    zone.min_scale.should eq(1.5f32)
    zone.max_scale.should eq(0.8f32)
  end
end
