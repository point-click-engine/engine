#!/usr/bin/env crystal
# Comprehensive Movement Test - All debugging features in one place

require "./src/point_click_engine"

# All-in-one debug test that checks every aspect of the movement system
class ComprehensiveMovementTest
  property engine : PointClickEngine::Core::Engine
  property scene : PointClickEngine::Scenes::Scene
  property player : PointClickEngine::Characters::Player
  property test_mode : String = "walkable"

  def initialize(mode : String = "walkable")
    @test_mode = mode
    puts "🚀 COMPREHENSIVE MOVEMENT TEST - Mode: #{mode}"
    puts "=" * 60
    
    setup_engine
    setup_scene
    setup_player
    setup_walkable_areas if mode == "walkable"
    finalize_setup
    
    print_test_info
  end

  def setup_engine
    puts "⚙️  Setting up engine..."
    @engine = PointClickEngine::Core::Engine.new(800, 600, "Movement Test - #{@test_mode}")
    
    # Enable debug mode for visual feedback
    PointClickEngine::Core::Engine.debug_mode = true
    
    @engine.init
    puts "   ✅ Engine initialized"
    puts "   🔧 Debug mode: #{PointClickEngine::Core::Engine.debug_mode}"
    puts "   🖱️  Handle clicks: #{@engine.handle_clicks}"
  end

  def setup_scene
    puts "🏠 Setting up scene..."
    @scene = PointClickEngine::Scenes::Scene.new("test_room_#{@test_mode}")
    puts "   ✅ Scene '#{@scene.name}' created"
  end

  def setup_player
    puts "🎮 Setting up player..."
    @player = PointClickEngine::Characters::Player.new(
      "TestPlayer", 
      RL::Vector2.new(x: 400, y: 300), 
      RL::Vector2.new(x: 32, y: 64)
    )
    
    # Add basic animations
    @player.add_animation("idle", 0, 1, 0.5, true)
    @player.add_animation("walk_left", 0, 4, 0.15, true)
    @player.add_animation("walk_right", 4, 4, 0.15, true)
    
    puts "   ✅ Player created at (#{@player.position.x}, #{@player.position.y})"
    puts "   🚶 Movement enabled: #{@player.movement_enabled}"
    puts "   🏃 Walking speed: #{@player.walking_speed}"
    puts "   🎯 Use pathfinding: #{@player.use_pathfinding}"
  end

  def setup_walkable_areas
    puts "🗺️  Setting up walkable areas..."
    
    walkable_area = PointClickEngine::Scenes::WalkableArea.new
    
    # Main walkable area (green in debug view)
    main_area = PointClickEngine::Scenes::PolygonRegion.new("main_walkable", true)
    main_area.vertices = [
      RL::Vector2.new(x: 100, y: 100),
      RL::Vector2.new(x: 700, y: 100),
      RL::Vector2.new(x: 700, y: 500),
      RL::Vector2.new(x: 100, y: 500)
    ]
    walkable_area.regions << main_area
    
    # Small obstacle (red in debug view)
    obstacle = PointClickEngine::Scenes::PolygonRegion.new("obstacle", false)
    obstacle.vertices = [
      RL::Vector2.new(x: 350, y: 200),
      RL::Vector2.new(x: 450, y: 200),
      RL::Vector2.new(x: 450, y: 300),
      RL::Vector2.new(x: 350, y: 300)
    ]
    walkable_area.regions << obstacle
    
    @scene.walkable_area = walkable_area
    puts "   ✅ Walkable area with #{walkable_area.regions.size} regions"
    puts "   🟢 Main walkable: 100,100 to 700,500"
    puts "   🔴 Obstacle: 350,200 to 450,300"
  end

  def finalize_setup
    puts "🔗 Finalizing setup..."
    
    # Connect everything
    @scene.set_player(@player)
    @engine.player = @player
    @engine.add_scene(@scene)
    @engine.change_scene(@scene.name)
    
    puts "   ✅ Player added to scene"
    puts "   ✅ Scene added to engine"
    puts "   ✅ Scene activated"
  end

  def print_test_info
    puts "\n📋 TEST INFORMATION"
    puts "-" * 40
    puts "🎮 Player position: (#{@player.position.x}, #{@player.position.y})"
    puts "🎯 Click handling: #{@engine.handle_clicks}"
    puts "🏠 Current scene: #{@engine.current_scene ? @engine.current_scene.not_nil!.name : "None"}"
    puts "🗺️  Walkable area: #{@scene.walkable_area ? "Yes" : "No"}"
    
    if walkable = @scene.walkable_area
      puts "   📍 Regions: #{walkable.regions.size}"
      walkable.regions.each_with_index do |region, i|
        puts "      #{i+1}. #{region.name} (#{region.walkable ? "walkable" : "blocked"})"
      end
    end

    puts "\n🎯 TEST INSTRUCTIONS"
    puts "-" * 40
    puts "🖱️  LEFT CLICK: Move player to position"
    puts "🎯 F1: Toggle debug visualization"
    puts "📊 TAB: Toggle hotspot highlighting"
    puts "⏸️  ESC: Pause menu"
    puts "❌ Close window to exit"
    
    puts "\n🔍 EXPECTED BEHAVIOR"
    puts "-" * 40
    case @test_mode
    when "walkable"
      puts "✅ Player should move within green areas"
      puts "❌ Player should NOT move to red areas"
      puts "🔍 Debug view shows walkable areas in green/red"
    else
      puts "✅ Player should move to any clicked position"
      puts "🔍 No movement restrictions"
    end
    
    puts "\n🚀 Starting test... Click to begin!"
    puts "=" * 60
  end

  def run
    # Override input handler for this test
    debug_handler = create_debug_input_handler
    @engine.input_handler = debug_handler
    
    @engine.run
  end

  private def create_debug_input_handler
    original_handler = @engine.input_handler
    
    # Create a wrapper that adds debugging
    debug_handler = PointClickEngine::Core::EngineComponents::InputHandler.new
    
    # Override the handle_click method with debugging
    class << debug_handler
      def handle_click(scene : PointClickEngine::Scenes::Scene?, player : PointClickEngine::Characters::Character?, camera : PointClickEngine::Graphics::Camera? = nil)
        return unless @handle_clicks
        return unless scene
        return unless RL.mouse_button_pressed?(RL::MouseButton::Left)

        mouse_pos = RL.get_mouse_position
        puts "\n🖱️  === CLICK DEBUG ==="
        puts "📍 Raw position: (#{mouse_pos.x}, #{mouse_pos.y})"

        # Convert screen coordinates to world coordinates if camera exists
        world_pos = if camera
                      converted = camera.screen_to_world(mouse_pos.x.to_i, mouse_pos.y.to_i)
                      puts "🧭 World position: (#{converted.x}, #{converted.y})"
                      converted
                    else
                      puts "🧭 No camera - using screen coordinates"
                      mouse_pos
                    end

        # Check walkable area
        walkable = scene.is_walkable?(world_pos)
        puts "🚶 Walkable check: #{walkable}"
        
        if walkable_area = scene.walkable_area
          puts "🗺️  Walkable area regions: #{walkable_area.regions.size}"
          walkable_area.regions.each_with_index do |region, i|
            contains = region.contains_point?(world_pos)
            puts "   #{i+1}. #{region.name}: #{contains ? "CONTAINS" : "outside"} (#{region.walkable ? "walkable" : "blocked"})"
          end
        else
          puts "🗺️  No walkable area defined - all positions walkable"
        end

        # Check if any hotspot was clicked
        clicked_hotspot = scene.get_hotspot_at(world_pos)
        puts "🎯 Hotspot clicked: #{clicked_hotspot ? clicked_hotspot.name : "None"}"

        if clicked_hotspot
          puts "🎯 Executing hotspot action..."
          clicked_hotspot.on_click.try(&.call)
        else
          puts "🎮 Attempting player movement..."
          if player
            if player.responds_to?(:handle_click)
              puts "   ✅ Calling player.handle_click"
              player.handle_click(world_pos, scene)
              puts "   ✅ Player movement command sent"
              puts "   📊 Player state: #{player.state}"
              puts "   🎯 Target position: #{player.target_position}"
            else
              puts "   ❌ Player does not respond to handle_click"
            end
          else
            puts "   ❌ No player available"
          end
        end
        puts "🖱️  === END CLICK DEBUG ===\n"
      end
    end
    
    debug_handler
  end
end

# Parse command line arguments
mode = ARGV.size > 0 ? ARGV[0] : "walkable"

unless ["walkable", "simple"].includes?(mode)
  puts "Usage: #{PROGRAM_NAME} [walkable|simple]"
  puts "  walkable - Test with walkable areas (default)"
  puts "  simple   - Test without walkable areas"
  exit 1
end

test = ComprehensiveMovementTest.new(mode)
test.run