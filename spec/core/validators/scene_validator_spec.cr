require "../../spec_helper"
require "yaml"

def with_temp_scene_file(filename : String, content : String, &)
  temp_dir = File.tempname("scene_validator")
  Dir.mkdir_p(temp_dir)
  path = File.join(temp_dir, filename)
  File.write(path, content)
  yield path
ensure
  FileUtils.rm_rf(temp_dir) if temp_dir && Dir.exists?(temp_dir)
end

describe PointClickEngine::Core::Validators::SceneValidator do
  describe ".validate_scene_file" do
    it "accepts a valid scene file" do
      with_temp_scene_file("valid_scene.yaml", <<-YAML
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
      ) do |path|
        PointClickEngine::Core::Validators::SceneValidator.validate_scene_file(path).should be_empty
      end
    end

    it "reports missing files and invalid YAML" do
      missing_errors = PointClickEngine::Core::Validators::SceneValidator.validate_scene_file("/nonexistent/scene.yaml")
      missing_errors.should contain("Scene file not found: /nonexistent/scene.yaml")

      with_temp_scene_file("invalid_yaml.yaml", "invalid: yaml: syntax: here") do |path|
        errors = PointClickEngine::Core::Validators::SceneValidator.validate_scene_file(path)
        errors.any? { |e| e.includes?("Invalid YAML syntax") }.should be_true
      end
    end

    it "validates required scene fields and numeric constraints" do
      with_temp_scene_file("test_scene.yaml", <<-YAML
        scale: 15.0
        enable_pathfinding: true
        navigation_cell_size: 150
      YAML
      ) do |path|
        errors = PointClickEngine::Core::Validators::SceneValidator.validate_scene_file(path)

        errors.should contain("Missing required field 'name'")
        errors.should contain("Missing required field 'background_path'")
        errors.should contain("Scale must be between 0 and 10 (got 15.0)")
        errors.should contain("Navigation cell size must be between 1 and 100 (got 150)")
      end
    end

    it "validates scene names against filenames" do
      with_temp_scene_file("test_scene.yaml", <<-YAML
        name: different_name
        background_path: bg.png
      YAML
      ) do |path|
        errors = PointClickEngine::Core::Validators::SceneValidator.validate_scene_file(path)
        errors.any? { |e| e.includes?("Scene name 'different_name' doesn't match filename 'test_scene'") }.should be_true
      end
    end

    it "validates hotspot shape, type, and dynamic requirements" do
      with_temp_scene_file("hotspot_test.yaml", <<-YAML
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
      ) do |path|
        errors = PointClickEngine::Core::Validators::SceneValidator.validate_scene_file(path)

        errors.should contain("Hotspot #1: Name cannot be empty")
        errors.should contain("Hotspot #1: x cannot be negative")
        errors.should contain("Hotspot #1: height cannot be negative")
        errors.should contain("Hotspot #2: Invalid type 'invalid_type'. Must be one of: rectangle, polygon, dynamic")
        errors.should contain("Hotspot #2: Missing required field 'x'")
        errors.should contain("Hotspot #3: Polygon type requires 'points' array")
        errors.should contain("Hotspot #4: Dynamic hotspot requires 'conditions'")
      end
    end

    it "validates polygon hotspots and walkable regions" do
      with_temp_scene_file("polygon_test.yaml", <<-YAML
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
        walkable_areas:
          regions:
            - name: area1
              walkable: true
              vertices:
                - x: 0
                  y: 0
                - x: 100
                  y: 0
            - name: area2
              walkable: true
              vertices:
                - x: 0
                  y: 0
                - x: -10
                  y: 20
                - x: 50
                  y: -30
      YAML
      ) do |path|
        errors = PointClickEngine::Core::Validators::SceneValidator.validate_scene_file(path)

        errors.should contain("Hotspot #1: Polygon must have at least 3 points")
        errors.should contain("Hotspot #1: Point #2 missing x or y coordinate")
        errors.should contain("Walkable region #1: Must have at least 3 vertices")
        errors.should contain("Walkable region #2: Vertex #2 has negative coordinates")
        errors.should contain("Walkable region #2: Vertex #3 has negative coordinates")
      end
    end

    it "validates exits and characters" do
      with_temp_scene_file("exit_test.yaml", <<-YAML
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
        characters:
          - name: ""
            position:
              x: -1
              y: 20
            sprite: ""
            dialog: ""
            scale: 0.0
      YAML
      ) do |path|
        errors = PointClickEngine::Core::Validators::SceneValidator.validate_scene_file(path)

        errors.should contain("Exit #1: Missing required field 'height'")
        errors.should contain("Exit #1: Missing required field 'target_scene'")
        errors.should contain("Exit #1: x cannot be negative")
        errors.should contain("Exit #2: Target scene cannot be empty")
        errors.should contain("Exit #3: Spawn position requires both x and y")
        errors.should contain("Character #1: Name cannot be empty")
        errors.should contain("Character #1: position.x cannot be negative")
        errors.should contain("Character #1: Sprite path cannot be empty")
        errors.should contain("Character #1: Dialog name cannot be empty")
        errors.should contain("Character #1: Scale must be greater than 0 (got 0.0)")
      end
    end
  end
end
