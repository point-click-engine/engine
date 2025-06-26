require "../spec_helper"

module PointClickEngine::Scenes
  describe WalkBehindManager do
    describe "#initialize" do
      it "creates an empty manager" do
        manager = WalkBehindManager.new
        manager.regions.should be_empty
      end
    end

    describe "#add_region" do
      it "adds a walk-behind region" do
        manager = WalkBehindManager.new
        region = WalkBehindRegion.new("tree", 100.0, 1)
        region.vertices = [
          RL::Vector2.new(10, 10),
          RL::Vector2.new(30, 10),
          RL::Vector2.new(20, 30)
        ]
        
        manager.add_region(region)
        manager.regions.size.should eq(1)
        manager.regions.first.should eq(region)
      end

      it "maintains regions sorted by z_order" do
        manager = WalkBehindManager.new
        
        region1 = WalkBehindRegion.new("tree1", 100.0, 3)
        region2 = WalkBehindRegion.new("tree2", 150.0, 1)
        region3 = WalkBehindRegion.new("tree3", 200.0, 2)
        
        manager.add_region(region1)
        manager.add_region(region2)
        manager.add_region(region3)
        
        manager.regions[0].z_order.should eq(1)
        manager.regions[1].z_order.should eq(2)
        manager.regions[2].z_order.should eq(3)
      end
    end

    describe "#clear" do
      it "removes all regions" do
        manager = WalkBehindManager.new
        manager.add_region(WalkBehindRegion.new("tree1", 100.0, 1))
        manager.add_region(WalkBehindRegion.new("tree2", 150.0, 2))
        
        manager.clear
        manager.regions.should be_empty
      end
    end

    describe "#get_regions_at_y" do
      it "returns regions where character is in front (y > threshold)" do
        manager = WalkBehindManager.new
        
        region1 = WalkBehindRegion.new("tree1", 100.0, 1)
        region2 = WalkBehindRegion.new("tree2", 200.0, 2)
        region3 = WalkBehindRegion.new("tree3", 300.0, 3)
        
        manager.add_region(region1)
        manager.add_region(region2)
        manager.add_region(region3)
        
        regions = manager.get_regions_at_y(250.0)
        regions.size.should eq(2)
        regions.should contain(region1)
        regions.should contain(region2)
        regions.should_not contain(region3)
      end
    end

    describe "#get_regions_character_behind" do
      it "returns regions where character is behind (y <= threshold)" do
        manager = WalkBehindManager.new
        
        region1 = WalkBehindRegion.new("tree1", 100.0, 1)
        region2 = WalkBehindRegion.new("tree2", 200.0, 2)
        region3 = WalkBehindRegion.new("tree3", 300.0, 3)
        
        manager.add_region(region1)
        manager.add_region(region2)
        manager.add_region(region3)
        
        regions = manager.get_regions_character_behind(150.0)
        regions.size.should eq(2)
        regions.should contain(region2)
        regions.should contain(region3)
        regions.should_not contain(region1)
      end
    end

    describe "#point_in_walk_behind?" do
      it "returns true if point is in any walk-behind region" do
        manager = WalkBehindManager.new
        
        region = WalkBehindRegion.new("tree", 100.0, 1)
        region.vertices = [
          RL::Vector2.new(0, 0),
          RL::Vector2.new(20, 0),
          RL::Vector2.new(20, 20),
          RL::Vector2.new(0, 20)
        ]
        
        manager.add_region(region)
        
        manager.point_in_walk_behind?(RL::Vector2.new(10, 10)).should be_true
        manager.point_in_walk_behind?(RL::Vector2.new(30, 30)).should be_false
      end
    end

    describe "#get_region_at_point" do
      it "returns the walk-behind region containing the point" do
        manager = WalkBehindManager.new
        
        region1 = WalkBehindRegion.new("tree1", 100.0, 1)
        region1.vertices = [
          RL::Vector2.new(0, 0),
          RL::Vector2.new(20, 0),
          RL::Vector2.new(20, 20),
          RL::Vector2.new(0, 20)
        ]
        
        region2 = WalkBehindRegion.new("tree2", 150.0, 2)
        region2.vertices = [
          RL::Vector2.new(30, 30),
          RL::Vector2.new(50, 30),
          RL::Vector2.new(50, 50),
          RL::Vector2.new(30, 50)
        ]
        
        manager.add_region(region1)
        manager.add_region(region2)
        
        manager.get_region_at_point(RL::Vector2.new(10, 10)).should eq(region1)
        manager.get_region_at_point(RL::Vector2.new(40, 40)).should eq(region2)
        manager.get_region_at_point(RL::Vector2.new(100, 100)).should be_nil
      end
    end

    describe "#sort_by_z_order!" do
      it "sorts regions by z_order" do
        manager = WalkBehindManager.new
        
        # Add regions in random order
        region1 = WalkBehindRegion.new("tree1", 100.0, 3)
        region2 = WalkBehindRegion.new("tree2", 150.0, 1)
        region3 = WalkBehindRegion.new("tree3", 200.0, 2)
        
        # Manually add to bypass automatic sorting
        manager.regions << region1
        manager.regions << region2
        manager.regions << region3
        
        manager.sort_by_z_order!
        
        manager.regions[0].z_order.should eq(1)
        manager.regions[1].z_order.should eq(2)
        manager.regions[2].z_order.should eq(3)
      end
    end

    describe "#get_regions_in_z_range" do
      it "returns regions within specified z-order range" do
        manager = WalkBehindManager.new
        
        region1 = WalkBehindRegion.new("tree1", 100.0, 1)
        region2 = WalkBehindRegion.new("tree2", 150.0, 3)
        region3 = WalkBehindRegion.new("tree3", 200.0, 5)
        region4 = WalkBehindRegion.new("tree4", 250.0, 7)
        
        manager.add_region(region1)
        manager.add_region(region2)
        manager.add_region(region3)
        manager.add_region(region4)
        
        regions = manager.get_regions_in_z_range(2, 5)
        regions.size.should eq(2)
        regions.should contain(region2)
        regions.should contain(region3)
      end
    end

    describe "#validate_regions" do
      it "detects regions with no vertices" do
        manager = WalkBehindManager.new
        region = WalkBehindRegion.new("empty", 100.0, 1)
        manager.add_region(region)
        
        errors = manager.validate_regions
        errors.should contain("Walk-behind region 'empty' (0) has no vertices")
      end

      it "detects regions with less than 3 vertices" do
        manager = WalkBehindManager.new
        region = WalkBehindRegion.new("invalid", 100.0, 1)
        region.vertices = [
          RL::Vector2.new(0, 0),
          RL::Vector2.new(10, 0)
        ]
        manager.add_region(region)
        
        errors = manager.validate_regions
        errors.should contain("Walk-behind region 'invalid' (0) has less than 3 vertices")
      end

      it "detects duplicate region names" do
        manager = WalkBehindManager.new
        
        region1 = WalkBehindRegion.new("tree", 100.0, 1)
        region1.vertices = [RL::Vector2.new(0, 0), RL::Vector2.new(10, 0), RL::Vector2.new(5, 10)]
        
        region2 = WalkBehindRegion.new("tree", 150.0, 2)
        region2.vertices = [RL::Vector2.new(0, 0), RL::Vector2.new(10, 0), RL::Vector2.new(5, 10)]
        
        manager.add_region(region1)
        manager.add_region(region2)
        
        errors = manager.validate_regions
        errors.should contain("Walk-behind region name 'tree' is used 2 times")
      end

      it "returns empty array for valid regions" do
        manager = WalkBehindManager.new
        
        region = WalkBehindRegion.new("valid", 100.0, 1)
        region.vertices = [
          RL::Vector2.new(0, 0),
          RL::Vector2.new(20, 0),
          RL::Vector2.new(10, 20)
        ]
        
        manager.add_region(region)
        
        errors = manager.validate_regions
        errors.should be_empty
      end
    end
  end
end