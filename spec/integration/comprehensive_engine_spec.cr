require "../spec_helper"
require "../../src/core/engine"
require "../../src/core/game_config"

# Comprehensive integration test that exercises all major engine components
# This test is designed to discover bugs through systematic feature testing
describe "Comprehensive Engine Integration" do
  describe "complete game lifecycle" do
    it "runs a full adventure game simulation without crashes" do
      # Create a test game configuration that exercises all features
      config = create_comprehensive_test_config
      
      engine = config.create_engine
      engine.init
      
      # Test 1: Scene Management
      test_scene_management(engine)
      
      # Test 2: Input Systems
      test_input_systems(engine)
      
      # Test 3: Audio Systems (if enabled)
      test_audio_systems(engine)
      
      # Test 4: Save/Load Cycles
      test_save_load_cycles(engine)
      
      # Test 5: Quest System
      test_quest_system(engine)
      
      # Test 6: Memory Management
      test_memory_management(engine)
      
      # Test 7: Error Recovery
      test_error_recovery(engine)
      
      engine.stop
    end
  end
  
  describe "stress testing" do
    it "handles rapid scene transitions" do
      engine = create_minimal_test_engine
      engine.init
      
      # Create multiple test scenes
      scenes = create_test_scenes(10)
      scenes.each { |scene| engine.add_scene(scene) }
      
      # Rapidly switch between scenes
      100.times do |i|
        scene_name = scenes[i % scenes.size].name
        engine.change_scene(scene_name)
        engine.current_scene.should_not be_nil
        engine.current_scene_name.should eq(scene_name)
      end
    end
    
    it "handles memory pressure gracefully" do
      engine = create_minimal_test_engine
      engine.init
      
      initial_memory = get_memory_usage
      
      # Simulate memory-intensive operations
      50.times do |i|
        # Create and load scenes with assets
        scene = create_memory_intensive_scene("stress_#{i}")
        engine.add_scene(scene)
        engine.change_scene("stress_#{i}")
        
        # Force some processing
        10.times { engine.update(0.016f32) }
        
        # Clean up periodically
        if i % 10 == 0
          GC.collect
        end
      end
      
      final_memory = get_memory_usage
      memory_growth = final_memory - initial_memory
      
      # Memory growth should be reasonable
      memory_growth.should be < 100_000_000 # 100MB threshold
    end
  end
  
  describe "edge cases and error conditions" do
    it "handles malformed configurations gracefully" do
      malformed_configs = [
        "",                           # Empty config
        "invalid: yaml: content:",    # Invalid YAML
        "game: {missing_required: true}", # Missing required fields
        create_config_with_missing_assets, # References non-existent files
      ]
      
      malformed_configs.each do |config_yaml|
        result = PointClickEngine::Core::GameConfig.from_yaml(config_yaml)
        # Should not crash, should return error result
        if result.success?
          # If parsing succeeds, engine creation should handle errors gracefully
          engine = result.value.create_engine
          expect { engine.init }.to_not raise_error
        end
      end
    end
    
    it "handles missing assets gracefully" do
      config = create_config_with_missing_assets
      engine = config.create_engine
      engine.init
      
      # Should not crash when trying to load missing assets
      expect { engine.change_scene("scene_with_missing_bg") }.to_not raise_error
      expect { engine.load_texture("non_existent.png") }.to_not raise_error
      expect { engine.load_sound("non_existent.wav") }.to_not raise_error
    end
  end
  
end

# Helper methods for test implementation

private def create_comprehensive_test_config
    config_yaml = <<-YAML
    game:
      title: "Comprehensive Test Game"
      version: "1.0.0"
    
    window:
      width: 800
      height: 600
    
    player:
      name: "TestPlayer"
      sprite_path: "test_player.png"
      sprite:
        frame_width: 32
        frame_height: 32
        columns: 4
        rows: 4
      starting_position:
        x: 100
        y: 200
    
    features:
      - verbs
      - floating_dialogs
      - portraits
    
    assets:
      scenes: ["test_scenes/*.yaml"]
      quests: ["test_quests/*.yaml"]
    
    start_scene: "test_room"
    YAML
    
    PointClickEngine::Core::GameConfig.from_yaml(config_yaml)
end

private def create_minimal_test_engine
    config_yaml = <<-YAML
    game:
      title: "Minimal Test"
      version: "1.0.0"
    window:
      width: 640
      height: 480
    start_scene: "test"
    YAML
    
    config = PointClickEngine::Core::GameConfig.from_yaml(config_yaml).value
    config.create_engine
end

private def test_scene_management(engine)
    # Test scene creation, transitions, and cleanup
    scene1 = create_test_scene("room1")
    scene2 = create_test_scene("room2")
    
    engine.add_scene(scene1)
    engine.add_scene(scene2)
    
    # Test transitions
    engine.change_scene("room1")
    engine.current_scene_name.should eq("room1")
    
    engine.change_scene("room2")
    engine.current_scene_name.should eq("room2")
    
    # Test scene removal
    result = engine.unload_scene("room1")
    result.success?.should be_true
end

private def test_input_systems(engine)
    # Test input registration and handling
    engine.register_input_handler("test_handler", 10)
    
    # Test input consumption
    engine.consume_input("click", "test_handler")
    engine.is_input_consumed("click").should be_true
    
    engine.unregister_input_handler("test_handler")
end

private def test_audio_systems(engine)
    # Test audio loading and playback (graceful handling if no audio)
    result = engine.load_sound("test.wav")
    # Should not crash regardless of result
    
    result = engine.load_music("test.ogg")
    # Should not crash regardless of result
end

private def test_save_load_cycles(engine)
    # Test save/load functionality
    Dir.mkdir_p("test_saves") unless Dir.exists?("test_saves")
    
    # Save current state
    engine.save_game("test_saves/integration_test.yml")
    
    # Modify state
    engine.change_scene("room2") if engine.scenes.has_key?("room2")
    
    # Load previous state
    loaded_engine = PointClickEngine::Core::Engine.load_game("test_saves/integration_test.yml")
    loaded_engine.should_not be_nil
    
    # Cleanup
    File.delete("test_saves/integration_test.yml") if File.exists?("test_saves/integration_test.yml")
    Dir.delete("test_saves") if Dir.exists?("test_saves")
end

private def test_quest_system(engine)
    # Test quest management if quest manager is available
    if engine.quest_manager
      # Add test quest operations here
    end
end

private def test_memory_management(engine)
    # Test resource cleanup and memory management
    initial_memory = get_memory_usage
    
    # Create and destroy many objects
    100.times do |i|
      scene = create_test_scene("temp_#{i}")
      engine.add_scene(scene)
      engine.unload_scene("temp_#{i}")
    end
    
    # Force garbage collection
    GC.collect
    
    final_memory = get_memory_usage
    memory_growth = final_memory - initial_memory
    
    # Should not leak significant memory
    memory_growth.should be < 10_000_000 # 10MB threshold
end

private def test_error_recovery(engine)
    # Test that engine recovers from various error conditions
    
    # Try to change to non-existent scene
    expect { engine.change_scene("non_existent") }.to_not raise_error
    
    # Try to load non-existent resources
    expect { engine.load_texture("fake.png") }.to_not raise_error
    
    # Engine should still be functional
    engine.current_scene.should_not be_nil
end

private def create_test_scene(name : String)
    scene = PointClickEngine::Scenes::Scene.new(name)
    scene.background_path = "test_bg.png"
    scene
end

private def create_test_scenes(count : Int32)
    (0...count).map { |i| create_test_scene("test_scene_#{i}") }
end

private def create_memory_intensive_scene(name : String)
    scene = PointClickEngine::Scenes::Scene.new(name)
    scene.background_path = "large_background.png"
    
    # Add many hotspots to make it memory intensive
    20.times do |i|
      hotspot = PointClickEngine::Scenes::Hotspot.new("hotspot_#{i}")
      hotspot.position = RL::Vector2.new(x: i * 10, y: i * 10)
      hotspot.size = RL::Vector2.new(x: 50, y: 50)
      scene.add_hotspot(hotspot)
    end
    
    scene
end

private def create_config_with_missing_assets
    config_yaml = <<-YAML
    game:
      title: "Missing Assets Test"
      version: "1.0.0"
    window:
      width: 640
      height: 480
    player:
      sprite_path: "non_existent_player.png"
    start_scene: "scene_with_missing_bg"
    YAML
    
    PointClickEngine::Core::GameConfig.from_yaml(config_yaml)
end

private def get_memory_usage : Int64
  # Simple memory usage tracking
  # In a real implementation, this would use system calls
  GC.stats.heap_size.to_i64
end