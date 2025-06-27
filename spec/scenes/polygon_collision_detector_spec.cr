require "../spec_helper"

describe PointClickEngine::Scenes::PolygonCollisionDetector do
  describe "#contains_point?" do
    it "detects points inside a triangle" do
      detector = PointClickEngine::Scenes::PolygonCollisionDetector.new

      vertices = [
        RL::Vector2.new(x: 0, y: 0),
        RL::Vector2.new(x: 100, y: 0),
        RL::Vector2.new(x: 50, y: 100),
      ]

      # Point inside triangle
      detector.contains_point?(vertices, RL::Vector2.new(x: 50, y: 50)).should be_true

      # Point outside triangle
      detector.contains_point?(vertices, RL::Vector2.new(x: 0, y: 100)).should be_false

      # Point on edge (implementation dependent)
      detector.contains_point?(vertices, RL::Vector2.new(x: 50, y: 0)).should be_true
    end

    it "detects points inside a square" do
      detector = PointClickEngine::Scenes::PolygonCollisionDetector.new

      vertices = [
        RL::Vector2.new(x: 0, y: 0),
        RL::Vector2.new(x: 100, y: 0),
        RL::Vector2.new(x: 100, y: 100),
        RL::Vector2.new(x: 0, y: 100),
      ]

      # Points inside
      detector.contains_point?(vertices, RL::Vector2.new(x: 50, y: 50)).should be_true
      detector.contains_point?(vertices, RL::Vector2.new(x: 10, y: 10)).should be_true
      detector.contains_point?(vertices, RL::Vector2.new(x: 90, y: 90)).should be_true

      # Points outside
      detector.contains_point?(vertices, RL::Vector2.new(x: -10, y: 50)).should be_false
      detector.contains_point?(vertices, RL::Vector2.new(x: 110, y: 50)).should be_false
      detector.contains_point?(vertices, RL::Vector2.new(x: 50, y: -10)).should be_false
      detector.contains_point?(vertices, RL::Vector2.new(x: 50, y: 110)).should be_false
    end

    it "handles concave polygons" do
      detector = PointClickEngine::Scenes::PolygonCollisionDetector.new

      # L-shaped polygon
      vertices = [
        RL::Vector2.new(x: 0, y: 0),
        RL::Vector2.new(x: 100, y: 0),
        RL::Vector2.new(x: 100, y: 50),
        RL::Vector2.new(x: 50, y: 50),
        RL::Vector2.new(x: 50, y: 100),
        RL::Vector2.new(x: 0, y: 100),
      ]

      # Inside the L
      detector.contains_point?(vertices, RL::Vector2.new(x: 25, y: 25)).should be_true
      detector.contains_point?(vertices, RL::Vector2.new(x: 25, y: 75)).should be_true

      # In the concave part (outside)
      detector.contains_point?(vertices, RL::Vector2.new(x: 75, y: 75)).should be_false
    end

    it "returns false for polygons with less than 3 vertices" do
      detector = PointClickEngine::Scenes::PolygonCollisionDetector.new

      # Empty polygon
      detector.contains_point?([] of RL::Vector2, RL::Vector2.new(x: 0, y: 0)).should be_false

      # Single point
      vertices = [RL::Vector2.new(x: 50, y: 50)]
      detector.contains_point?(vertices, RL::Vector2.new(x: 50, y: 50)).should be_false

      # Line (2 points)
      vertices = [
        RL::Vector2.new(x: 0, y: 0),
        RL::Vector2.new(x: 100, y: 100),
      ]
      detector.contains_point?(vertices, RL::Vector2.new(x: 50, y: 50)).should be_false
    end
  end

  describe "#point_in_bounds?" do
    it "checks if point is within rectangle bounds" do
      detector = PointClickEngine::Scenes::PolygonCollisionDetector.new

      bounds = RL::Rectangle.new(x: 10, y: 20, width: 100, height: 50)

      # Inside bounds
      detector.point_in_bounds?(RL::Vector2.new(x: 50, y: 40), bounds).should be_true
      detector.point_in_bounds?(RL::Vector2.new(x: 10, y: 20), bounds).should be_true
      detector.point_in_bounds?(RL::Vector2.new(x: 109, y: 69), bounds).should be_true

      # Outside bounds
      detector.point_in_bounds?(RL::Vector2.new(x: 5, y: 40), bounds).should be_false
      detector.point_in_bounds?(RL::Vector2.new(x: 111, y: 40), bounds).should be_false
      detector.point_in_bounds?(RL::Vector2.new(x: 50, y: 10), bounds).should be_false
      detector.point_in_bounds?(RL::Vector2.new(x: 50, y: 71), bounds).should be_false
    end

    it "returns false for invalid bounds" do
      detector = PointClickEngine::Scenes::PolygonCollisionDetector.new

      # Zero width
      bounds = RL::Rectangle.new(x: 10, y: 20, width: 0, height: 50)
      detector.point_in_bounds?(RL::Vector2.new(x: 10, y: 40), bounds).should be_false

      # Zero height
      bounds = RL::Rectangle.new(x: 10, y: 20, width: 100, height: 0)
      detector.point_in_bounds?(RL::Vector2.new(x: 50, y: 20), bounds).should be_false

      # Negative dimensions
      bounds = RL::Rectangle.new(x: 10, y: 20, width: -100, height: 50)
      detector.point_in_bounds?(RL::Vector2.new(x: 50, y: 40), bounds).should be_false
    end
  end

  describe "#calculate_bounds" do
    it "calculates bounding box for vertices" do
      detector = PointClickEngine::Scenes::PolygonCollisionDetector.new

      vertices = [
        RL::Vector2.new(x: 10, y: 20),
        RL::Vector2.new(x: 110, y: 30),
        RL::Vector2.new(x: 60, y: 120),
        RL::Vector2.new(x: 5, y: 80),
      ]

      bounds = detector.calculate_bounds(vertices)

      bounds.x.should eq(5)
      bounds.y.should eq(20)
      bounds.width.should eq(105)  # 110 - 5
      bounds.height.should eq(100) # 120 - 20
    end

    it "returns empty bounds for empty vertices" do
      detector = PointClickEngine::Scenes::PolygonCollisionDetector.new

      bounds = detector.calculate_bounds([] of RL::Vector2)

      bounds.x.should eq(0)
      bounds.y.should eq(0)
      bounds.width.should eq(0)
      bounds.height.should eq(0)
    end
  end

  describe "#calculate_combined_bounds" do
    it "calculates bounds for multiple regions" do
      detector = PointClickEngine::Scenes::PolygonCollisionDetector.new

      region1 = PointClickEngine::Scenes::PolygonRegion.new("r1")
      region1.vertices = [
        RL::Vector2.new(x: 0, y: 0),
        RL::Vector2.new(x: 50, y: 0),
        RL::Vector2.new(x: 50, y: 50),
        RL::Vector2.new(x: 0, y: 50),
      ]

      region2 = PointClickEngine::Scenes::PolygonRegion.new("r2")
      region2.vertices = [
        RL::Vector2.new(x: 100, y: 100),
        RL::Vector2.new(x: 200, y: 100),
        RL::Vector2.new(x: 200, y: 200),
        RL::Vector2.new(x: 100, y: 200),
      ]

      bounds = detector.calculate_combined_bounds([region1, region2])

      bounds.x.should eq(0)
      bounds.y.should eq(0)
      bounds.width.should eq(200)
      bounds.height.should eq(200)
    end

    it "returns empty bounds for no regions" do
      detector = PointClickEngine::Scenes::PolygonCollisionDetector.new

      bounds = detector.calculate_combined_bounds([] of PointClickEngine::Scenes::PolygonRegion)

      bounds.x.should eq(0)
      bounds.y.should eq(0)
      bounds.width.should eq(0)
      bounds.height.should eq(0)
    end
  end
end
