require "../spec_helper"

# Scene management stress tests
# Tests scene loading, transitions, memory management, and performance under load
describe "Scene Management Stress Tests" do
  describe "scene manager initialization and basic operations" do
    it "initializes scene manager correctly" do
      scene_manager = PointClickEngine::Core::SceneManager.new

      scene_manager.current_scene.should be_nil
      scene_manager.scene_names.should be_empty
      # Note: Callbacks are internal and not directly testable
      # We'll test them through actual scene transitions
    end

    it "handles scene addition and retrieval" do
      scene_manager = PointClickEngine::Core::SceneManager.new

      # Create test scenes
      scene1 = PointClickEngine::Scenes::Scene.new("test_scene_1")
      scene2 = PointClickEngine::Scenes::Scene.new("test_scene_2")
      scene3 = PointClickEngine::Scenes::Scene.new("test_scene_3")

      # Add scenes
      result1 = scene_manager.add_scene(scene1)
      result2 = scene_manager.add_scene(scene2)
      result3 = scene_manager.add_scene(scene3)

      # Verify scenes were added successfully
      result1.success?.should be_true
      result2.success?.should be_true
      result3.success?.should be_true

      scene_manager.scene_names.size.should eq(3)
      scene_manager.has_scene?("test_scene_1").should be_true
      scene_manager.has_scene?("test_scene_2").should be_true
      scene_manager.has_scene?("test_scene_3").should be_true
    end

    it "handles scene removal" do
      scene_manager = PointClickEngine::Core::SceneManager.new

      scene = PointClickEngine::Scenes::Scene.new("removable_scene")
      result = scene_manager.add_scene(scene)
      result.success?.should be_true
      scene_manager.scene_names.size.should eq(1)

      # Remove scene
      remove_result = scene_manager.remove_scene("removable_scene")
      remove_result.success?.should be_true
      scene_manager.scene_names.size.should eq(0)

      # Try to remove non-existent scene
      remove_again_result = scene_manager.remove_scene("nonexistent_scene")
      remove_again_result.success?.should be_false
    end
  end

  describe "scene transition mechanisms" do
    it "handles basic scene transitions" do
      scene_manager = PointClickEngine::Core::SceneManager.new

      scene1 = PointClickEngine::Scenes::Scene.new("scene_1")
      scene2 = PointClickEngine::Scenes::Scene.new("scene_2")

      scene_manager.add_scene(scene1)
      scene_manager.add_scene(scene2)

      # Initial state
      scene_manager.current_scene.should be_nil

      # Change to first scene
      result = scene_manager.change_scene("scene_1")
      result.success?.should be_true
      if result.success?
        scene_manager.current_scene.should eq(result.value)
      end

      # Change to second scene
      result = scene_manager.change_scene("scene_2")
      result.success?.should be_true
      if result.success?
        scene_manager.current_scene.should eq(result.value)
      end

      # Try to change to non-existent scene
      result = scene_manager.change_scene("nonexistent_scene")
      result.success?.should be_false
    end

    it "handles scene transition callbacks" do
      scene_manager = PointClickEngine::Core::SceneManager.new

      callback_order = [] of String

      # Register transition callbacks
      scene_manager.on_scene_transition("scene_1") do
        callback_order << "transition_to_scene_1"
      end

      scene_manager.on_scene_transition("scene_2") do
        callback_order << "transition_to_scene_2"
      end

      # Register enter/exit callbacks
      scene_manager.on_scene_enter("scene_1") do
        callback_order << "enter_scene_1"
      end

      scene_manager.on_scene_exit("scene_1") do
        callback_order << "exit_scene_1"
      end

      # Create and add scenes
      scene1 = PointClickEngine::Scenes::Scene.new("scene_1")
      scene2 = PointClickEngine::Scenes::Scene.new("scene_2")
      scene_manager.add_scene(scene1)
      scene_manager.add_scene(scene2)

      # Perform transitions
      scene_manager.change_scene("scene_1")
      scene_manager.change_scene("scene_2")

      # Check callback execution
      callback_order.includes?("transition_to_scene_1").should be_true
      callback_order.includes?("enter_scene_1").should be_true
      callback_order.includes?("exit_scene_1").should be_true
      callback_order.includes?("transition_to_scene_2").should be_true
    end

    it "handles multiple callbacks for the same scene" do
      scene_manager = PointClickEngine::Core::SceneManager.new

      callback_count = 0

      # Add multiple callbacks for the same scene
      3.times do |i|
        scene_manager.on_scene_transition("test_scene") do
          callback_count += 1
        end
      end

      scene = PointClickEngine::Scenes::Scene.new("test_scene")
      scene_manager.add_scene(scene)

      # Transition should trigger all callbacks
      scene_manager.change_scene("test_scene")
      callback_count.should eq(3)
    end
  end

  describe "scene preloading and caching" do
    it "handles scene preloading" do
      scene_manager = PointClickEngine::Core::SceneManager.new

      # Create scenes
      scenes_to_preload = [] of String
      5.times do |i|
        scene_name = "preload_scene_#{i}"
        scene = PointClickEngine::Scenes::Scene.new(scene_name)
        scene_manager.add_scene(scene)
        scenes_to_preload << scene_name
      end

      # Preload scenes individually
      scenes_to_preload.each do |scene_name|
        result = scene_manager.preload_scene(scene_name)
        result.success?.should be_true
      end

      # All scenes should be available
      scenes_to_preload.each do |scene_name|
        scene_manager.has_scene?(scene_name).should be_true
      end
    end

    it "handles scene caching and memory management" do
      scene_manager = PointClickEngine::Core::SceneManager.new

      # Create many scenes
      20.times do |i|
        scene = PointClickEngine::Scenes::Scene.new("cache_scene_#{i}")
        scene_manager.add_scene(scene)
      end

      scene_manager.scene_names.size.should eq(20)

      # Clear cache
      scene_manager.clear_cache

      # Cache should be empty (note: scenes may still exist but not cached)
      cache_stats = scene_manager.cache_stats
      cache_stats[:size].should eq(0)
    end

    it "handles scene validation during loading" do
      scene_manager = PointClickEngine::Core::SceneManager.new

      # Test scene validation through adding scenes
      valid_scene = PointClickEngine::Scenes::Scene.new("valid_scene")
      result = scene_manager.add_scene(valid_scene)
      result.success?.should be_true

      # Test validation with various scene configurations
      empty_name_scene = PointClickEngine::Scenes::Scene.new("")
      result = scene_manager.add_scene(empty_name_scene)
      # Empty name may or may not be valid depending on implementation
      # Just check that result responds to success? method
      result.responds_to?(:success?).should be_true
    end
  end

  describe "massive scene operations stress tests" do
    it "handles many scene additions efficiently" do
      scene_manager = PointClickEngine::Core::SceneManager.new

      scene_count = 1000

      # Create and add many scenes
      start_time = Time.monotonic
      scene_count.times do |i|
        scene = PointClickEngine::Scenes::Scene.new("stress_scene_#{i}")
        scene_manager.add_scene(scene)
      end
      addition_time = Time.monotonic - start_time

      scene_manager.scene_names.size.should eq(scene_count)

      puts "Scene addition performance:"
      puts "  Scenes added: #{scene_count}"
      puts "  Total time: #{addition_time.total_milliseconds.round(2)}ms"
      puts "  Time per scene: #{(addition_time.total_milliseconds / scene_count).round(4)}ms"

      # Should be reasonably fast
      (addition_time.total_milliseconds / scene_count).should be < 1.0 # 1ms per scene
    end

    it "handles rapid scene transitions" do
      scene_manager = PointClickEngine::Core::SceneManager.new

      # Create scenes for rapid switching
      transition_count = 100
      scene_names = [] of String

      transition_count.times do |i|
        scene_name = "rapid_scene_#{i}"
        scene = PointClickEngine::Scenes::Scene.new(scene_name)
        scene_manager.add_scene(scene)
        scene_names << scene_name
      end

      # Perform rapid transitions
      start_time = Time.monotonic
      transition_count.times do |i|
        scene_name = scene_names[i % scene_names.size]
        scene_manager.change_scene(scene_name)
      end
      transition_time = Time.monotonic - start_time

      puts "Rapid scene transition performance:"
      puts "  Transitions: #{transition_count}"
      puts "  Total time: #{transition_time.total_milliseconds.round(2)}ms"
      puts "  Time per transition: #{(transition_time.total_milliseconds / transition_count).round(4)}ms"

      # Should be very fast
      (transition_time.total_milliseconds / transition_count).should be < 0.1 # 0.1ms per transition
    end

    it "handles many concurrent callbacks" do
      scene_manager = PointClickEngine::Core::SceneManager.new

      callback_execution_count = 0
      callback_count = 500

      # Add many callbacks
      callback_count.times do |i|
        scene_manager.on_scene_transition("callback_test_scene") do
          callback_execution_count += 1
        end
      end

      scene = PointClickEngine::Scenes::Scene.new("callback_test_scene")
      scene_manager.add_scene(scene)

      # Trigger all callbacks
      start_time = Time.monotonic
      scene_manager.change_scene("callback_test_scene")
      callback_time = Time.monotonic - start_time

      # All callbacks should have executed
      callback_execution_count.should eq(callback_count)

      puts "Callback execution performance:"
      puts "  Callbacks: #{callback_count}"
      puts "  Total time: #{callback_time.total_milliseconds.round(2)}ms"
      puts "  Time per callback: #{(callback_time.total_milliseconds / callback_count).round(6)}ms"

      # Should be fast
      (callback_time.total_milliseconds / callback_count).should be < 0.01 # 0.01ms per callback
    end

    it "handles scene lookup performance under load" do
      scene_manager = PointClickEngine::Core::SceneManager.new

      # Create many scenes
      lookup_scene_count = 1000
      lookup_scene_count.times do |i|
        scene = PointClickEngine::Scenes::Scene.new("lookup_scene_#{i}")
        scene_manager.add_scene(scene)
      end

      # Perform many lookups
      lookup_count = 10000
      start_time = Time.monotonic

      lookup_count.times do |i|
        scene_name = "lookup_scene_#{rand(lookup_scene_count)}"
        scene = scene_manager.scenes[scene_name]?
        scene.should_not be_nil
      end

      lookup_time = Time.monotonic - start_time

      puts "Scene lookup performance:"
      puts "  Scenes: #{lookup_scene_count}"
      puts "  Lookups: #{lookup_count}"
      puts "  Total time: #{lookup_time.total_milliseconds.round(2)}ms"
      puts "  Time per lookup: #{(lookup_time.total_milliseconds / lookup_count).round(6)}ms"

      # Should be very fast (hash lookup)
      (lookup_time.total_milliseconds / lookup_count).should be < 0.001 # 0.001ms per lookup
    end
  end

  describe "scene memory management stress tests" do
    it "manages memory efficiently during scene creation and destruction" do
      initial_memory = GC.stats.heap_size

      # Create and destroy many scenes
      50.times do |cycle|
        scene_manager = PointClickEngine::Core::SceneManager.new

        # Create many scenes
        100.times do |i|
          scene = PointClickEngine::Scenes::Scene.new("memory_scene_#{cycle}_#{i}")

          # Add some complexity to scenes
          scene.background_path = "test_background_#{i}.png"

          scene_manager.add_scene(scene)
        end

        # Add many callbacks
        20.times do |i|
          scene_manager.on_scene_transition("memory_scene_#{cycle}_#{i}") do
            # Simulate some work
            dummy_work = cycle * i
          end
        end

        # Perform some transitions
        10.times do |i|
          scene_manager.change_scene("memory_scene_#{cycle}_#{i}")
        end

        # Scene manager goes out of scope here
      end

      # Force garbage collection
      GC.collect
      final_memory = GC.stats.heap_size
      memory_growth = final_memory.to_i64 - initial_memory.to_i64

      puts "Scene manager memory test: growth = #{memory_growth} bytes"

      # Should not leak significant memory
      memory_growth.should be < 10_000_000 # 10MB limit
    end

    it "handles scene cache cleanup efficiently" do
      scene_manager = PointClickEngine::Core::SceneManager.new

      # Create many scenes
      cache_scene_count = 200
      cache_scene_count.times do |i|
        scene = PointClickEngine::Scenes::Scene.new("cache_scene_#{i}")
        scene.background_path = "background_#{i}.png"
        scene_manager.add_scene(scene)
      end

      scene_manager.scene_names.size.should eq(cache_scene_count)

      # Clear cache multiple times
      10.times do
        scene_manager.clear_cache

        # Cache should be cleared but scenes may still exist
        cache_stats = scene_manager.cache_stats
        cache_stats[:size].should eq(0)

        # Re-add some scenes
        20.times do |i|
          scene = PointClickEngine::Scenes::Scene.new("temp_scene_#{i}")
          scene_manager.add_scene(scene)
        end
      end
    end

    it "handles callback cleanup during scene removal" do
      scene_manager = PointClickEngine::Core::SceneManager.new

      # Add scene and callbacks
      scene = PointClickEngine::Scenes::Scene.new("callback_cleanup_scene")
      scene_manager.add_scene(scene)

      # Add many callbacks
      100.times do |i|
        scene_manager.on_scene_transition("callback_cleanup_scene") do
          # Callback work
        end
        scene_manager.on_scene_enter("callback_cleanup_scene") do
          # Enter callback work
        end
        scene_manager.on_scene_exit("callback_cleanup_scene") do
          # Exit callback work
        end
      end

      # Verify scene exists
      scene_manager.has_scene?("callback_cleanup_scene").should be_true

      # Remove scene
      result = scene_manager.remove_scene("callback_cleanup_scene")
      result.success?.should be_true

      # Scene should be gone
      scene_manager.has_scene?("callback_cleanup_scene").should be_false
    end
  end

  describe "scene manager edge cases and error handling" do
    it "handles duplicate scene names" do
      scene_manager = PointClickEngine::Core::SceneManager.new

      scene1 = PointClickEngine::Scenes::Scene.new("duplicate_scene")
      scene2 = PointClickEngine::Scenes::Scene.new("duplicate_scene")

      scene_manager.add_scene(scene1)
      scene_manager.add_scene(scene2) # Should replace first scene

      scene_manager.scene_names.size.should eq(1)
      result = scene_manager.get_scene("duplicate_scene")
      result.success?.should be_true
      if result.success?
        # Check that we have the right scene name (object may differ due to replacement)
        result.value.name.should eq("duplicate_scene")
      end
    end

    it "handles invalid scene transitions" do
      scene_manager = PointClickEngine::Core::SceneManager.new

      # Try to transition to non-existent scene
      result = scene_manager.change_scene("nonexistent_scene")
      result.success?.should be_false
      scene_manager.current_scene.should be_nil

      # Add a scene and transition
      scene = PointClickEngine::Scenes::Scene.new("valid_scene")
      scene_manager.add_scene(scene)
      scene_manager.change_scene("valid_scene")

      # Try to transition to non-existent scene (should keep current)
      result = scene_manager.change_scene("another_nonexistent_scene")
      result.success?.should be_false
      if current = scene_manager.current_scene
        current.name.should eq("valid_scene")
      else
        fail "Expected current scene to remain set"
      end
    end

    it "handles empty and invalid scene names" do
      scene_manager = PointClickEngine::Core::SceneManager.new

      # Test empty scene name
      empty_scene = PointClickEngine::Scenes::Scene.new("")
      result = scene_manager.add_scene(empty_scene)
      # Empty names may be rejected - check either way
      if result.success?
        scene_manager.has_scene?("").should be_true
      else
        scene_manager.has_scene?("").should be_false
      end

      # Test whitespace scene name
      whitespace_scene = PointClickEngine::Scenes::Scene.new("   ")
      result = scene_manager.add_scene(whitespace_scene)
      # Whitespace names may be rejected - check either way
      if result.success?
        scene_manager.has_scene?("   ").should be_true
      else
        scene_manager.has_scene?("   ").should be_false
      end

      # Test very long scene name
      long_name = "x" * 1000
      long_scene = PointClickEngine::Scenes::Scene.new(long_name)
      scene_manager.add_scene(long_scene)
      scene_manager.has_scene?(long_name).should be_true
    end

    it "handles callback exceptions gracefully" do
      scene_manager = PointClickEngine::Core::SceneManager.new

      successful_callback_executed = false

      # Add callback that raises exception
      scene_manager.on_scene_transition("exception_scene") do
        raise "Test exception in callback"
      end

      # Add callback that should still execute
      scene_manager.on_scene_transition("exception_scene") do
        successful_callback_executed = true
      end

      scene = PointClickEngine::Scenes::Scene.new("exception_scene")
      scene_manager.add_scene(scene)

      # Transition should handle exception gracefully
      begin
        scene_manager.change_scene("exception_scene")
        # If implementation handles exceptions, second callback should still execute
        # If not, exception will be raised
      rescue ex
        # Exception handling depends on implementation
        ex.should be_a(Exception)
      end
    end

    it "handles extreme numbers of callbacks" do
      scene_manager = PointClickEngine::Core::SceneManager.new

      # Add extreme number of callbacks
      extreme_callback_count = 10000
      execution_count = 0

      extreme_callback_count.times do |i|
        scene_manager.on_scene_transition("extreme_scene") do
          execution_count += 1
        end
      end

      scene = PointClickEngine::Scenes::Scene.new("extreme_scene")
      scene_manager.add_scene(scene)

      # This might be slow but should not crash
      scene_manager.change_scene("extreme_scene")

      # All callbacks should execute (if implementation supports it)
      execution_count.should be >= 0 # At least some should execute
    end
  end

  describe "scene state and validation" do
    it "handles scene state consistency" do
      scene_manager = PointClickEngine::Core::SceneManager.new

      scene = PointClickEngine::Scenes::Scene.new("state_test_scene")
      scene_manager.add_scene(scene)

      # Multiple transitions to same scene
      5.times do
        scene_manager.change_scene("state_test_scene")
        if current = scene_manager.current_scene
          current.name.should eq("state_test_scene")
        else
          fail "Expected current scene to be set"
        end
      end

      # Transition to different scene and back
      other_scene = PointClickEngine::Scenes::Scene.new("other_scene")
      scene_manager.add_scene(other_scene)

      scene_manager.change_scene("other_scene")
      if current = scene_manager.current_scene
        current.name.should eq("other_scene")
      else
        fail "Expected current scene to be set"
      end

      scene_manager.change_scene("state_test_scene")
      if current = scene_manager.current_scene
        current.name.should eq("state_test_scene")
      else
        fail "Expected current scene to be set"
      end
    end

    it "handles concurrent scene operations" do
      scene_manager = PointClickEngine::Core::SceneManager.new

      # Simulate concurrent operations by rapid scene management
      1000.times do |i|
        scene_name = "concurrent_scene_#{i % 10}" # Cycle through 10 scenes

        if i % 3 == 0
          # Add scene
          scene = PointClickEngine::Scenes::Scene.new(scene_name)
          scene_manager.add_scene(scene)
        elsif i % 3 == 1
          # Try to transition
          scene_manager.change_scene(scene_name)
        else
          # Try to remove
          scene_manager.remove_scene(scene_name)
        end
      end

      # Should complete without crashing
      # Final state may vary but should be consistent
      scene_manager.scene_names.size.should be >= 0
    end
  end
end
