require "./spec_helper"

describe "PreflightCheck Development Environment" do
  before_each do
    cleanup_test_files
  end

  after_each do
    cleanup_test_files
  end

  it "reports Crystal runtime and operating system information" do
    File.write("test_game.yaml", create_minimal_config)

    result = PointClickEngine::Core::PreflightCheck.run("test_game.yaml")

    result.info.any? { |info| info.includes?("Running on Crystal") }.should be_true
    result.info.any? { |info| info.includes?("Operating System:") }.should be_true
  end

  it "reports development tools and platform capabilities" do
    File.write("test_game.yaml", create_minimal_config)

    result = PointClickEngine::Core::PreflightCheck.run("test_game.yaml")

    result.info.any? { |info| info.includes?("Development tools") }.should be_true
    result.info.any? { |info| info.includes?("Platform capabilities:") }.should be_true
  end

  it "reports resource summary when assets are configured" do
    create_test_directory_structure
    File.write("test_sprites/player.png", "fake_png")
    File.write("test_audio/theme.ogg", "fake_ogg")
    File.write("test_scenes/intro.yaml", create_test_scene("intro"))

    config_yaml = <<-YAML
    game:
      title: "Test Game"
      version: "1.0.0"
    window:
      width: 1024
      height: 768
    player:
      name: "Test Player"
      sprite_path: "test_sprites/player.png"
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
      audio:
        music:
          theme: "test_audio/theme.ogg"
    start_scene: "intro"
    YAML
    File.write("test_game.yaml", config_yaml)

    result = PointClickEngine::Core::PreflightCheck.run("test_game.yaml")

    result.info.any? { |info| info.includes?("Resource summary:") }.should be_true
    result.info.any? { |info| info.includes?("Total asset size:") }.should be_true
  end
end
