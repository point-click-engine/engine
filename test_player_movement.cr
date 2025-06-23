#!/usr/bin/env crystal
# Player Movement Debug Test
# This test creates a simple scene to debug player movement issues

require "./src/point_click_engine"

# Debug-enabled Player class with extensive logging
class DebugPlayer < PointClickEngine::Characters::Player
  def initialize(name : String, position : RL::Vector2, size : RL::Vector2)
    super(name, position, size)
    puts "🎮 DEBUG: Player initialized at position (#{position.x}, #{position.y})"
  end

  def handle_click(mouse_pos : RL::Vector2, scene : PointClickEngine::Scenes::Scene)
    puts "\n🖱️  DEBUG: Mouse clicked at (#{mouse_pos.x}, #{mouse_pos.y})"
    puts "🧭 DEBUG: Player current position: (#{@position.x}, #{@position.y})"
    puts "🚶 DEBUG: Movement enabled: #{@movement_enabled}"

    unless @movement_enabled
      puts "❌ DEBUG: Movement is disabled!"
      return
    end

    # Check if the target is walkable
    walkable = scene.is_walkable?(mouse_pos)
    puts "🚶 DEBUG: Is position walkable? #{walkable}"

    if walkable_area = scene.walkable_area
      puts "🔧 DEBUG: Scene has walkable area defined"
      puts "🔧 DEBUG: Walkable area regions: #{walkable_area.regions.size}"
      walkable_area.regions.each_with_index do |region, i|
        puts "   Region #{i}: #{region.vertices.size} vertices, walkable: #{region.walkable}"
      end
    else
      puts "⚠️  DEBUG: No walkable area defined - all positions should be walkable"
    end

    unless walkable
      puts "❌ DEBUG: Target position is not walkable, stopping movement"
      return
    end

    puts "✅ DEBUG: Starting movement to (#{mouse_pos.x}, #{mouse_pos.y})"

    # Start walking with enhanced animations
    walk_to(mouse_pos)
    puts "🎯 DEBUG: walk_to() called successfully"
  end

  def walk_to(target : RL::Vector2)
    puts "🚶 DEBUG: walk_to() called with target (#{target.x}, #{target.y})"
    puts "🎯 DEBUG: Setting target position and state"

    super(target) # Call parent implementation

    puts "🔄 DEBUG: Character state set to: #{@state}"
    puts "🎯 DEBUG: Target position set to: #{@target_position}"
    puts "🧭 DEBUG: Direction set to: #{@direction}"
  end

  def update(dt : Float32)
    # Add debug output for movement updates
    if @state == PointClickEngine::Characters::CharacterState::Walking
      if @target_position
        distance = Math.sqrt((@target_position.not_nil!.x - @position.x) ** 2 + (@target_position.not_nil!.y - @position.y) ** 2)
        puts "🔄 DEBUG: Walking... Distance to target: #{distance.round(2)}"
      end
    end

    super(dt)
  end

  def stop_walking
    puts "🛑 DEBUG: stop_walking() called"
    puts "🎯 DEBUG: Previous state: #{@state}"
    super
    puts "✅ DEBUG: Movement stopped, new state: #{@state}"
  end
end

# Debug Scene class with walkable area logging
class DebugScene < PointClickEngine::Scenes::Scene
  def initialize(name : String)
    super(name)
    puts "🏠 DEBUG: Scene '#{name}' initialized"
  end

  def is_walkable?(point : RL::Vector2) : Bool
    puts "🔍 DEBUG: Checking if point (#{point.x}, #{point.y}) is walkable"

    if walkable = @walkable_area
      result = walkable.is_point_walkable?(point)
      puts "🔍 DEBUG: Walkable area check result: #{result}"
      return result
    else
      puts "🔍 DEBUG: No walkable area defined, returning true"
      return true
    end
  end
end

# Main test class
class PlayerMovementTest
  property engine : PointClickEngine::Core::Engine
  property scene : DebugScene
  property player : DebugPlayer

  def initialize
    puts "🚀 Starting Player Movement Debug Test"

    # Create engine
    @engine = PointClickEngine::Core::Engine.new(800, 600, "Player Movement Test")

    # Enable debug mode
    PointClickEngine::Core::Engine.debug_mode = true
    puts "🔧 DEBUG: Debug mode enabled"

    # Initialize engine
    @engine.init
    puts "✅ Engine initialized"

    # Create test scene
    @scene = DebugScene.new("test_room")

    # Create simple walkable area (optional - comment out to test without walkable area)
    setup_walkable_area

    # Create debug player
    @player = DebugPlayer.new("TestPlayer", RL::Vector2.new(x: 100, y: 200), RL::Vector2.new(x: 32, y: 64))

    # Set up player in scene
    @scene.set_player(@player)
    @engine.player = @player

    # Add scene to engine
    @engine.add_scene(@scene)
    @engine.change_scene("test_room")

    puts "🎮 Test setup complete!"
    puts "🖱️  Click anywhere to test player movement"
    puts "📊 Debug output will show mouse clicks, walkable checks, and movement commands"
    puts "🎯 Press F1 to toggle debug mode"
    puts "🔄 Press ESC to show pause menu"
  end

  def setup_walkable_area
    puts "🏠 DEBUG: Setting up walkable area"

    # Create a simple rectangular walkable area
    walkable_area = PointClickEngine::Scenes::WalkableArea.new

    # Define a large walkable rectangle (most of the screen)
    walkable_region = PointClickEngine::Scenes::PolygonRegion.new("walkable_main", true)
    walkable_region.vertices = [
      RL::Vector2.new(x: 50, y: 150),  # top-left
      RL::Vector2.new(x: 750, y: 150), # top-right
      RL::Vector2.new(x: 750, y: 550), # bottom-right
      RL::Vector2.new(x: 50, y: 550),  # bottom-left
    ]

    walkable_area.regions << walkable_region

    # Add a small non-walkable obstacle in the middle
    obstacle_region = PointClickEngine::Scenes::PolygonRegion.new("obstacle", false)
    obstacle_region.vertices = [
      RL::Vector2.new(x: 350, y: 250), # top-left
      RL::Vector2.new(x: 450, y: 250), # top-right
      RL::Vector2.new(x: 450, y: 350), # bottom-right
      RL::Vector2.new(x: 350, y: 350), # bottom-left
    ]

    walkable_area.regions << obstacle_region
    @scene.walkable_area = walkable_area

    puts "✅ DEBUG: Walkable area created with #{walkable_area.regions.size} regions"
  end

  def run
    puts "🎮 Starting game loop..."
    @engine.run
  end
end

# Custom input handler for additional debugging
class DebugInputHandler < PointClickEngine::Core::EngineComponents::InputHandler
  def handle_click(scene : PointClickEngine::Scenes::Scene?, player : PointClickEngine::Characters::Character?, camera : PointClickEngine::Graphics::Camera? = nil)
    puts "\n🖱️  DEBUG: InputHandler.handle_click() called"
    puts "🔧 DEBUG: handle_clicks enabled: #{@handle_clicks}"
    puts "🏠 DEBUG: Scene present: #{scene ? "Yes" : "No"}"
    puts "🎮 DEBUG: Player present: #{player ? "Yes" : "No"}"
    puts "🖱️  DEBUG: Left mouse button pressed: #{RL.mouse_button_pressed?(RL::MouseButton::Left)}"

    if scene && player && RL.mouse_button_pressed?(RL::MouseButton::Left)
      mouse_pos = RL.get_mouse_position
      puts "🖱️  DEBUG: Raw mouse position: (#{mouse_pos.x}, #{mouse_pos.y})"

      # Convert screen coordinates to world coordinates if camera exists
      world_pos = if camera
                    converted = camera.screen_to_world(mouse_pos.x.to_i, mouse_pos.y.to_i)
                    puts "🧭 DEBUG: Converted to world coordinates: (#{converted.x}, #{converted.y})"
                    converted
                  else
                    puts "🧭 DEBUG: No camera, using screen coordinates"
                    mouse_pos
                  end

      # Check if any hotspot was clicked
      clicked_hotspot = scene.get_hotspot_at(world_pos)
      puts "🎯 DEBUG: Hotspot at position: #{clicked_hotspot ? clicked_hotspot.name : "None"}"

      if clicked_hotspot
        puts "🎯 DEBUG: Executing hotspot click"
        clicked_hotspot.on_click.try(&.call)
      else
        puts "🎮 DEBUG: No hotspot clicked, attempting player movement"
        if player.responds_to?(:handle_click)
          player.handle_click(world_pos, scene)
        else
          puts "❌ DEBUG: Player does not respond to handle_click"
        end
      end
    end

    # Call parent implementation for other functionality
    super
  end
end

# Run the test
puts "🔧 Creating Player Movement Debug Test..."
test = PlayerMovementTest.new

# Replace the input handler with our debug version
debug_input_handler = DebugInputHandler.new
test.engine.input_handler = debug_input_handler

test.run
