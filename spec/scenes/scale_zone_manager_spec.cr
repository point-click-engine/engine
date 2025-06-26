require "../spec_helper"

describe PointClickEngine::Scenes::ScaleZoneManager do
  describe "#get_scale_at_y" do
    it "returns 1.0 when no zones defined" do
      manager = PointClickEngine::Scenes::ScaleZoneManager.new
      
      manager.get_scale_at_y(100).should eq(1.0)
      manager.get_scale_at_y(500).should eq(1.0)
    end
    
    it "interpolates scale within a zone" do
      manager = PointClickEngine::Scenes::ScaleZoneManager.new
      
      zone = PointClickEngine::Scenes::ScaleZone.new(
        min_y: 100,
        max_y: 500,
        min_scale: 0.5,
        max_scale: 1.0
      )
      manager.add_zone(zone)
      
      # At minimum Y
      manager.get_scale_at_y(100).should eq(0.5)
      
      # At maximum Y
      manager.get_scale_at_y(500).should eq(1.0)
      
      # At midpoint
      manager.get_scale_at_y(300).should eq(0.75)
      
      # At 25% point
      manager.get_scale_at_y(200).should eq(0.625)
      
      # At 75% point
      manager.get_scale_at_y(400).should eq(0.875)
    end
    
    it "returns 1.0 outside all zones" do
      manager = PointClickEngine::Scenes::ScaleZoneManager.new
      
      zone = PointClickEngine::Scenes::ScaleZone.new(
        min_y: 200,
        max_y: 400,
        min_scale: 0.5,
        max_scale: 0.8
      )
      manager.add_zone(zone)
      
      # Before zone
      manager.get_scale_at_y(100).should eq(1.0)
      
      # After zone
      manager.get_scale_at_y(500).should eq(1.0)
    end
    
    it "handles multiple zones" do
      manager = PointClickEngine::Scenes::ScaleZoneManager.new
      
      zone1 = PointClickEngine::Scenes::ScaleZone.new(
        min_y: 0,
        max_y: 200,
        min_scale: 0.3,
        max_scale: 0.6
      )
      
      zone2 = PointClickEngine::Scenes::ScaleZone.new(
        min_y: 400,
        max_y: 600,
        min_scale: 0.8,
        max_scale: 1.2
      )
      
      manager.add_zone(zone1)
      manager.add_zone(zone2)
      
      # In first zone
      manager.get_scale_at_y(100).should eq(0.45) # Midpoint of 0.3-0.6
      
      # Between zones (default)
      manager.get_scale_at_y(300).should eq(1.0)
      
      # In second zone
      manager.get_scale_at_y(500).should eq(1.0) # Midpoint of 0.8-1.2
    end
  end

  describe "#in_scale_zone?" do
    it "checks if Y is within any zone" do
      manager = PointClickEngine::Scenes::ScaleZoneManager.new
      
      zone = PointClickEngine::Scenes::ScaleZone.new(
        min_y: 100,
        max_y: 300
      )
      manager.add_zone(zone)
      
      manager.in_scale_zone?(50).should be_false
      manager.in_scale_zone?(100).should be_true
      manager.in_scale_zone?(200).should be_true
      manager.in_scale_zone?(300).should be_true
      manager.in_scale_zone?(350).should be_false
    end
  end

  describe "#get_zone_at_y" do
    it "returns the zone containing Y position" do
      manager = PointClickEngine::Scenes::ScaleZoneManager.new
      
      zone1 = PointClickEngine::Scenes::ScaleZone.new(min_y: 0, max_y: 100)
      zone2 = PointClickEngine::Scenes::ScaleZone.new(min_y: 200, max_y: 300)
      
      manager.add_zone(zone1)
      manager.add_zone(zone2)
      
      manager.get_zone_at_y(50).should eq(zone1)
      manager.get_zone_at_y(250).should eq(zone2)
      manager.get_zone_at_y(150).should be_nil
    end
  end

  describe "#validate_zones" do
    it "detects invalid Y ranges" do
      manager = PointClickEngine::Scenes::ScaleZoneManager.new
      
      # Invalid range (min >= max)
      zone = PointClickEngine::Scenes::ScaleZone.new(
        min_y: 300,
        max_y: 100,
        min_scale: 0.5,
        max_scale: 1.0
      )
      manager.add_zone(zone)
      
      errors = manager.validate_zones
      errors.size.should eq(1)
      errors[0].should contain("invalid Y range")
    end
    
    it "detects negative scale values" do
      manager = PointClickEngine::Scenes::ScaleZoneManager.new
      
      zone = PointClickEngine::Scenes::ScaleZone.new(
        min_y: 100,
        max_y: 200,
        min_scale: -0.5,
        max_scale: 1.0
      )
      manager.add_zone(zone)
      
      errors = manager.validate_zones
      errors.size.should eq(1)
      errors[0].should contain("negative scale values")
    end
    
    it "detects overlapping zones" do
      manager = PointClickEngine::Scenes::ScaleZoneManager.new
      
      zone1 = PointClickEngine::Scenes::ScaleZone.new(
        min_y: 100,
        max_y: 300
      )
      
      zone2 = PointClickEngine::Scenes::ScaleZone.new(
        min_y: 200,
        max_y: 400
      )
      
      manager.add_zone(zone1)
      manager.add_zone(zone2)
      
      errors = manager.validate_zones
      errors.size.should eq(1)
      errors[0].should contain("overlap")
    end
    
    it "returns empty array for valid zones" do
      manager = PointClickEngine::Scenes::ScaleZoneManager.new
      
      zone1 = PointClickEngine::Scenes::ScaleZone.new(
        min_y: 0,
        max_y: 100,
        min_scale: 0.5,
        max_scale: 0.7
      )
      
      zone2 = PointClickEngine::Scenes::ScaleZone.new(
        min_y: 200,
        max_y: 300,
        min_scale: 0.8,
        max_scale: 1.0
      )
      
      manager.add_zone(zone1)
      manager.add_zone(zone2)
      
      errors = manager.validate_zones
      errors.should be_empty
    end
  end

  describe "#clear" do
    it "removes all zones" do
      manager = PointClickEngine::Scenes::ScaleZoneManager.new
      
      3.times do |i|
        zone = PointClickEngine::Scenes::ScaleZone.new(
          min_y: (i * 100).to_f32,
          max_y: ((i + 1) * 100).to_f32
        )
        manager.add_zone(zone)
      end
      
      manager.zones.size.should eq(3)
      
      manager.clear
      
      manager.zones.size.should eq(0)
      manager.zones.should be_empty
    end
  end
end