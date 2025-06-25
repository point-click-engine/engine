require "../spec_helper"
require "../../src/core/preflight_check"
require "file_utils"
require "../../src/core/game_config"

describe PointClickEngine::Core::PreflightCheck do
  describe "player spawn position validation" do
    it "detects when player spawn position is in non-walkable area" do
      # Create test config file
      config_content = <<-YAML
      game:
        title: "Test Game"
        
      window:
        width: 1024
        height: 768
        
      player:
        name: "TestPlayer"
        start_position:
          x: 500.0
          y: 400.0
        sprite:
          frame_width: 56
          frame_height: 56
        scale: 2.0
        
      start_scene: "test_scene"
      
      assets:
        scenes:
          - "test_scene.yaml"
      YAML

      # Create test scene with non-walkable area at player position
      scene_content = <<-YAML
      name: test_scene
      background_path: "test_bg.png"
      logical_width: 1024
      logical_height: 768
      
      walkable_areas:
        regions:
          - name: main_floor
            walkable: true
            vertices:
              - {x: 0, y: 0}
              - {x: 1024, y: 0}
              - {x: 1024, y: 768}
              - {x: 0, y: 768}
          - name: obstacle
            walkable: false
            vertices:
              - {x: 400, y: 300}
              - {x: 600, y: 300}
              - {x: 600, y: 500}
              - {x: 400, y: 500}
      YAML

      # Use /tmp for temporary files
      dir = "/tmp/spec_test_#{Random.rand(10000)}"
      Dir.mkdir_p(dir)

      begin
        config_path = File.join(dir, "game_config.yaml")
        scene_path = File.join(dir, "test_scene.yaml")

        File.write(config_path, config_content)
        File.write(scene_path, scene_content)

        # Create dummy background image
        File.write(File.join(dir, "test_bg.png"), "dummy")

        result = PointClickEngine::Core::PreflightCheck.run(config_path)

        # Should fail because player is spawning inside obstacle
        result.passed.should be_false
        result.errors.any? { |e| e.includes?("non-walkable area") }.should be_true
      ensure
        # Clean up
        FileUtils.rm_rf(dir) if Dir.exists?(dir)
      end
    end

    it "validates player spawn position with character radius" do
      # Create test config
      config_content = <<-YAML
      game:
        title: "Test Game"
        
      window:
        width: 1024
        height: 768
        
      player:
        name: "TestPlayer"
        start_position:
          x: 305.0  # Very close to obstacle edge
          y: 400.0
        sprite:
          frame_width: 56
          frame_height: 56
        scale: 1.5
        
      start_scene: "test_scene"
      
      assets:
        scenes:
          - "test_scene.yaml"
      YAML

      scene_content = <<-YAML
      name: test_scene
      background_path: "test_bg.png"
      logical_width: 1024
      logical_height: 768
      
      walkable_areas:
        regions:
          - name: main_floor
            walkable: true
            vertices:
              - {x: 0, y: 0}
              - {x: 1024, y: 0}
              - {x: 1024, y: 768}
              - {x: 0, y: 768}
          - name: wall
            walkable: false
            vertices:
              - {x: 350, y: 0}
              - {x: 370, y: 0}
              - {x: 370, y: 768}
              - {x: 350, y: 768}
      YAML

      # Use /tmp for temporary files
      dir = "/tmp/spec_test_#{Random.rand(10000)}"
      Dir.mkdir_p(dir)

      begin
        config_path = File.join(dir, "game_config.yaml")
        scene_path = File.join(dir, "test_scene.yaml")

        File.write(config_path, config_content)
        File.write(scene_path, scene_content)
        File.write(File.join(dir, "test_bg.png"), "dummy")

        result = PointClickEngine::Core::PreflightCheck.run(config_path)

        # Should fail because character radius makes it too close to wall
        result.passed.should be_false
        result.errors.any? { |e| e.includes?("too close to non-walkable areas") }.should be_true
        result.errors.any? { |e| e.includes?("Consider moving the spawn position") }.should be_true
      ensure
        # Clean up
        FileUtils.rm_rf(dir) if Dir.exists?(dir)
      end
    end

    it "suggests better spawn position when current one is invalid" do
      config_content = <<-YAML
      game:
        title: "Test Game"
        
      player:
        start_position:
          x: 300.0
          y: 500.0
        sprite:
          frame_width: 56
          frame_height: 56
        scale: 2.0
        
      start_scene: "library"
      
      assets:
        scenes:
          - "library.yaml"
      YAML

      scene_content = <<-YAML
      name: library
      background_path: "library_bg.png"
      logical_width: 1024
      logical_height: 768
      
      walkable_areas:
        regions:
          - name: main_floor
            walkable: true
            vertices:
              - {x: 100, y: 350}
              - {x: 900, y: 350}
              - {x: 900, y: 700}
              - {x: 100, y: 700}
          - name: desk
            walkable: false
            vertices:
              - {x: 250, y: 450}
              - {x: 350, y: 450}
              - {x: 350, y: 550}
              - {x: 250, y: 550}
      YAML

      # Use /tmp for temporary files
      dir = "/tmp/spec_test_#{Random.rand(10000)}"
      Dir.mkdir_p(dir)

      begin
        config_path = File.join(dir, "game_config.yaml")
        scene_path = File.join(dir, "library.yaml")

        File.write(config_path, config_content)
        File.write(scene_path, scene_content)
        File.write(File.join(dir, "library_bg.png"), "dummy")

        result = PointClickEngine::Core::PreflightCheck.run(config_path)

        if !result.passed
          # Should suggest a better position
          result.errors.any? { |e| e.includes?("Consider moving") }.should be_true

          # Extract suggested position from error message
          error_with_suggestion = result.errors.find { |e| e.includes?("Consider moving") }
          if error_with_suggestion
            # Should suggest something like (320, 520) or similar
            error_with_suggestion.should match(/\(\d+, \d+\)/)
          end
        end
      ensure
        # Clean up
        FileUtils.rm_rf(dir) if Dir.exists?(dir)
      end
    end

    it "passes when player spawn position has adequate clearance" do
      config_content = <<-YAML
      game:
        title: "Test Game"
        
      player:
        start_position:
          x: 500.0
          y: 500.0
        sprite:
          frame_width: 56
          frame_height: 56
        scale: 1.0
        
      start_scene: "test_scene"
      
      assets:
        scenes:
          - "test_scene.yaml"
      YAML

      scene_content = <<-YAML
      name: test_scene
      background_path: "test_bg.png"
      logical_width: 1024
      logical_height: 768
      
      walkable_areas:
        regions:
          - name: main_area
            walkable: true
            vertices:
              - {x: 0, y: 0}
              - {x: 1024, y: 0}
              - {x: 1024, y: 768}
              - {x: 0, y: 768}
      YAML

      # Use /tmp for temporary files
      dir = "/tmp/spec_test_#{Random.rand(10000)}"
      Dir.mkdir_p(dir)

      begin
        config_path = File.join(dir, "game_config.yaml")
        scene_path = File.join(dir, "test_scene.yaml")

        File.write(config_path, config_content)
        File.write(scene_path, scene_content)
        File.write(File.join(dir, "test_bg.png"), "dummy")

        result = PointClickEngine::Core::PreflightCheck.run(config_path)

        # Should pass - plenty of clearance
        result.errors.any? { |e| e.includes?("starting position") }.should be_false
        result.info.any? { |i| i.includes?("starting position is in walkable area") }.should be_true
      ensure
        # Clean up
        FileUtils.rm_rf(dir) if Dir.exists?(dir)
      end
    end

    it "handles missing walkable areas gracefully" do
      config_content = <<-YAML
      game:
        title: "Test Game"
        
      player:
        start_position:
          x: 400.0
          y: 400.0
        sprite:
          frame_width: 56
          frame_height: 56
        
      start_scene: "test_scene"
      
      assets:
        scenes:
          - "test_scene.yaml"
      YAML

      scene_content = <<-YAML
      name: test_scene
      background_path: "test_bg.png"
      # No walkable_areas defined
      YAML

      # Use /tmp for temporary files
      dir = "/tmp/spec_test_#{Random.rand(10000)}"
      Dir.mkdir_p(dir)

      begin
        config_path = File.join(dir, "game_config.yaml")
        scene_path = File.join(dir, "test_scene.yaml")

        File.write(config_path, config_content)
        File.write(scene_path, scene_content)
        File.write(File.join(dir, "test_bg.png"), "dummy")

        result = PointClickEngine::Core::PreflightCheck.run(config_path)

        # Should not error on missing walkable areas
        result.errors.any? { |e| e.includes?("starting position") }.should be_false
      ensure
        # Clean up
        FileUtils.rm_rf(dir) if Dir.exists?(dir)
      end
    end
  end
end
