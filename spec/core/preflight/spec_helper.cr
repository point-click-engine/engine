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
    "test_scenes",
    "test_audio",
    "test_sprites",
    "test_saves",
    "test_locales",
    "test_dialogs",
    "test_shaders",
    "locales",
    "saves",
    "dialogs",
    "scripts",
  ]

  test_files.each { |f| File.delete(f) if File.exists?(f) }
  test_dirs.each { |d| FileUtils.rm_rf(d) if Dir.exists?(d) }
end

def create_minimal_config(additional_config = "")
  <<-YAML
  game:
    title: "Test Game"
    version: "1.0.0"
  window:
    width: 1024
    height: 768
  start_scene: "intro"
  #{additional_config}
  YAML
end

def create_test_scene(name : String, additional_config = "")
  <<-YAML
  name: #{name}
  background: "test_sprite.png"
  walkable_areas:
    - polygon:
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
