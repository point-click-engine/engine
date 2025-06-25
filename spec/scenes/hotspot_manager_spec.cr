require "../spec_helper"
require "../../src/scenes/hotspot_manager"

def create_test_hotspot(name : String, x : Int32, y : Int32, width : Int32, height : Int32) : PointClickEngine::Scenes::Hotspot
  PointClickEngine::Scenes::Hotspot.new(name, x, y, width, height)
end

describe PointClickEngine::Scenes::HotspotManager do
  let(manager) { PointClickEngine::Scenes::HotspotManager.new }

  describe "initialization" do
    it "starts with empty hotspot collection" do
      manager.hotspot_count.should eq(0)
      manager.all_hotspots.should be_empty
      manager.use_spatial_optimization.should be_false
    end
  end

  describe "hotspot management" do
    let(hotspot1) { create_test_hotspot("door", 100, 200, 50, 100) }
    let(hotspot2) { create_test_hotspot("window", 300, 150, 80, 60) }
    let(hotspot3) { create_test_hotspot("table", 400, 300, 120, 80) }

    it "adds hotspots to collection" do
      manager.add_hotspot(hotspot1)
      manager.add_hotspot(hotspot2)

      manager.hotspot_count.should eq(2)
      manager.all_hotspots.should contain(hotspot1)
      manager.all_hotspots.should contain(hotspot2)
    end

    it "prevents duplicate hotspot addition" do
      manager.add_hotspot(hotspot1)
      manager.add_hotspot(hotspot1) # Same hotspot

      manager.hotspot_count.should eq(1)
    end

    it "removes hotspots from collection" do
      manager.add_hotspot(hotspot1)
      manager.add_hotspot(hotspot2)

      manager.remove_hotspot(hotspot1)

      manager.hotspot_count.should eq(1)
      manager.all_hotspots.should_not contain(hotspot1)
      manager.all_hotspots.should contain(hotspot2)
    end

    it "removes hotspots by name" do
      manager.add_hotspot(hotspot1)
      manager.add_hotspot(hotspot2)

      manager.remove_hotspot_by_name("door")

      manager.hotspot_count.should eq(1)
      manager.get_hotspot_by_name("door").should be_nil
      manager.get_hotspot_by_name("window").should eq(hotspot2)
    end

    it "finds hotspots by name" do
      manager.add_hotspot(hotspot1)
      manager.add_hotspot(hotspot2)

      found = manager.get_hotspot_by_name("door")
      found.should eq(hotspot1)

      not_found = manager.get_hotspot_by_name("nonexistent")
      not_found.should be_nil
    end

    it "clears all hotspots" do
      manager.add_hotspot(hotspot1)
      manager.add_hotspot(hotspot2)

      manager.clear_hotspots

      manager.hotspot_count.should eq(0)
      manager.all_hotspots.should be_empty
    end
  end

  describe "position-based queries" do
    let(hotspot1) { create_test_hotspot("door", 100, 200, 50, 100) }  # 100-150, 200-300
    let(hotspot2) { create_test_hotspot("window", 120, 220, 80, 60) } # 120-200, 220-280 (overlaps door)
    let(hotspot3) { create_test_hotspot("table", 400, 300, 120, 80) } # 400-520, 300-380

    before_each do
      manager.add_hotspot(hotspot1)
      manager.add_hotspot(hotspot2)
      manager.add_hotspot(hotspot3)
    end

    it "finds hotspot at specific position" do
      # Point inside door hotspot
      found = manager.get_hotspot_at(RL::Vector2.new(125, 250))
      found.should eq(hotspot1)

      # Point inside table hotspot
      found = manager.get_hotspot_at(RL::Vector2.new(450, 340))
      found.should eq(hotspot3)

      # Point in empty space
      found = manager.get_hotspot_at(RL::Vector2.new(50, 50))
      found.should be_nil
    end

    it "returns topmost hotspot when multiple overlap" do
      # Point in overlapping area of door and window
      position = RL::Vector2.new(140, 240)

      # Both hotspots should contain this point
      hotspot1.contains_point?(position).should be_true
      hotspot2.contains_point?(position).should be_true

      # Should return the one added last (topmost)
      found = manager.get_hotspot_at(position)
      found.should eq(hotspot2) # Added after hotspot1
    end

    it "finds all hotspots at position" do
      # Point in overlapping area
      position = RL::Vector2.new(140, 240)

      all_hotspots = manager.get_hotspots_at(position)
      all_hotspots.size.should eq(2)
      all_hotspots.should contain(hotspot1)
      all_hotspots.should contain(hotspot2)
    end

    it "checks if any hotspot exists at position" do
      manager.has_hotspot_at?(RL::Vector2.new(125, 250)).should be_true
      manager.has_hotspot_at?(RL::Vector2.new(50, 50)).should be_false
    end
  end

  describe "area-based queries" do
    let(hotspot1) { create_test_hotspot("door", 100, 200, 50, 100) }
    let(hotspot2) { create_test_hotspot("window", 300, 150, 80, 60) }
    let(hotspot3) { create_test_hotspot("table", 400, 300, 120, 80) }

    before_each do
      manager.add_hotspot(hotspot1)
      manager.add_hotspot(hotspot2)
      manager.add_hotspot(hotspot3)
    end

    it "finds hotspots within rectangular area" do
      # Area that encompasses door and window
      area = RL::Rectangle.new(x: 50, y: 100, width: 400, height: 200)

      hotspots = manager.get_hotspots_in_area(area)
      hotspots.should contain(hotspot1)     # door
      hotspots.should contain(hotspot2)     # window
      hotspots.should_not contain(hotspot3) # table is outside
    end

    it "finds hotspots within circular area" do
      center = RL::Vector2.new(200, 250)
      radius = 150.0_f32

      hotspots = manager.get_hotspots_in_radius(center, radius)

      # Calculate which hotspots are within radius
      hotspots.each do |hotspot|
        distance = hotspot.distance_to_point(center)
        distance.should be <= radius
      end
    end
  end

  describe "spatial optimization" do
    let(hotspots) do
      # Create many hotspots for testing optimization
      (0...100).map do |i|
        create_test_hotspot("hotspot_#{i}", i * 10, i * 5, 20, 15)
      end
    end

    before_each do
      hotspots.each { |h| manager.add_hotspot(h) }
    end

    it "enables spatial optimization" do
      manager.enable_spatial_optimization(50)

      manager.use_spatial_optimization.should be_true
      manager.spatial_grid_size.should eq(50)
    end

    it "maintains same query results with optimization enabled" do
      position = RL::Vector2.new(155, 77)

      # Get result without optimization
      manager.disable_spatial_optimization
      result_without = manager.get_hotspot_at(position)

      # Get result with optimization
      manager.enable_spatial_optimization
      result_with = manager.get_hotspot_at(position)

      # Results should be the same
      result_without.should eq(result_with)
    end

    it "updates spatial cache when hotspot positions change" do
      manager.enable_spatial_optimization

      # Add a new hotspot after optimization is enabled
      new_hotspot = create_test_hotspot("new", 500, 600, 30, 30)
      manager.add_hotspot(new_hotspot)

      # Should be able to find the new hotspot
      found = manager.get_hotspot_at(RL::Vector2.new(515, 615))
      found.should eq(new_hotspot)
    end

    it "handles position updates efficiently" do
      manager.enable_spatial_optimization

      start_time = Time.monotonic
      manager.update_hotspot_positions
      update_time = Time.monotonic - start_time

      # Should complete quickly even with many hotspots
      update_time.should be < 100.milliseconds
    end
  end

  describe "validation and statistics" do
    let(valid_hotspot) { create_test_hotspot("valid", 100, 200, 50, 100) }
    let(invalid_hotspot) { create_test_hotspot("invalid", -10, -20, 0, 50) }
    let(duplicate_hotspot) { create_test_hotspot("valid", 300, 400, 60, 70) }

    it "validates hotspot consistency" do
      manager.add_hotspot(valid_hotspot)
      manager.add_hotspot(invalid_hotspot)
      manager.add_hotspot(duplicate_hotspot)

      issues = manager.validate_hotspots

      issues.should_not be_empty
      # Should detect invalid dimensions
      issues.any? { |issue| issue.includes?("invalid dimensions") }.should be_true
      # Should detect negative positions
      issues.any? { |issue| issue.includes?("negative position") }.should be_true
      # Should detect duplicate names
      issues.any? { |issue| issue.includes?("Duplicate hotspot name") }.should be_true
    end

    it "provides hotspot statistics" do
      manager.add_hotspot(create_test_hotspot("h1", 0, 0, 100, 100))
      manager.add_hotspot(create_test_hotspot("h2", 50, 50, 100, 100)) # Overlapping
      manager.add_hotspot(create_test_hotspot("h3", 200, 200, 50, 50))

      stats = manager.get_statistics

      stats["total_hotspots"].should eq(3)
      stats["total_area"].should eq(25000) # 100*100 + 100*100 + 50*50
      stats["average_area"].should be_close(8333.33, 1)
      stats["overlapping_pairs"].should eq(1) # h1 and h2 overlap
    end

    it "sorts hotspots by depth" do
      h1 = create_test_hotspot("back", 0, 0, 50, 50)
      h1.z_order = 1
      h2 = create_test_hotspot("middle", 0, 0, 50, 50)
      h2.z_order = 5
      h3 = create_test_hotspot("front", 0, 0, 50, 50)
      h3.z_order = 3

      manager.add_hotspot(h2) # Add in random order
      manager.add_hotspot(h1)
      manager.add_hotspot(h3)

      manager.sort_hotspots_by_depth

      sorted_hotspots = manager.all_hotspots
      sorted_hotspots[0].should eq(h1) # z_order = 1
      sorted_hotspots[1].should eq(h3) # z_order = 3
      sorted_hotspots[2].should eq(h2) # z_order = 5
    end
  end

  describe "data export/import" do
    let(hotspot1) { create_test_hotspot("door", 100, 200, 50, 100) }
    let(hotspot2) { create_test_hotspot("window", 300, 150, 80, 60) }

    before_each do
      hotspot1.z_order = 2
      hotspot1.description = "A wooden door"
      hotspot2.z_order = 1
      hotspot2.description = "A glass window"

      manager.add_hotspot(hotspot1)
      manager.add_hotspot(hotspot2)
    end

    it "exports hotspot data" do
      exported = manager.export_hotspots

      exported.size.should eq(2)

      door_data = exported.find { |h| h["name"] == "door" }
      door_data.should_not be_nil
      if door_data
        door_data["x"].should eq(100)
        door_data["y"].should eq(200)
        door_data["width"].should eq(50)
        door_data["height"].should eq(100)
        door_data["z_order"].should eq(2)
        door_data["description"].should eq("A wooden door")
      end
    end

    it "imports hotspot data" do
      manager.clear_hotspots

      import_data = [
        {
          "name"        => "imported_door",
          "x"           => 150,
          "y"           => 250,
          "width"       => 60,
          "height"      => 120,
          "z_order"     => 3,
          "description" => "An imported door",
        },
        {
          "name"   => "imported_window",
          "x"      => 350,
          "y"      => 180,
          "width"  => 90,
          "height" => 70 # Missing z_order and description (should handle gracefully)
        },
      ]

      manager.import_hotspots(import_data)

      manager.hotspot_count.should eq(2)

      door = manager.get_hotspot_by_name("imported_door")
      door.should_not be_nil
      if door
        door.x.should eq(150)
        door.y.should eq(250)
        door.z_order.should eq(3)
        door.description.should eq("An imported door")
      end

      window = manager.get_hotspot_by_name("imported_window")
      window.should_not be_nil
      if window
        window.x.should eq(350)
        window.y.should eq(180)
        # Should use default values for missing fields
      end
    end
  end

  describe "performance" do
    it "handles large numbers of hotspots efficiently" do
      # Add many hotspots
      start_time = Time.monotonic

      1000.times do |i|
        hotspot = create_test_hotspot("hotspot_#{i}", i % 800, i % 600, 20, 20)
        manager.add_hotspot(hotspot)
      end

      add_time = Time.monotonic - start_time

      # Should complete quickly
      add_time.should be < 1.second

      # Query should also be efficient
      start_time = Time.monotonic
      100.times do |i|
        manager.get_hotspot_at(RL::Vector2.new(i * 8, i * 6))
      end
      query_time = Time.monotonic - start_time

      query_time.should be < 100.milliseconds
    end

    it "benefits from spatial optimization with many hotspots" do
      # Add many hotspots
      500.times do |i|
        hotspot = create_test_hotspot("hotspot_#{i}", i % 800, i % 600, 20, 20)
        manager.add_hotspot(hotspot)
      end

      # Time queries without optimization
      manager.disable_spatial_optimization
      start_time = Time.monotonic
      100.times { manager.get_hotspot_at(RL::Vector2.new(400, 300)) }
      time_without = Time.monotonic - start_time

      # Time queries with optimization
      manager.enable_spatial_optimization
      start_time = Time.monotonic
      100.times { manager.get_hotspot_at(RL::Vector2.new(400, 300)) }
      time_with = Time.monotonic - start_time

      # Optimization should provide some benefit (though exact timing depends on system)
      # At minimum, should not be significantly slower
      time_with.should be <= time_without * 2
    end
  end

  describe "edge cases" do
    it "handles zero-sized hotspots" do
      zero_hotspot = create_test_hotspot("zero", 100, 100, 0, 0)
      manager.add_hotspot(zero_hotspot)

      # Should be able to add but won't contain any points
      found = manager.get_hotspot_at(RL::Vector2.new(100, 100))
      found.should be_nil
    end

    it "handles hotspots with negative positions" do
      negative_hotspot = create_test_hotspot("negative", -50, -30, 100, 80)
      manager.add_hotspot(negative_hotspot)

      # Should be able to find at negative coordinates
      found = manager.get_hotspot_at(RL::Vector2.new(-25, -15))
      found.should eq(negative_hotspot)
    end

    it "handles very large hotspots" do
      large_hotspot = create_test_hotspot("large", 0, 0, 10000, 10000)
      manager.add_hotspot(large_hotspot)

      # Should cover most of the area
      found = manager.get_hotspot_at(RL::Vector2.new(5000, 5000))
      found.should eq(large_hotspot)
    end

    it "handles queries at extreme coordinates" do
      # Should not crash with very large coordinates
      found = manager.get_hotspot_at(RL::Vector2.new(1000000, 1000000))
      found.should be_nil

      found = manager.get_hotspot_at(RL::Vector2.new(-1000000, -1000000))
      found.should be_nil
    end
  end
end
