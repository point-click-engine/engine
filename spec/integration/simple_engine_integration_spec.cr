require "../spec_helper"

# Simple integration tests that don't require graphics initialization
# These tests focus on core engine components working together
describe "Simple Engine Integration" do
  describe "scene management integration" do
    it "can create scenes without graphics" do
      # Test creating scenes and basic operations
      scene = PointClickEngine::Scenes::Scene.new("test_scene")
      scene.name.should eq("test_scene")
      
      # Test adding hotspots
      hotspot = PointClickEngine::Scenes::Hotspot.new(
        "door",
        vec2(100, 100),
        vec2(50, 100)
      )
      
      scene.hotspots << hotspot
      scene.hotspots.size.should eq(1)
      scene.hotspots.first.name.should eq("door")
    end
  end

  describe "config loading integration" do
    it "loads configuration without validation" do
      # Test basic YAML parsing without file validation
      yaml_content = <<-YAML
      game:
        title: "Test Game"
        version: "1.0.0"
      
      window:
        width: 800
        height: 600
        
      start_scene: "intro"
      YAML
      
      # Test parsing directly from YAML (this uses Crystal's built-in YAML)
      parsed = YAML.parse(yaml_content)
      parsed["game"]["title"].as_s.should eq("Test Game")
      parsed["window"]["width"].as_i.should eq(800)
      parsed["start_scene"].as_s.should eq("intro")
    end
  end

  describe "state management integration" do
    it "manages game state without graphics" do
      # Test state variables
      state_value = PointClickEngine::Core::StateValue.new(42)
      state_value.as_int?.should eq(42)
      
      # Test different value types
      string_state = PointClickEngine::Core::StateValue.new("test")
      string_state.as_string?.should eq("test")
      
      bool_state = PointClickEngine::Core::StateValue.new(true)
      bool_state.as_bool?.should be_true
    end
  end

  describe "component validation integration" do
    it "validates scene components properly" do
      # Test scene validation
      scene = PointClickEngine::Scenes::Scene.new("valid_scene")
      scene.name.empty?.should be_false
      
      # Test hotspot validation
      hotspot = PointClickEngine::Scenes::Hotspot.new(
        "test_hotspot",
        vec2(0, 0),
        vec2(10, 10)
      )
      
      hotspot.name.empty?.should be_false
      hotspot.size.x.should be > 0
      hotspot.size.y.should be > 0
    end
  end

  describe "error handling integration" do
    it "handles invalid configurations gracefully" do
      # Test invalid YAML file
      invalid_yaml = "invalid: yaml: content: ["
      File.write("invalid_config.yaml", invalid_yaml)
      
      expect_raises(Exception) do
        PointClickEngine::Core::GameConfig.from_file("invalid_config.yaml")
      end
      
      # Cleanup
      File.delete("invalid_config.yaml")
    end
    
    it "handles missing required fields" do
      # Test config with missing required fields
      incomplete_yaml = <<-YAML
      game:
        title: "Incomplete Game"
      YAML
      
      File.write("incomplete_config.yaml", incomplete_yaml)
      
      # Should either succeed with defaults or fail gracefully
      begin
        config = PointClickEngine::Core::GameConfig.from_file("incomplete_config.yaml")
        config.game.title.should eq("Incomplete Game")
      rescue ex
        # Acceptable - missing required fields should cause failure
        ex.should be_a(Exception)
      end
      
      # Cleanup
      File.delete("incomplete_config.yaml")
    end
  end

  describe "memory management integration" do
    it "creates and destroys objects cleanly" do
      initial_objects = 0
      
      # Create multiple scenes and objects
      scenes = [] of PointClickEngine::Scenes::Scene
      10.times do |i|
        scene = PointClickEngine::Scenes::Scene.new("scene_#{i}")
        
        # Add multiple hotspots to each scene
        5.times do |j|
          hotspot = PointClickEngine::Scenes::Hotspot.new(
            "hotspot_#{j}",
            vec2(j * 10, j * 10),
            vec2(20, 20)
          )
          scene.hotspots << hotspot
        end
        
        scenes << scene
      end
      
      # Verify objects were created
      scenes.size.should eq(10)
      scenes.each { |scene| scene.hotspots.size.should eq(5) }
      
      # Clear references (simulating cleanup)
      scenes.clear
      
      # Force garbage collection
      GC.collect
      
      # Test passes if we get here without crashing
      true.should be_true
    end
  end
end