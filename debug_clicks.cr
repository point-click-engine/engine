#!/usr/bin/env crystal
# Minimal test to debug click handling

require "./src/point_click_engine"

# Override engine to add debug logging at the game loop level
class DebugEngine < PointClickEngine::Core::Engine
  def initialize(width : Int32, height : Int32, title : String)
    super(width, height, title)
    puts "🔧 DEBUG: DebugEngine initialized"
  end

  private def update
    dt = RL.get_frame_time

    # Check for mouse clicks at the engine level
    if RL.mouse_button_pressed?(RL::MouseButton::Left)
      mouse_pos = RL.get_mouse_position
      puts "\n🖱️  DEBUG ENGINE: Mouse clicked at (#{mouse_pos.x}, #{mouse_pos.y})"
      puts "🎮 DEBUG ENGINE: Current scene: #{@current_scene ? @current_scene.not_nil!.name : "None"}"
      puts "🎮 DEBUG ENGINE: Player exists: #{@player ? "Yes" : "No"}"
      puts "🎮 DEBUG ENGINE: Input handler handle_clicks: #{@input_handler.handle_clicks}"
    end

    # Call parent update
    super
  end
end

# Create minimal test
puts "🚀 Starting Click Debug Test"

engine = DebugEngine.new(800, 600, "Click Debug")
PointClickEngine::Core::Engine.debug_mode = true
engine.init

# Create basic scene
scene = PointClickEngine::Scenes::Scene.new("debug_room")

# Create player
player = PointClickEngine::Characters::Player.new("DebugPlayer",
  RL::Vector2.new(x: 400, y: 300),
  RL::Vector2.new(x: 32, y: 64))

puts "🎮 Player created at: (#{player.position.x}, #{player.position.y})"
puts "🎮 Player movement enabled: #{player.movement_enabled}"

# Setup scene and player
scene.set_player(player)
engine.player = player
engine.add_scene(scene)
engine.change_scene("debug_room")

puts "✅ Setup complete"
puts "🖱️  Click anywhere to test - debug output will show what happens"
puts "🔄 Press F1 to toggle debug mode"

engine.run
