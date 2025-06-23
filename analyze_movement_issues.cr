#!/usr/bin/env crystal
# Static analysis script to identify potential movement issues

require "./src/point_click_engine"

class MovementAnalyzer
  def self.analyze
    puts "🔍 PLAYER MOVEMENT SYSTEM ANALYSIS"
    puts "=" * 50

    analyze_player_class
    analyze_input_handler
    analyze_scene_walkable_checks
    analyze_character_base_class
    analyze_engine_integration

    puts "\n✅ Analysis complete. Check the findings above."
  end

  private def self.analyze_player_class
    puts "\n📝 PLAYER CLASS ANALYSIS:"
    puts "-" * 30

    # Test Player class instantiation
    begin
      player = PointClickEngine::Characters::Player.new("TestPlayer",
        RL::Vector2.new(x: 100, y: 100),
        RL::Vector2.new(x: 32, y: 64))
      puts "✅ Player class can be instantiated"
      puts "   Default movement_enabled: #{player.movement_enabled}"
      puts "   Default walking_speed: #{player.walking_speed}"
      puts "   Default state: #{player.state}"
      puts "   Responds to handle_click: #{player.responds_to?(:handle_click)}"

      # Test handle_click method signature
      if player.responds_to?(:handle_click)
        puts "✅ Player.handle_click method exists"
      else
        puts "❌ Player.handle_click method NOT found"
      end
    rescue ex
      puts "❌ Failed to instantiate Player: #{ex.message}"
    end
  end

  private def self.analyze_input_handler
    puts "\n🖱️  INPUT HANDLER ANALYSIS:"
    puts "-" * 30

    begin
      handler = PointClickEngine::Core::EngineComponents::InputHandler.new
      puts "✅ InputHandler can be instantiated"
      puts "   Default handle_clicks: #{handler.handle_clicks}"
      puts "   Responds to process_input: #{handler.responds_to?(:process_input)}"
      puts "   Responds to handle_click: #{handler.responds_to?(:handle_click)}"
    rescue ex
      puts "❌ Failed to instantiate InputHandler: #{ex.message}"
    end
  end

  private def self.analyze_scene_walkable_checks
    puts "\n🏠 SCENE WALKABLE ANALYSIS:"
    puts "-" * 30

    begin
      scene = PointClickEngine::Scenes::Scene.new("test")
      puts "✅ Scene can be instantiated"

      test_point = RL::Vector2.new(x: 100, y: 100)
      walkable = scene.is_walkable?(test_point)
      puts "   is_walkable() without walkable_area: #{walkable}"
      puts "   walkable_area defined: #{scene.walkable_area ? "Yes" : "No"}"

      # Test with walkable area
      walkable_area = PointClickEngine::Scenes::WalkableArea.new
      walkable_region = PointClickEngine::Scenes::PolygonRegion.new("test", true)
      walkable_region.vertices = [
        RL::Vector2.new(x: 0, y: 0),
        RL::Vector2.new(x: 200, y: 0),
        RL::Vector2.new(x: 200, y: 200),
        RL::Vector2.new(x: 0, y: 200),
      ]
      walkable_area.regions << walkable_region
      scene.walkable_area = walkable_area

      walkable_with_area = scene.is_walkable?(test_point)
      puts "   is_walkable() with walkable_area: #{walkable_with_area}"
    rescue ex
      puts "❌ Failed to test Scene walkable checks: #{ex.message}"
    end
  end

  private def self.analyze_character_base_class
    puts "\n🚶 CHARACTER BASE CLASS ANALYSIS:"
    puts "-" * 30

    begin
      # Test using Player class which extends Character
      char = PointClickEngine::Characters::Player.new("Test", RL::Vector2.new(x: 50, y: 50), RL::Vector2.new(x: 32, y: 64))
      puts "✅ Character (Player) class works"
      puts "   Default walking_speed: #{char.walking_speed}"
      puts "   Default state: #{char.state}"
      puts "   Default use_pathfinding: #{char.use_pathfinding}"
      puts "   Responds to walk_to: #{char.responds_to?(:walk_to)}"

      # Test walk_to method
      target = RL::Vector2.new(x: 150, y: 150)
      char.walk_to(target)
      puts "✅ walk_to method executed"
      puts "   State after walk_to: #{char.state}"
      puts "   Target position set: #{char.target_position}"
    rescue ex
      puts "❌ Failed to test Character base class: #{ex.message}"
    end
  end

  private def self.analyze_engine_integration
    puts "\n⚙️  ENGINE INTEGRATION ANALYSIS:"
    puts "-" * 30

    begin
      engine = PointClickEngine::Core::Engine.new(800, 600, "Test")
      puts "✅ Engine can be instantiated"
      puts "   handle_clicks property: #{engine.handle_clicks}"

      # Test changing handle_clicks
      engine.handle_clicks = false
      puts "   handle_clicks after setting false: #{engine.handle_clicks}"
      engine.handle_clicks = true
      puts "   handle_clicks after setting true: #{engine.handle_clicks}"

      puts "   input_handler present: #{engine.input_handler ? "Yes" : "No"}"
    rescue ex
      puts "❌ Failed to test Engine integration: #{ex.message}"
    end
  end
end

# Run the analysis
MovementAnalyzer.analyze
