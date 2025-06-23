#!/usr/bin/env crystal
# Simple Player Movement Test - No walkable areas, just basic movement

require "./src/point_click_engine"

# Test if the basic movement system works without any constraints
class SimpleMovementTest
  def initialize
    puts "🚀 Simple Movement Test Starting..."
    
    # Create minimal engine setup
    @engine = PointClickEngine::Core::Engine.new(800, 600, "Simple Movement Test")
    PointClickEngine::Core::Engine.debug_mode = true
    @engine.init
    
    # Create simple scene without walkable areas
    @scene = PointClickEngine::Scenes::Scene.new("simple_room")
    
    # Create player
    @player = PointClickEngine::Characters::Player.new("TestPlayer", 
                                                        RL::Vector2.new(x: 400, y: 300), 
                                                        RL::Vector2.new(x: 32, y: 64))
    
    # Load a simple sprite for the player (optional - will work without)
    # @player.load_spritesheet("assets/player.png", 32, 64)
    
    # Set up basic animations
    @player.add_animation("idle", 0, 1, 0.5, true)
    @player.add_animation("walk_left", 0, 4, 0.15, true)
    @player.add_animation("walk_right", 4, 4, 0.15, true)
    
    # Add player to scene and engine
    @scene.set_player(@player)
    @engine.player = @player
    @engine.add_scene(@scene)
    @engine.change_scene("simple_room")
    
    # Enable click handling explicitly
    @engine.handle_clicks = true
    
    puts "✅ Simple setup complete - click anywhere to move!"
    puts "🎮 Player at: (#{@player.position.x}, #{@player.position.y})"
    puts "🎯 Movement enabled: #{@player.movement_enabled}"
    puts "🖱️  Click handling enabled: #{@engine.handle_clicks}"
  end

  def run
    @engine.run
  end
end

# Additional debugging by overriding the input processing
module PointClickEngine
  module Core
    module EngineComponents
      class InputHandler
        # Override to add debug logging
        def process_input(scene : Scenes::Scene?, player : Characters::Character?, camera : Graphics::Camera? = nil)
          # Debug keyboard input
          if RL.key_pressed?(RL::KeyboardKey::Space)
            puts "\n🔍 DEBUG INFO:"
            puts "  Scene: #{scene ? scene.name : "None"}"
            puts "  Player: #{player ? player.name : "None"}"
            puts "  Player pos: #{player ? "(#{player.position.x}, #{player.position.y})" : "N/A"}"
            puts "  Player state: #{player ? player.state : "N/A"}"
            puts "  Handle clicks: #{@handle_clicks}"
          end
          
          # Check for mouse input with detailed logging
          if RL.mouse_button_pressed?(RL::MouseButton::Left)
            mouse_pos = RL.get_mouse_position
            puts "\n🖱️  MOUSE CLICK DEBUG:"
            puts "  Raw position: (#{mouse_pos.x}, #{mouse_pos.y})"
            puts "  Handle clicks enabled: #{@handle_clicks}"
            puts "  Scene present: #{scene ? "Yes" : "No"}"
            puts "  Player present: #{player ? "Yes" : "No"}"
            
            if !@handle_clicks
              puts "  ❌ Click handling is DISABLED"
            end
            
            if scene && player && @handle_clicks
              puts "  ✅ Conditions met for movement"
              
              # Check walkable area
              walkable = scene.is_walkable?(mouse_pos)
              puts "  Walkable check: #{walkable}"
              
              if walkable
                puts "  🎯 Calling player.handle_click"
                if player.responds_to?(:handle_click)
                  player.handle_click(mouse_pos, scene)
                  puts "  ✅ handle_click called successfully"
                else
                  puts "  ❌ Player does not respond to handle_click"
                end
              else
                puts "  ❌ Position not walkable"
              end
            end
          end
          
          # Call original method
          handle_keyboard_input
          handle_click(scene, player, camera)
          handle_right_click(scene, camera)
        end
      end
    end
  end
end

puts "🔧 Starting Simple Movement Test..."
test = SimpleMovementTest.new
puts "🎮 Press SPACE for debug info"
puts "🖱️  Click anywhere to test movement"
test.run