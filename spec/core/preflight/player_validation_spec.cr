require "./spec_helper"

describe "PreflightCheck Player Configuration Validation" do
  before_each do
    cleanup_test_files
  end

  after_each do
    cleanup_test_files
  end

  it "detects a missing player sprite" do
    config_yaml = <<-YAML
    game:
      title: "Test Game"
    window:
      width: 1024
      height: 768
    player:
      name: "Hero"
      sprite_path: "missing/player_does_not_exist.png"
      sprite:
        frame_width: 32
        frame_height: 64
        columns: 4
        rows: 4
      start_position:
        x: 50.0
        y: 50.0
    YAML
    File.write("test_game.yaml", config_yaml)

    result = PointClickEngine::Core::PreflightCheck.run("test_game.yaml")

    result.errors.any? { |error| error.includes?("Player sprite not found") }.should be_true
  end

  it "validates sprite dimensions and warns about very large frames" do
    Dir.mkdir_p("test_game_dir/sprites")
    File.write("test_game_dir/sprites/player.png", "fake_png_data")

    invalid_config = <<-YAML
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
      start_position:
        x: 50.0
        y: 50.0
    YAML
    File.write("test_game_dir/test_game.yaml", invalid_config)

    invalid_result = PointClickEngine::Core::PreflightCheck.run("test_game_dir/test_game.yaml")
    invalid_result.errors.any? do |error|
      error.includes?("frame dimensions must be positive") ||
        error.includes?("frame_width must be positive") ||
        error.includes?("frame_height must be positive")
    end.should be_true

    large_config = <<-YAML
    game:
      title: "Test Game"
    window:
      width: 1024
      height: 768
    player:
      name: "Hero"
      sprite_path: "sprites/player.png"
      sprite:
        frame_width: 600
        frame_height: 600
        columns: 4
        rows: 4
      start_position:
        x: 50.0
        y: 50.0
    YAML
    File.write("test_game_dir/test_game.yaml", large_config)

    large_result = PointClickEngine::Core::PreflightCheck.run("test_game_dir/test_game.yaml")
    large_result.warnings.any? { |warning| warning.includes?("Player sprite frames are very large") }.should be_true
  end

  it "accepts a valid player configuration" do
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
        frame_width: 64
        frame_height: 96
        columns: 8
        rows: 4
      start_position:
        x: 50.0
        y: 50.0
    YAML
    File.write("test_game_dir/test_game.yaml", config_yaml)

    result = PointClickEngine::Core::PreflightCheck.run("test_game_dir/test_game.yaml")

    result.errors.select { |error| error.includes?("Player sprite") }.should be_empty
  end

  it "validates start_position against the configured start scene" do
    Dir.mkdir_p("test_scenes")
    File.write("test_scenes/intro.yaml", create_test_scene("intro"))

    outside_config = <<-YAML
    game:
      title: "Test Game"
      version: "1.0.0"
    window:
      width: 1024
      height: 768
    player:
      name: "Hero"
      sprite_path: "spec/fixtures/assets/test_sprite.png"
      sprite:
        frame_width: 32
        frame_height: 48
        columns: 4
        rows: 4
      start_position:
        x: 500.0
        y: 500.0
    assets:
      scenes:
        - "test_scenes/*.yaml"
    start_scene: "intro"
    YAML
    File.write("test_game.yaml", outside_config)

    outside_result = PointClickEngine::Core::PreflightCheck.run("test_game.yaml")
    outside_result.errors.any? { |error| error.includes?("outside walkable areas") }.should be_true

    valid_config = <<-YAML
    game:
      title: "Test Game"
      version: "1.0.0"
    window:
      width: 1024
      height: 768
    player:
      name: "Hero"
      sprite_path: "spec/fixtures/assets/test_sprite.png"
      sprite:
        frame_width: 32
        frame_height: 48
        columns: 4
        rows: 4
      start_position:
        x: 50.0
        y: 50.0
    assets:
      scenes:
        - "test_scenes/*.yaml"
    start_scene: "intro"
    YAML
    File.write("test_game.yaml", valid_config)

    valid_result = PointClickEngine::Core::PreflightCheck.run("test_game.yaml")
    valid_result.errors.none? { |error| error.includes?("walkable") }.should be_true
  end
end
