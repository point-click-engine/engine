require "./spec_helper"

describe "PreflightCheck Player Configuration Validation" do
  before_each do
    cleanup_test_files
  end

  after_each do
    cleanup_test_files
  end

  describe "player sprite validation" do
    it "detects missing player sprite" do
      config_yaml = <<-YAML
      game:
        title: "Test Game"
      window:
        width: 1024
        height: 768
      player:
        name: "Hero"
        sprite_path: "sprites/player.png"
        sprite:
          frame_width: 32
          frame_height: 64
          columns: 4
          rows: 4
      YAML

      File.write("test_game.yaml", config_yaml)

      result = PointClickEngine::Core::PreflightCheck.run("test_game.yaml")

      error_found = result.errors.any? { |e| e.includes?("Player sprite not found") || e.includes?("Missing sprite") }
      error_found.should be_true
    end

    it "validates existing player sprite" do
      Dir.mkdir_p("sprites")
      File.write("sprites/player.png", "fake_png_data")

      config_yaml = <<-YAML
      game:
        title: "Test Game"
      window:
        width: 1024
        height: 768
      player:
        name: "Hero"
        sprite_path: "sprites/player.png"
        sprite:
          frame_width: 32
          frame_height: 64
          columns: 4
          rows: 4
      YAML

      File.write("test_game.yaml", config_yaml)

      result = PointClickEngine::Core::PreflightCheck.run("test_game.yaml")

      # Should not have sprite not found errors
      sprite_errors = result.errors.select { |e| e.includes?("Player sprite not found") }
      sprite_errors.should be_empty
    end
  end

  describe "sprite dimension validation" do
    it "validates player sprite dimensions" do
      Dir.mkdir_p("test_game_dir/sprites")
      File.write("test_game_dir/sprites/player.png", "fake_png_data")

      config_yaml = <<-YAML
      game:
        title: "Test Game"
      window:
        width: 1024
        height: 768
      player:
        name: "Hero"
        sprite_path: "sprites/player.png"
        sprite:
          frame_width: -32
          frame_height: 0
          columns: 4
          rows: 4
      YAML

      File.write("test_game_dir/test_game.yaml", config_yaml)

      result = PointClickEngine::Core::PreflightCheck.run("test_game_dir/test_game.yaml")

      error_found = result.errors.any? { |e|
        e.includes?("Invalid player sprite dimensions") ||
          e.includes?("frame_width must be positive") ||
          e.includes?("frame_height must be positive")
      }
      error_found.should be_true
    end

    it "warns about large sprite frames" do
      Dir.mkdir_p("test_game_dir/sprites")
      File.write("test_game_dir/sprites/player.png", "fake_png_data")

      config_yaml = <<-YAML
      game:
        title: "Test Game"
      window:
        width: 1024
        height: 768
      player:
        name: "Hero"
        sprite_path: "sprites/player.png"
        sprite:
          frame_width: 512
          frame_height: 512
          columns: 4
          rows: 4
      YAML

      File.write("test_game_dir/test_game.yaml", config_yaml)

      result = PointClickEngine::Core::PreflightCheck.run("test_game_dir/test_game.yaml")

      warning_found = result.warnings.any? { |w| w.includes?("Player sprite frames are large") }
      warning_found.should be_true
    end

    it "accepts reasonable sprite dimensions" do
      Dir.mkdir_p("sprites")
      File.write("sprites/player.png", "fake_png_data")

      config_yaml = <<-YAML
      game:
        title: "Test Game"
      window:
        width: 1024
        height: 768
      player:
        name: "Hero"
        sprite_path: "sprites/player.png"
        sprite:
          frame_width: 64
          frame_height: 96
          columns: 8
          rows: 4
      YAML

      File.write("test_game.yaml", config_yaml)

      result = PointClickEngine::Core::PreflightCheck.run("test_game.yaml")

      # Should not have dimension warnings
      dimension_warnings = result.warnings.select { |w|
        w.includes?("sprite") && (w.includes?("large") || w.includes?("dimension"))
      }
      dimension_warnings.should be_empty
    end
  end

  describe "player movement validation" do
    it "validates player speed settings" do
      config_yaml = <<-YAML
      game:
        title: "Test Game"
      window:
        width: 1024
        height: 768
      player:
        name: "Hero"
        movement:
          walk_speed: -100
          run_speed: 0
      YAML

      File.write("test_game.yaml", config_yaml)

      result = PointClickEngine::Core::PreflightCheck.run("test_game.yaml")

      # Should error on invalid speeds
      speed_errors = result.errors.select { |e|
        e.includes?("speed") && (e.includes?("negative") || e.includes?("must be positive"))
      }
      speed_errors.should_not be_empty
    end

    it "warns about very high player speeds" do
      config_yaml = <<-YAML
      game:
        title: "Test Game"
      window:
        width: 1024
        height: 768
      player:
        name: "Hero"
        movement:
          walk_speed: 1000
          run_speed: 2000
      YAML

      File.write("test_game.yaml", config_yaml)

      result = PointClickEngine::Core::PreflightCheck.run("test_game.yaml")

      # Should warn about high speeds
      speed_warnings = result.warnings.select { |w|
        w.includes?("speed") && (w.includes?("high") || w.includes?("fast"))
      }
      speed_warnings.should_not be_empty
    end
  end

  describe "player spawn validation" do
    it "validates player spawn position in start scene" do
      Dir.mkdir_p("test_scenes")
      File.write("test_scenes/intro.yaml", create_test_scene("intro"))

      config_yaml = <<-YAML
      game:
        title: "Test Game"
      window:
        width: 1024
        height: 768
      start_scene: "intro"
      player:
        name: "Hero"
        spawn_position:
          x: 500
          y: 500
      YAML

      File.write("test_game.yaml", config_yaml)

      result = PointClickEngine::Core::PreflightCheck.run("test_game.yaml")

      # Should warn if spawn is outside walkable area
      spawn_warnings = result.warnings.select { |w|
        w.includes?("spawn") && (w.includes?("outside") || w.includes?("walkable"))
      }
      spawn_warnings.should_not be_empty
    end

    it "accepts valid spawn positions" do
      Dir.mkdir_p("test_scenes")
      Dir.mkdir_p("test_sprites")
      File.write("test_sprites/test_sprite.png", "fake_png")
      File.write("test_scenes/intro.yaml", create_test_scene("intro"))

      config_yaml = <<-YAML
      game:
        title: "Test Game"
      window:
        width: 1024
        height: 768
      start_scene: "intro"
      player:
        name: "Hero"
        spawn_position:
          x: 50
          y: 50
      YAML

      File.write("test_game.yaml", config_yaml)

      result = PointClickEngine::Core::PreflightCheck.run("test_game.yaml")

      # Should not warn about valid spawn position
      spawn_errors = result.errors.select { |e|
        e.includes?("spawn") && e.includes?("invalid")
      }
      spawn_errors.should be_empty
    end
  end
end
