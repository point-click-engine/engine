require "./src/core/game_config"

yaml_content = <<-YAML
game:
  title: "Test Game"
  version: "1.0.0"
  author: "Test Author"

window:
  width: 800
  height: 600
  fullscreen: false
  target_fps: 60

player:
  name: "TestPlayer"
  sprite_path: "assets/player.png"
  sprite:
    frame_width: 32
    frame_height: 32
    columns: 4
    rows: 4

features:
  - verbs
  - floating_dialogs

start_scene: "intro"
YAML

begin
  config = PointClickEngine::Core::GameConfig.from_yaml(yaml_content)
  puts "Success! Loaded config: #{config.game.title}"
rescue ex
  puts "Error: #{ex.class} - #{ex.message}"
  puts ex.backtrace.first(5).join("\n")
end
