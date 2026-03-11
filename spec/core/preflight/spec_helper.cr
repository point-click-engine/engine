require "../../spec_helper"
require "../../../src/core/preflight_check"
require "../../../src/core/game_config"

def cleanup_test_files
  test_files = [
    "test_game.yaml",
    "test_scene.yaml",
    "test_sprite.png",
    "test_music.ogg",
    "test_sound.wav",
  ]

  test_dirs = [
    "test_game_dir",
    "test_audio",
    "test_saves",
    "test_locales",
    "test_dialogs",
    "test_shaders",
  ]

  test_files.each { |f| File.delete(f) if File.exists?(f) }
  test_dirs.each { |d| FileUtils.rm_rf(d) if Dir.exists?(d) }

  generated_files = [
    "test_scenes/intro.yaml",
    "test_sprites/player.png",
    "test_audio/theme.ogg",
    "user_settings.yaml",
    "invalid.yaml",
  ]

  generated_files.each { |f| File.delete(f) if File.exists?(f) }

  # Baseline sprite fixture used by create_minimal_config
  File.write("test_sprite.png", "fake_png_data")
end

def create_minimal_config(additional_config = "")
  <<-YAML
  game:
    title: "Test Game"
    version: "1.0.0"
  window:
    width: 1024
    height: 768
  player:
    name: "Test Player"
    sprite_path: "test_sprite.png"
    sprite:
      frame_width: 32
      frame_height: 48
      columns: 4
      rows: 4
    start_position:
      x: 512.0
      y: 384.0
  start_scene: "intro"
  #{additional_config}
  YAML
end

def create_test_scene(name : String, additional_config = "")
  <<-YAML
  name: #{name}
  background_path: "test_sprite.png"
  walkable_areas:
    regions:
      - name: floor
        walkable: true
        vertices:
          - {x: 0, y: 0}
          - {x: 100, y: 0}
          - {x: 100, y: 100}
          - {x: 0, y: 100}
  #{additional_config}
  YAML
end

def create_test_directory_structure
  Dir.mkdir_p("test_scenes")
  Dir.mkdir_p("test_sprites")
  Dir.mkdir_p("test_audio")
  Dir.mkdir_p("test_saves")
  Dir.mkdir_p("test_locales")
  Dir.mkdir_p("test_dialogs")
end
