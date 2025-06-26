require "../spec_helper"

module PointClickEngine::Scenes
  describe WalkablePointFinder do
    describe "#initialize" do
      it "creates a finder with collision detector" do
        finder = WalkablePointFinder.new
        finder.should_not be_nil
      end
    end

    describe "#find_nearest_walkable_point" do
      it "returns target point if already walkable" do
        finder = WalkablePointFinder.new
        
        walkable_region = PolygonRegion.new("floor", true)
        walkable_region.vertices = [
          RL::Vector2.new(0, 0),
          RL::Vector2.new(100, 0),
          RL::Vector2.new(100, 100),
          RL::Vector2.new(0, 100)
        ]
        
        regions = [walkable_region]
        target = RL::Vector2.new(50, 50)
        
        result = finder.find_nearest_walkable_point(target, regions)
        result.should eq(target)
      end

      it "finds nearest walkable point when target is in obstacle" do
        finder = WalkablePointFinder.new
        
        walkable_region = PolygonRegion.new("floor", true)
        walkable_region.vertices = [
          RL::Vector2.new(0, 0),
          RL::Vector2.new(100, 0),
          RL::Vector2.new(100, 100),
          RL::Vector2.new(0, 100)
        ]
        
        obstacle = PolygonRegion.new("wall", false)
        obstacle.vertices = [
          RL::Vector2.new(40, 40),
          RL::Vector2.new(60, 40),
          RL::Vector2.new(60, 60),
          RL::Vector2.new(40, 60)
        ]
        
        regions = [walkable_region, obstacle]
        target = RL::Vector2.new(50, 50) # Inside obstacle
        
        result = finder.find_nearest_walkable_point(target, regions, 20.0, 5.0)
        
        # Result should be outside the obstacle but inside walkable area
        result.should_not eq(target)
        # Verify it's walkable
        detector = PolygonCollisionDetector.new
        detector.contains_point?(obstacle.vertices, result).should be_false
        detector.contains_point?(walkable_region.vertices, result).should be_true
      end

      it "returns target when no walkable point found within radius" do
        finder = WalkablePointFinder.new
        
        obstacle = PolygonRegion.new("big_wall", false)
        obstacle.vertices = [
          RL::Vector2.new(-200, -200),
          RL::Vector2.new(200, -200),
          RL::Vector2.new(200, 200),
          RL::Vector2.new(-200, 200)
        ]
        
        regions = [obstacle]
        target = RL::Vector2.new(0, 0) # Inside large obstacle
        
        result = finder.find_nearest_walkable_point(target, regions, 50.0)
        result.should eq(target)
      end

      it "handles empty regions by returning target" do
        finder = WalkablePointFinder.new
        regions = [] of PolygonRegion
        target = RL::Vector2.new(25, 25)
        
        result = finder.find_nearest_walkable_point(target, regions)
        result.should eq(target)
      end
    end

    describe "#constrain_to_walkable" do
      it "returns destination if walkable" do
        finder = WalkablePointFinder.new
        
        walkable_region = PolygonRegion.new("floor", true)
        walkable_region.vertices = [
          RL::Vector2.new(0, 0),
          RL::Vector2.new(100, 0),
          RL::Vector2.new(100, 100),
          RL::Vector2.new(0, 100)
        ]
        
        regions = [walkable_region]
        from = RL::Vector2.new(20, 20)
        to = RL::Vector2.new(80, 80)
        
        result = finder.constrain_to_walkable(from, to, regions)
        result.should eq(to)
      end

      it "constrains movement when path crosses obstacle" do
        finder = WalkablePointFinder.new
        
        walkable_region = PolygonRegion.new("floor", true)
        walkable_region.vertices = [
          RL::Vector2.new(0, 0),
          RL::Vector2.new(100, 0),
          RL::Vector2.new(100, 100),
          RL::Vector2.new(0, 100)
        ]
        
        obstacle = PolygonRegion.new("wall", false)
        obstacle.vertices = [
          RL::Vector2.new(40, 0),
          RL::Vector2.new(60, 0),
          RL::Vector2.new(60, 100),
          RL::Vector2.new(40, 100)
        ]
        
        regions = [walkable_region, obstacle]
        from = RL::Vector2.new(20, 50)
        to = RL::Vector2.new(80, 50) # Path crosses obstacle
        
        result = finder.constrain_to_walkable(from, to, regions)
        
        # Result should be before the obstacle
        result.x.should be < 40
        result.y.should be_close(50, 1)
      end

      it "returns from point when destination is non-walkable and no path exists" do
        finder = WalkablePointFinder.new
        
        obstacle = PolygonRegion.new("wall", false)
        obstacle.vertices = [
          RL::Vector2.new(0, 0),
          RL::Vector2.new(100, 0),
          RL::Vector2.new(100, 100),
          RL::Vector2.new(0, 100)
        ]
        
        regions = [obstacle]
        from = RL::Vector2.new(50, 50) # Inside obstacle (shouldn't happen normally)
        to = RL::Vector2.new(80, 80) # Also inside obstacle
        
        result = finder.constrain_to_walkable(from, to, regions)
        result.should eq(from)
      end

      it "handles empty regions by returning destination" do
        finder = WalkablePointFinder.new
        regions = [] of PolygonRegion
        from = RL::Vector2.new(10, 10)
        to = RL::Vector2.new(90, 90)
        
        result = finder.constrain_to_walkable(from, to, regions)
        result.should eq(to)
      end
    end

    describe "private #is_point_walkable?" do
      it "considers non-walkable regions as higher priority" do
        finder = WalkablePointFinder.new
        
        # Overlapping regions
        walkable_region = PolygonRegion.new("floor", true)
        walkable_region.vertices = [
          RL::Vector2.new(0, 0),
          RL::Vector2.new(100, 0),
          RL::Vector2.new(100, 100),
          RL::Vector2.new(0, 100)
        ]
        
        obstacle = PolygonRegion.new("table", false)
        obstacle.vertices = [
          RL::Vector2.new(25, 25),
          RL::Vector2.new(75, 25),
          RL::Vector2.new(75, 75),
          RL::Vector2.new(25, 75)
        ]
        
        regions = [walkable_region, obstacle]
        
        # Point in both regions - should be non-walkable
        point_in_both = RL::Vector2.new(50, 50)
        result = finder.find_nearest_walkable_point(point_in_both, regions, 1.0)
        result.should_not eq(point_in_both) # Should move it out
        
        # Point only in walkable - should be walkable
        point_walkable = RL::Vector2.new(10, 10)
        result = finder.find_nearest_walkable_point(point_walkable, regions)
        result.should eq(point_walkable)
        
        # Point outside all regions - should be non-walkable
        point_outside = RL::Vector2.new(150, 150)
        result = finder.find_nearest_walkable_point(point_outside, regions, 1.0)
        result.should_not eq(point_outside)
      end
    end
  end
end