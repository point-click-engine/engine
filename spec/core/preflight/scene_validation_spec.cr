require "./spec_helper"

describe "PreflightCheck Scene Validation" do
  before_each do
    cleanup_test_files
  end

  after_each do
    cleanup_test_files
  end

  describe "scene background validation" do
    it "detects missing scene backgrounds" do
      Dir.mkdir_p("test_game_dir/scenes")

      scene_yaml = <<-YAML
      name: "intro"
      background_path: "../backgrounds/missing_bg.png"
      YAML

      File.write("test_game_dir/scenes/intro.yaml", scene_yaml)

      config_yaml = <<-YAML
      game:
        title: "Test Game"
      window:
        width: 1024
        height: 768
      assets:
        scenes:
          - "scenes/*.yaml"
      YAML

      File.write("test_game_dir/game.yaml", config_yaml)

      result = PointClickEngine::Core::PreflightCheck.run("test_game_dir/game.yaml")

      error_found = result.errors.any? { |e| e.includes?("Background image not found") }
      error_found.should be_true
    end

    it "warns about scenes without backgrounds" do
      Dir.mkdir_p("test_game_dir/scenes")

      scene_yaml = <<-YAML
      name: "intro"
      hotspots:
        - name: "door"
          x: 100
          y: 200
          width: 50
          height: 100
      YAML

      File.write("test_game_dir/scenes/intro.yaml", scene_yaml)

      config_yaml = <<-YAML
      game:
        title: "Test Game"
      window:
        width: 1024
        height: 768
      assets:
        scenes:
          - "scenes/*.yaml"
      YAML

      File.write("test_game_dir/game.yaml", config_yaml)

      result = PointClickEngine::Core::PreflightCheck.run("test_game_dir/game.yaml")

      warning_found = result.warnings.any? { |w| w.includes?("no background specified") }
      warning_found.should be_true
    end

    it "validates existing backgrounds" do
      Dir.mkdir_p("test_game_dir/scenes")
      Dir.mkdir_p("test_game_dir/backgrounds")
      File.write("test_game_dir/backgrounds/intro_bg.png", "fake_png")

      scene_yaml = <<-YAML
      name: "intro"
      background_path: "../backgrounds/intro_bg.png"
      YAML

      File.write("test_game_dir/scenes/intro.yaml", scene_yaml)

      config_yaml = <<-YAML
      game:
        title: "Test Game"
      window:
        width: 1024
        height: 768
      assets:
        scenes:
          - "scenes/*.yaml"
      YAML

      File.write("test_game_dir/game.yaml", config_yaml)

      result = PointClickEngine::Core::PreflightCheck.run("test_game_dir/game.yaml")

      # Should not have background errors
      bg_errors = result.errors.select { |e| e.includes?("Background") && e.includes?("not found") }
      bg_errors.should be_empty
    end
  end

  describe "scene reference validation" do
    it "detects broken scene references" do
      Dir.mkdir_p("test_game_dir/scenes")

      # Scene with exit to non-existent scene
      scene_yaml = <<-YAML
      name: "intro"
      hotspots:
        - name: "exit_door"
          x: 400
          y: 300
          width: 100
          height: 200
          target_scene: "missing_scene"
      YAML

      File.write("test_game_dir/scenes/intro.yaml", scene_yaml)

      config_yaml = <<-YAML
      game:
        title: "Test Game"
      window:
        width: 1024
        height: 768
      start_scene: "intro"
      assets:
        scenes:
          - "scenes/*.yaml"
      YAML

      File.write("test_game_dir/game.yaml", config_yaml)

      result = PointClickEngine::Core::PreflightCheck.run("test_game_dir/game.yaml")

      error_found = result.errors.any? { |e| e.includes?("references non-existent scene") || e.includes?("missing_scene") }
      error_found.should be_true
    end

    it "validates existing scene references" do
      Dir.mkdir_p("test_game_dir/scenes")

      # Create two scenes with valid references
      intro_yaml = <<-YAML
      name: "intro"
      hotspots:
        - name: "exit_door"
          x: 400
          y: 300
          width: 100
          height: 200
          target_scene: "hallway"
      YAML

      hallway_yaml = <<-YAML
      name: "hallway"
      hotspots:
        - name: "back_door"
          x: 100
          y: 300
          width: 100
          height: 200
          target_scene: "intro"
      YAML

      File.write("test_game_dir/scenes/intro.yaml", intro_yaml)
      File.write("test_game_dir/scenes/hallway.yaml", hallway_yaml)

      config_yaml = <<-YAML
      game:
        title: "Test Game"
      window:
        width: 1024
        height: 768
      start_scene: "intro"
      assets:
        scenes:
          - "scenes/*.yaml"
      YAML

      File.write("test_game_dir/game.yaml", config_yaml)

      result = PointClickEngine::Core::PreflightCheck.run("test_game_dir/game.yaml")

      # Should not have scene reference errors
      ref_errors = result.errors.select { |e| e.includes?("references non-existent scene") }
      ref_errors.should be_empty
    end
  end

  describe "walkable area validation" do
    it "detects scenes without walkable areas" do
      Dir.mkdir_p("test_game_dir/scenes")

      scene_yaml = <<-YAML
      name: "intro"
      background_path: "bg.png"
      # No walkable areas defined
      YAML

      File.write("test_game_dir/scenes/intro.yaml", scene_yaml)

      config_yaml = <<-YAML
      game:
        title: "Test Game"
      window:
        width: 1024
        height: 768
      start_scene: "intro"
      assets:
        scenes:
          - "scenes/*.yaml"
      YAML

      File.write("test_game_dir/game.yaml", config_yaml)

      result = PointClickEngine::Core::PreflightCheck.run("test_game_dir/game.yaml")

      warning_found = result.warnings.any? { |w| w.includes?("no walkable areas") }
      warning_found.should be_true
    end

    it "validates walkable area polygons" do
      Dir.mkdir_p("test_game_dir/scenes")

      scene_yaml = <<-YAML
      name: "intro"
      background_path: "bg.png"
      walkable_areas:
        - polygon:
            - {x: 0, y: 0}
            - {x: 100}  # Missing y coordinate
        - polygon:
            - {x: 200, y: 200}
            - {x: 300, y: 200}
            # Only 2 points, need at least 3 for a polygon
      YAML

      File.write("test_game_dir/scenes/intro.yaml", scene_yaml)

      config_yaml = <<-YAML
      game:
        title: "Test Game"
      window:
        width: 1024
        height: 768
      start_scene: "intro"
      assets:
        scenes:
          - "scenes/*.yaml"
      YAML

      File.write("test_game_dir/game.yaml", config_yaml)

      result = PointClickEngine::Core::PreflightCheck.run("test_game_dir/game.yaml")

      # Should have errors about invalid polygons
      polygon_errors = result.errors.select { |e|
        e.includes?("polygon") || e.includes?("walkable area") || e.includes?("coordinates")
      }
      polygon_errors.should_not be_empty
    end
  end

  describe "hotspot validation" do
    it "detects invalid hotspot configurations" do
      Dir.mkdir_p("test_game_dir/scenes")

      scene_yaml = <<-YAML
      name: "intro"
      hotspots:
        - name: "invalid_hotspot"
          # Missing position
          width: 100
          height: 100
        - name: "negative_size"
          x: 100
          y: 100
          width: -50
          height: 0
      YAML

      File.write("test_game_dir/scenes/intro.yaml", scene_yaml)

      config_yaml = <<-YAML
      game:
        title: "Test Game"
      window:
        width: 1024
        height: 768
      start_scene: "intro"
      assets:
        scenes:
          - "scenes/*.yaml"
      YAML

      File.write("test_game_dir/game.yaml", config_yaml)

      result = PointClickEngine::Core::PreflightCheck.run("test_game_dir/game.yaml")

      # Should have errors about invalid hotspots
      hotspot_errors = result.errors.select { |e|
        e.includes?("hotspot") && (e.includes?("invalid") || e.includes?("missing") || e.includes?("negative"))
      }
      hotspot_errors.should_not be_empty
    end

    it "warns about overlapping hotspots" do
      Dir.mkdir_p("test_game_dir/scenes")

      scene_yaml = <<-YAML
      name: "intro"
      hotspots:
        - name: "door1"
          x: 100
          y: 100
          width: 100
          height: 100
        - name: "door2"
          x: 150
          y: 150
          width: 100
          height: 100
      YAML

      File.write("test_game_dir/scenes/intro.yaml", scene_yaml)

      config_yaml = <<-YAML
      game:
        title: "Test Game"
      window:
        width: 1024
        height: 768
      start_scene: "intro"
      assets:
        scenes:
          - "scenes/*.yaml"
      YAML

      File.write("test_game_dir/game.yaml", config_yaml)

      result = PointClickEngine::Core::PreflightCheck.run("test_game_dir/game.yaml")

      warning_found = result.warnings.any? { |w| w.includes?("overlap") }
      warning_found.should be_true
    end
  end
end
