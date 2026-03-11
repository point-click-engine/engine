require "./spec_helper"

describe "PreflightCheck Performance Analysis" do
  before_each do
    cleanup_test_files
  end

  after_each do
    cleanup_test_files
  end

  it "reports entity-heavy scenes as performance hints" do
    Dir.mkdir_p("test_game_dir/scenes")
    File.write("test_game_dir/bg.png", "fake_png")
    scene_yaml = String.build do |io|
      io << "name: busy_scene\n"
      io << "background_path: bg.png\n"
      io << "hotspots:\n"
      (1..51).each do |i|
        io << "  - name: hotspot_#{i}\n"
        io << "    x: #{i}\n"
        io << "    y: #{i}\n"
        io << "    width: 10\n"
        io << "    height: 10\n"
      end
    end
    File.write("test_game_dir/scenes/busy_scene.yaml", scene_yaml)

    config_yaml = <<-YAML
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
    File.write("test_game_dir/game.yaml", config_yaml)

    result = PointClickEngine::Core::PreflightCheck.run("test_game_dir/game.yaml")

    result.performance_hints.any? { |hint| hint.includes?("has 51 entities") }.should be_true
  end

  it "reports large assets and audio compression hints" do
    Dir.mkdir_p("test_game_dir/audio")
    Dir.mkdir_p("test_game_dir/scenes")
    File.write("test_game_dir/audio/huge_sound.wav", "x" * 12_000_000)
    File.write("test_game_dir/scenes/test.yaml", <<-YAML
      name: test
      background_path: test_sprite.png
      background_music: test_game_dir/audio/huge_sound.wav
    YAML
    )

    config_yaml = create_minimal_config(<<-YAML
    assets:
      scenes:
        - "test_game_dir/scenes/*.yaml"
      audio:
        sounds:
          huge: "test_game_dir/audio/huge_sound.wav"
    YAML
    )
    File.write("test_game.yaml", config_yaml)

    result = PointClickEngine::Core::PreflightCheck.run("test_game.yaml")

    result.performance_hints.any? { |hint| hint.includes?("Large sound effect 'huge'") || hint.includes?("Large WAV sound 'huge'") }.should be_true
    result.performance_hints.any? { |hint| hint.includes?("Large assets found") }.should be_true
  end

  it "reports estimated memory usage for heavy texture sets" do
    Dir.mkdir_p("test_game_dir/sprites")
    20.times do |i|
      File.write("test_game_dir/sprites/sprite_#{i}.png", "x" * 5_000_000)
    end

    config_yaml = <<-YAML
    game:
      title: "Test Game"
    window:
      width: 1920
      height: 1080
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
      sprites:
        - "sprites/*.png"
    YAML
    File.write("test_game_dir/game.yaml", config_yaml)

    result = PointClickEngine::Core::PreflightCheck.run("test_game_dir/game.yaml")

    result.info.any? { |info| info.includes?("Estimated texture memory usage:") }.should be_true
    result.performance_hints.any? { |hint| hint.includes?("Estimated memory usage") }.should be_true
  end

  it "reports potential slow loading for large scene payloads" do
    Dir.mkdir_p("test_game_dir/scenes")
    Dir.mkdir_p("test_game_dir/audio")
    File.write("test_game_dir/big_bg.png", "x" * 15_000_000)
    File.write("test_game_dir/audio/slow_music.wav", "x" * 30_000_000)
    File.write("test_game_dir/scenes/slow_scene.yaml", <<-YAML
      name: slow_scene
      background_path: big_bg.png
      background_music: audio/slow_music.wav
    YAML
    )

    config_yaml = <<-YAML
    game:
      title: "Test Game"
    window:
      width: 800
      height: 600
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
      audio:
        music:
          slow_music: "audio/slow_music.wav"
    YAML
    File.write("test_game_dir/game.yaml", config_yaml)

    result = PointClickEngine::Core::PreflightCheck.run("test_game_dir/game.yaml")

    result.performance_hints.any? { |hint| hint.includes?("may have slow loading time") }.should be_true
  end
end
