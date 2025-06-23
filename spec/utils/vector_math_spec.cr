require "../spec_helper"
require "../../src/utils/vector_math"

describe PointClickEngine::Utils::VectorMath do
  describe "#distance" do
    it "calculates distance between two points" do
      point1 = Raylib::Vector2.new(x: 0.0_f32, y: 0.0_f32)
      point2 = Raylib::Vector2.new(x: 3.0_f32, y: 4.0_f32)

      distance = PointClickEngine::Utils::VectorMath.distance(point1, point2)

      distance.should be_close(5.0_f32, 0.001_f32) # 3-4-5 triangle
    end

    it "returns zero for same points" do
      point = Raylib::Vector2.new(x: 10.0_f32, y: 20.0_f32)

      distance = PointClickEngine::Utils::VectorMath.distance(point, point)

      distance.should eq(0.0_f32)
    end

    it "handles negative coordinates" do
      point1 = Raylib::Vector2.new(x: -3.0_f32, y: -4.0_f32)
      point2 = Raylib::Vector2.new(x: 0.0_f32, y: 0.0_f32)

      distance = PointClickEngine::Utils::VectorMath.distance(point1, point2)

      distance.should be_close(5.0_f32, 0.001_f32)
    end
  end

  describe "#distance_squared" do
    it "calculates squared distance between two points" do
      point1 = Raylib::Vector2.new(x: 0.0_f32, y: 0.0_f32)
      point2 = Raylib::Vector2.new(x: 3.0_f32, y: 4.0_f32)

      dist_sq = PointClickEngine::Utils::VectorMath.distance_squared(point1, point2)

      dist_sq.should eq(25.0_f32) # 3^2 + 4^2 = 25
    end
  end

  describe "#direction_and_distance" do
    it "calculates direction vector and distance" do
      from = Raylib::Vector2.new(x: 0.0_f32, y: 0.0_f32)
      to = Raylib::Vector2.new(x: 3.0_f32, y: 4.0_f32)

      direction, distance = PointClickEngine::Utils::VectorMath.direction_and_distance(from, to)

      direction.x.should eq(3.0_f32)
      direction.y.should eq(4.0_f32)
      distance.should be_close(5.0_f32, 0.001_f32)
    end

    it "returns zero direction for same points" do
      point = Raylib::Vector2.new(x: 10.0_f32, y: 20.0_f32)

      direction, distance = PointClickEngine::Utils::VectorMath.direction_and_distance(point, point)

      direction.x.should eq(0.0_f32)
      direction.y.should eq(0.0_f32)
      distance.should eq(0.0_f32)
    end
  end

  describe "#normalized_direction" do
    it "returns normalized direction vector" do
      from = Raylib::Vector2.new(x: 0.0_f32, y: 0.0_f32)
      to = Raylib::Vector2.new(x: 3.0_f32, y: 4.0_f32)

      normalized = PointClickEngine::Utils::VectorMath.normalized_direction(from, to)

      # Should have length 1
      length = Math.sqrt(normalized.x ** 2 + normalized.y ** 2)
      length.should be_close(1.0_f32, 0.001_f32)

      # Should maintain direction
      normalized.x.should be_close(0.6_f32, 0.001_f32)
      normalized.y.should be_close(0.8_f32, 0.001_f32)
    end

    it "handles zero distance gracefully" do
      point = Raylib::Vector2.new(x: 5.0_f32, y: 5.0_f32)

      normalized = PointClickEngine::Utils::VectorMath.normalized_direction(point, point)

      normalized.x.should eq(0.0_f32)
      normalized.y.should eq(0.0_f32)
    end
  end

  describe "#normalize_vector" do
    it "normalizes a vector given its length" do
      vector = Raylib::Vector2.new(x: 3.0_f32, y: 4.0_f32)
      length = 5.0_f32

      normalized = PointClickEngine::Utils::VectorMath.normalize_vector(vector, length)

      normalized.x.should be_close(0.6_f32, 0.001_f32)
      normalized.y.should be_close(0.8_f32, 0.001_f32)
    end

    it "returns zero vector for very small length" do
      vector = Raylib::Vector2.new(x: 0.0001_f32, y: 0.0001_f32)
      length = 0.0001_f32

      normalized = PointClickEngine::Utils::VectorMath.normalize_vector(vector, length)

      normalized.x.should eq(0.0_f32)
      normalized.y.should eq(0.0_f32)
    end
  end

  describe "#move_towards" do
    it "moves point towards target by specified step" do
      from = Raylib::Vector2.new(x: 0.0_f32, y: 0.0_f32)
      to = Raylib::Vector2.new(x: 10.0_f32, y: 0.0_f32)
      step = 3.0_f32

      new_pos = PointClickEngine::Utils::VectorMath.move_towards(from, to, step)

      new_pos.x.should eq(3.0_f32)
      new_pos.y.should eq(0.0_f32)
    end

    it "returns target when step exceeds distance" do
      from = Raylib::Vector2.new(x: 0.0_f32, y: 0.0_f32)
      to = Raylib::Vector2.new(x: 2.0_f32, y: 0.0_f32)
      step = 5.0_f32

      new_pos = PointClickEngine::Utils::VectorMath.move_towards(from, to, step)

      new_pos.x.should eq(2.0_f32)
      new_pos.y.should eq(0.0_f32)
    end
  end

  describe "#lerp" do
    it "interpolates between two points" do
      from = Raylib::Vector2.new(x: 0.0_f32, y: 0.0_f32)
      to = Raylib::Vector2.new(x: 10.0_f32, y: 20.0_f32)

      # Test halfway
      mid = PointClickEngine::Utils::VectorMath.lerp(from, to, 0.5_f32)
      mid.x.should eq(5.0_f32)
      mid.y.should eq(10.0_f32)

      # Test quarter way
      quarter = PointClickEngine::Utils::VectorMath.lerp(from, to, 0.25_f32)
      quarter.x.should eq(2.5_f32)
      quarter.y.should eq(5.0_f32)
    end

    it "clamps t to [0, 1] range" do
      from = Raylib::Vector2.new(x: 0.0_f32, y: 0.0_f32)
      to = Raylib::Vector2.new(x: 10.0_f32, y: 10.0_f32)

      # Test t > 1
      result1 = PointClickEngine::Utils::VectorMath.lerp(from, to, 2.0_f32)
      result1.x.should eq(10.0_f32)
      result1.y.should eq(10.0_f32)

      # Test t < 0
      result2 = PointClickEngine::Utils::VectorMath.lerp(from, to, -1.0_f32)
      result2.x.should eq(0.0_f32)
      result2.y.should eq(0.0_f32)
    end
  end

  describe "#point_in_rect?" do
    it "returns true when point is inside rectangle" do
      point = Raylib::Vector2.new(x: 5.0_f32, y: 5.0_f32)
      rect_pos = Raylib::Vector2.new(x: 0.0_f32, y: 0.0_f32)
      rect_size = Raylib::Vector2.new(x: 10.0_f32, y: 10.0_f32)

      result = PointClickEngine::Utils::VectorMath.point_in_rect?(point, rect_pos, rect_size)

      result.should be_true
    end

    it "returns false when point is outside rectangle" do
      point = Raylib::Vector2.new(x: 15.0_f32, y: 15.0_f32)
      rect_pos = Raylib::Vector2.new(x: 0.0_f32, y: 0.0_f32)
      rect_size = Raylib::Vector2.new(x: 10.0_f32, y: 10.0_f32)

      result = PointClickEngine::Utils::VectorMath.point_in_rect?(point, rect_pos, rect_size)

      result.should be_false
    end

    it "returns true for points on edges" do
      rect_pos = Raylib::Vector2.new(x: 0.0_f32, y: 0.0_f32)
      rect_size = Raylib::Vector2.new(x: 10.0_f32, y: 10.0_f32)

      # Test all edges
      edge_points = [
        Raylib::Vector2.new(x: 0.0_f32, y: 5.0_f32),  # Left edge
        Raylib::Vector2.new(x: 10.0_f32, y: 5.0_f32), # Right edge
        Raylib::Vector2.new(x: 5.0_f32, y: 0.0_f32),  # Top edge
        Raylib::Vector2.new(x: 5.0_f32, y: 10.0_f32), # Bottom edge
      ]

      edge_points.each do |point|
        result = PointClickEngine::Utils::VectorMath.point_in_rect?(point, rect_pos, rect_size)
        result.should be_true
      end
    end
  end

  describe "#point_in_circle?" do
    it "returns true when point is inside circle" do
      point = Raylib::Vector2.new(x: 3.0_f32, y: 4.0_f32)
      center = Raylib::Vector2.new(x: 0.0_f32, y: 0.0_f32)
      radius = 10.0_f32

      result = PointClickEngine::Utils::VectorMath.point_in_circle?(point, center, radius)

      result.should be_true
    end

    it "returns false when point is outside circle" do
      point = Raylib::Vector2.new(x: 10.0_f32, y: 10.0_f32)
      center = Raylib::Vector2.new(x: 0.0_f32, y: 0.0_f32)
      radius = 5.0_f32

      result = PointClickEngine::Utils::VectorMath.point_in_circle?(point, center, radius)

      result.should be_false
    end

    it "returns true for points on circumference" do
      center = Raylib::Vector2.new(x: 0.0_f32, y: 0.0_f32)
      radius = 5.0_f32
      point = Raylib::Vector2.new(x: 5.0_f32, y: 0.0_f32) # On the edge

      result = PointClickEngine::Utils::VectorMath.point_in_circle?(point, center, radius)

      result.should be_true
    end
  end

  describe "#angle_between" do
    it "calculates angle between two points" do
      from = Raylib::Vector2.new(x: 0.0_f32, y: 0.0_f32)

      # Test cardinal directions
      right = Raylib::Vector2.new(x: 1.0_f32, y: 0.0_f32)
      angle_right = PointClickEngine::Utils::VectorMath.angle_between(from, right)
      angle_right.should be_close(0.0_f32, 0.001_f32)

      up = Raylib::Vector2.new(x: 0.0_f32, y: -1.0_f32)
      angle_up = PointClickEngine::Utils::VectorMath.angle_between(from, up)
      angle_up.should be_close(-Math::PI/2, 0.001_f32)

      left = Raylib::Vector2.new(x: -1.0_f32, y: 0.0_f32)
      angle_left = PointClickEngine::Utils::VectorMath.angle_between(from, left)
      angle_left.abs.should be_close(Math::PI, 0.001_f32)

      down = Raylib::Vector2.new(x: 0.0_f32, y: 1.0_f32)
      angle_down = PointClickEngine::Utils::VectorMath.angle_between(from, down)
      angle_down.should be_close(Math::PI/2, 0.001_f32)
    end
  end

  describe "#angle_to_vector" do
    it "converts angle to direction vector" do
      # Test cardinal directions
      right = PointClickEngine::Utils::VectorMath.angle_to_vector(0.0_f32)
      right.x.should be_close(1.0_f32, 0.001_f32)
      right.y.should be_close(0.0_f32, 0.001_f32)

      up = PointClickEngine::Utils::VectorMath.angle_to_vector((-Math::PI/2).to_f32)
      up.x.should be_close(0.0_f32, 0.001_f32)
      up.y.should be_close(-1.0_f32, 0.001_f32)

      left = PointClickEngine::Utils::VectorMath.angle_to_vector(Math::PI.to_f32)
      left.x.should be_close(-1.0_f32, 0.001_f32)
      left.y.should be_close(0.0_f32, 0.001_f32)

      down = PointClickEngine::Utils::VectorMath.angle_to_vector((Math::PI/2).to_f32)
      down.x.should be_close(0.0_f32, 0.001_f32)
      down.y.should be_close(1.0_f32, 0.001_f32)
    end
  end

  describe "#clamp_magnitude" do
    it "clamps vector magnitude to maximum" do
      vector = Raylib::Vector2.new(x: 6.0_f32, y: 8.0_f32) # Magnitude 10
      max_magnitude = 5.0_f32

      clamped = PointClickEngine::Utils::VectorMath.clamp_magnitude(vector, max_magnitude)

      # Should maintain direction but reduce magnitude
      magnitude = Math.sqrt(clamped.x ** 2 + clamped.y ** 2)
      magnitude.should be_close(5.0_f32, 0.001_f32)

      # Should maintain direction (3:4 ratio)
      clamped.x.should be_close(3.0_f32, 0.001_f32)
      clamped.y.should be_close(4.0_f32, 0.001_f32)
    end

    it "leaves smaller vectors unchanged" do
      vector = Raylib::Vector2.new(x: 2.0_f32, y: 1.0_f32) # Magnitude ~2.236
      max_magnitude = 5.0_f32

      clamped = PointClickEngine::Utils::VectorMath.clamp_magnitude(vector, max_magnitude)

      clamped.x.should eq(2.0_f32)
      clamped.y.should eq(1.0_f32)
    end

    it "handles zero vector" do
      zero_vector = Raylib::Vector2.new(x: 0.0_f32, y: 0.0_f32)

      clamped = PointClickEngine::Utils::VectorMath.clamp_magnitude(zero_vector, 5.0_f32)

      clamped.x.should eq(0.0_f32)
      clamped.y.should eq(0.0_f32)
    end
  end

  describe "performance" do
    it "handles repeated calculations efficiently" do
      vector1 = Raylib::Vector2.new(x: 3.0_f32, y: 4.0_f32)
      vector2 = Raylib::Vector2.new(x: 6.0_f32, y: 8.0_f32)

      start_time = Time.monotonic

      # Perform many calculations
      1000.times do
        PointClickEngine::Utils::VectorMath.distance(vector1, vector2)
        PointClickEngine::Utils::VectorMath.normalized_direction(vector1, vector2)
        PointClickEngine::Utils::VectorMath.lerp(vector1, vector2, 0.5_f32)
      end

      end_time = Time.monotonic
      elapsed = (end_time - start_time).total_milliseconds

      # Should complete in reasonable time (under 100ms)
      elapsed.should be < 100.0
    end
  end
end
