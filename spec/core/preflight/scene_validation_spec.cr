require "./spec_helper"

describe "PreflightCheck Scene Validation" do
  before_each do
    cleanup_test_files
  end

  after_each do
    cleanup_test_files
  end

  it "detects missing scene background files" do
    Dir.mkdir_p("test_game_dir/scenes")
    File.write("test_game_dir/scenes/intro.yaml", <<-YAML
      name: intro
      background_path: "backgrounds/missing_bg.png"
    YAML
    )

    File.write("test_game_dir/game.yaml", <<-YAML
      game:
        title: "Test Game"
      window:
        width: 1024
        height: 768
      player:
        sprite_path: "../test_sprite.png"
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
          - "scenes/*.yaml"
    YAML
    )

    result = PointClickEngine::Core::PreflightCheck.run("test_game_dir/game.yaml")

    result.errors.any? { |error| error.includes?("Background") || error.includes?("Missing background") }.should be_true
  end

  it "detects missing background_path fields and invalid hotspot definitions" do
    Dir.mkdir_p("test_game_dir/scenes")
    File.write("test_game_dir/scenes/intro.yaml", <<-YAML
      name: intro
      hotspots:
        - name: invalid_hotspot
          width: 100
          height: 100
        - name: negative_size
          x: 100
          y: 100
          width: -50
          height: 0
    YAML
    )

    File.write("test_game_dir/game.yaml", <<-YAML
      game:
        title: "Test Game"
      window:
        width: 1024
        height: 768
      player:
        sprite_path: "../test_sprite.png"
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
          - "scenes/*.yaml"
    YAML
    )

    result = PointClickEngine::Core::PreflightCheck.run("test_game_dir/game.yaml")

    result.errors.any? { |error| error.includes?("Missing required field 'background_path'") }.should be_true
    result.errors.any? { |error| error.includes?("Hotspot #1: Missing required field 'x'") }.should be_true
    result.errors.any? { |error| error.includes?("Hotspot #2: width cannot be negative") }.should be_true
  end

  it "detects broken scene references and accepts valid ones" do
    Dir.mkdir_p("test_game_dir/scenes")
    File.write("test_game_dir/bg.png", "fake_png")
    File.write("test_game_dir/scenes/intro.yaml", <<-YAML
      name: intro
      background_path: bg.png
      hotspots:
        - name: exit_door
          x: 400
          y: 300
          width: 100
          height: 200
          target_scene: missing_scene
    YAML
    )

    File.write("test_game_dir/game.yaml", <<-YAML
      game:
        title: "Test Game"
      window:
        width: 1024
        height: 768
      player:
        sprite_path: "../test_sprite.png"
        sprite:
          frame_width: 32
          frame_height: 48
          columns: 4
          rows: 4
        start_position:
          x: 50.0
          y: 50.0
      start_scene: "intro"
      assets:
        scenes:
          - "scenes/*.yaml"
    YAML
    )

    broken_result = PointClickEngine::Core::PreflightCheck.run("test_game_dir/game.yaml")
    broken_result.errors.any? { |error| error.includes?("references non-existent scene 'missing_scene'") }.should be_true

    File.write("test_game_dir/scenes/hallway.yaml", <<-YAML
      name: hallway
      background_path: bg.png
      hotspots:
        - name: back_door
          x: 100
          y: 300
          width: 100
          height: 200
          target_scene: intro
    YAML
    )
    File.write("test_game_dir/scenes/intro.yaml", <<-YAML
      name: intro
      background_path: bg.png
      hotspots:
        - name: exit_door
          x: 400
          y: 300
          width: 100
          height: 200
          target_scene: hallway
    YAML
    )

    valid_result = PointClickEngine::Core::PreflightCheck.run("test_game_dir/game.yaml")
    valid_result.errors.none? { |error| error.includes?("references non-existent scene") }.should be_true
  end

  it "accepts scenes with existing backgrounds and valid structure" do
    Dir.mkdir_p("test_game_dir/scenes")
    Dir.mkdir_p("test_game_dir/backgrounds")
    File.write("test_game_dir/backgrounds/intro_bg.png", "fake_png")
    File.write("test_game_dir/scenes/intro.yaml", <<-YAML
      name: intro
      background_path: backgrounds/intro_bg.png
      walkable_areas:
        regions:
          - name: floor
            walkable: true
            vertices:
              - {x: 0, y: 0}
              - {x: 100, y: 0}
              - {x: 100, y: 100}
              - {x: 0, y: 100}
    YAML
    )

    File.write("test_game_dir/game.yaml", <<-YAML
      game:
        title: "Test Game"
      window:
        width: 1024
        height: 768
      player:
        sprite_path: "../test_sprite.png"
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
          - "scenes/*.yaml"
    YAML
    )

    result = PointClickEngine::Core::PreflightCheck.run("test_game_dir/game.yaml")

    result.errors.none? { |error| error.includes?("background") || error.includes?("Background") }.should be_true
  end
end
