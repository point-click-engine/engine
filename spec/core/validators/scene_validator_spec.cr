require "../../spec_helper"
require "yaml"

describe PointClickEngine::Core::Validators::SceneValidator do
  describe ".validate_scene_file" do
    it "validates a valid scene" do
      temp_file = File.tempname("valid_scene", ".yaml")
      scene_yaml = <<-YAML
      name: valid_scene
      background_path: backgrounds/room.png
      scale: 1.0
      hotspots:
        - name: door
          x: 100
          y: 200
          width: 50
          height: 100
          actions:
            look: "It's a door"
            use: "open_door"
      YAML
      
      File.write(temp_file, scene_yaml)
      
      begin
        errors = PointClickEngine::Core::Validators::SceneValidator.validate_scene_file(temp_file)
        errors.should be_empty
      ensure
        File.delete(temp_file) if File.exists?(temp_file)
      end
    end

    it "detects missing scene file" do
      errors = PointClickEngine::Core::Validators::SceneValidator.validate_scene_file("/nonexistent/scene.yaml")
      errors.should contain("Scene file not found: /nonexistent/scene.yaml")
    end

    it "detects invalid YAML syntax" do
      temp_file = File.tempname("invalid_yaml", ".yaml")
      File.write(temp_file, "invalid: yaml: syntax: here")
      
      begin
        errors = PointClickEngine::Core::Validators::SceneValidator.validate_scene_file(temp_file)
        errors.any? { |e| e.includes?("Invalid YAML syntax") }.should be_true
      ensure
        File.delete(temp_file) if File.exists?(temp_file)
      end
    end

    it "validates required scene fields" do
      temp_file = File.tempname("missing_fields", ".yaml")
      scene_yaml = <<-YAML
      scale: 1.0
      YAML
      
      File.write(temp_file, scene_yaml)
      
      begin
        errors = PointClickEngine::Core::Validators::SceneValidator.validate_scene_file(temp_file)
        errors.should contain("Missing required field 'name'")
        errors.should contain("Missing required field 'background_path'")
      ensure
        File.delete(temp_file) if File.exists?(temp_file)
      end
    end

    it "validates scene name matches filename" do
      temp_file = File.tempname("test_scene", ".yaml")
      scene_yaml = <<-YAML
      name: different_name
      background_path: bg.png
      YAML
      
      File.write(temp_file, scene_yaml)
      
      begin
        errors = PointClickEngine::Core::Validators::SceneValidator.validate_scene_file(temp_file)
        errors.any? { |e| e.includes?("Scene name 'different_name' doesn't match filename") }.should be_true
      ensure
        File.delete(temp_file) if File.exists?(temp_file)
      end
    end

    it "validates scale value" do
      temp_file = File.tempname("invalid_scale", ".yaml")
      scene_yaml = <<-YAML
      name: invalid_scale
      background_path: bg.png
      scale: 15.0
      YAML
      
      File.write(temp_file, scene_yaml)
      
      begin
        errors = PointClickEngine::Core::Validators::SceneValidator.validate_scene_file(temp_file)
        errors.should contain("Scale must be between 0 and 10 (got 15.0)")
      ensure
        File.delete(temp_file) if File.exists?(temp_file)
      end
    end

    it "validates navigation settings" do
      temp_file = File.tempname("nav_settings", ".yaml")
      scene_yaml = <<-YAML
      name: nav_settings
      background_path: bg.png
      enable_pathfinding: true
      navigation_cell_size: 150
      YAML
      
      File.write(temp_file, scene_yaml)
      
      begin
        errors = PointClickEngine::Core::Validators::SceneValidator.validate_scene_file(temp_file)
        errors.should contain("Navigation cell size must be between 1 and 100 (got 150)")
      ensure
        File.delete(temp_file) if File.exists?(temp_file)
      end
    end

    it "validates hotspots" do
      temp_file = File.tempname("hotspot_test", ".yaml")
      scene_yaml = <<-YAML
      name: hotspot_test
      background_path: bg.png
      hotspots:
        - name: ""
          x: -10
          y: 20
          width: 50
          height: -100
        - type: invalid_type
          name: test
        - type: polygon
          name: poly
        - type: dynamic
          name: dyn
          x: 0
          y: 0
          width: 10
          height: 10
      YAML
      
      File.write(temp_file, scene_yaml)
      
      begin
        errors = PointClickEngine::Core::Validators::SceneValidator.validate_scene_file(temp_file)
        
        errors.should contain("Hotspot #1: Name cannot be empty")
        errors.should contain("Hotspot #1: x cannot be negative")
        errors.should contain("Hotspot #1: height cannot be negative")
        errors.should contain("Hotspot #2: Invalid type 'invalid_type'. Must be one of: rectangle, polygon, dynamic")
        errors.should contain("Hotspot #2: Missing required field 'x'")
        errors.should contain("Hotspot #3: Polygon type requires 'points' array")
        errors.should contain("Hotspot #4: Dynamic hotspot requires 'conditions'")
      ensure
        File.delete(temp_file) if File.exists?(temp_file)
      end
    end

    it "validates polygon hotspot points" do
      temp_file = File.tempname("polygon_test", ".yaml")
      scene_yaml = <<-YAML
      name: polygon_test
      background_path: bg.png
      hotspots:
        - type: polygon
          name: poly1
          points:
            - x: 0
              y: 0
            - x: 100
        - type: polygon
          name: poly2
          points:
            - x: 0
              y: 0
            - x: -50
              y: -50
            - x: 100
              y: 100
      YAML
      
      File.write(temp_file, scene_yaml)
      
      begin
        errors = PointClickEngine::Core::Validators::SceneValidator.validate_scene_file(temp_file)
        
        errors.should contain("Hotspot #1: Polygon must have at least 3 points")
        errors.should contain("Hotspot #1: Point #2 missing x or y coordinate")
        errors.should contain("Hotspot #2: Point #2 has negative coordinates")
      ensure
        File.delete(temp_file) if File.exists?(temp_file)
      end
    end

    it "validates walkable areas" do
      temp_file = File.tempname("walkable_test", ".yaml")
      scene_yaml = <<-YAML
      name: walkable_test
      background_path: bg.png
      walkable_areas:
        - points:
            - x: 0
              y: 0
            - x: 100
              y: 0
        - points:
            - x: 0
              y: 0
            - x: -10
              y: 20
            - x: 50
              y: -30
      YAML
      
      File.write(temp_file, scene_yaml)
      
      begin
        errors = PointClickEngine::Core::Validators::SceneValidator.validate_scene_file(temp_file)
        
        errors.should contain("Walkable area #1: Must have at least 3 points")
        errors.should contain("Walkable area #2: Point #2 has negative coordinates")
        errors.should contain("Walkable area #2: Point #3 has negative coordinates")
      ensure
        File.delete(temp_file) if File.exists?(temp_file)
      end
    end

    it "validates exits" do
      temp_file = File.tempname("exit_test", ".yaml")
      scene_yaml = <<-YAML
      name: exit_test
      background_path: bg.png
      exits:
        - x: -10
          y: 20
          width: 50
        - x: 100
          y: 200
          width: 50
          height: 100
          target_scene: ""
        - x: 200
          y: 300
          width: 50
          height: 100
          target_scene: "next_scene"
          spawn_position:
            x: 100
      YAML
      
      File.write(temp_file, scene_yaml)
      
      begin
        errors = PointClickEngine::Core::Validators::SceneValidator.validate_scene_file(temp_file)
        
        errors.should contain("Exit #1: Missing required field 'height'")
        errors.should contain("Exit #1: Missing required field 'target_scene'")
        errors.should contain("Exit #1: x cannot be negative")
        errors.should contain("Exit #2: Target scene cannot be empty")
        errors.should contain("Exit #3: Spawn position requires both x and y")
      ensure
        File.delete(temp_file) if File.exists?(temp_file)
      end
    end

    it "validates scale zones" do
      temp_file = File.tempname("scale_zone_test", ".yaml")
      scene_yaml = <<-YAML
      name: scale_zone_test
      background_path: bg.png
      scale_zones:
        - x: 0
          y: 0
          width: -100
          height: 100
          min_scale: 0.5
          max_scale: 0.3
        - x: 100
          y: 100
          width: 200
          height: 200
          min_scale: -0.5
          max_scale: 10
      YAML
      
      File.write(temp_file, scene_yaml)
      
      begin
        errors = PointClickEngine::Core::Validators::SceneValidator.validate_scene_file(temp_file)
        
        errors.should contain("Scale zone #1: width cannot be negative")
        errors.should contain("Scale zone #1: min_scale cannot be greater than max_scale")
        errors.should contain("Scale zone #2: min_scale must be between 0 and 5")
        errors.should contain("Scale zone #2: max_scale must be between 0 and 5")
      ensure
        File.delete(temp_file) if File.exists?(temp_file)
      end
    end

    it "validates characters" do
      temp_file = File.tempname("character_test", ".yaml")
      scene_yaml = <<-YAML
      name: character_test
      background_path: bg.png
      characters:
        - name: ""
          x: 100
          y: 200
        - name: "NPC"
          x: -50
          y: -100
          sprite: ""
          dialog: ""
      YAML
      
      File.write(temp_file, scene_yaml)
      
      begin
        errors = PointClickEngine::Core::Validators::SceneValidator.validate_scene_file(temp_file)
        
        errors.should contain("Character #1: Name cannot be empty")
        errors.should contain("Character #2: x cannot be negative")
        errors.should contain("Character #2: y cannot be negative")
        errors.should contain("Character #2: Sprite path cannot be empty")
        errors.should contain("Character #2: Dialog name cannot be empty")
      ensure
        File.delete(temp_file) if File.exists?(temp_file)
      end
    end

    it "validates hotspot actions" do
      temp_file = File.tempname("action_test", ".yaml")
      scene_yaml = <<-YAML
      name: action_test
      background_path: bg.png
      hotspots:
        - name: test
          x: 0
          y: 0
          width: 100
          height: 100
          actions:
            look: "description"
            invalid_action: "something"
            use: "do_something"
      YAML
      
      File.write(temp_file, scene_yaml)
      
      begin
        errors = PointClickEngine::Core::Validators::SceneValidator.validate_scene_file(temp_file)
        
        errors.should contain("Hotspot #1: Unknown action 'invalid_action'")
      ensure
        File.delete(temp_file) if File.exists?(temp_file)
      end
    end
  end
end