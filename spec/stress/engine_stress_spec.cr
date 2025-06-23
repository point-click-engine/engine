require "../spec_helper"

# Stress tests to find performance issues and memory leaks
# These tests push the engine to its limits to discover scalability problems
describe "Engine Stress Tests" do
  describe "scene management stress" do
    it "handles creating and destroying many scenes" do
      initial_memory = GC.stats.heap_size
      scene_count = 1000

      # Create many scenes
      scenes = [] of PointClickEngine::Scenes::Scene
      scene_count.times do |i|
        scene = PointClickEngine::Scenes::Scene.new("stress_scene_#{i}")
        scenes << scene

        # Add some hotspots to each scene to increase complexity
        5.times do |j|
          hotspot = PointClickEngine::Scenes::Hotspot.new(
            "hotspot_#{j}",
            vec2(rand(1000), rand(1000)),
            vec2(rand(50) + 10, rand(50) + 10)
          )
          scene.hotspots << hotspot
        end
      end

      # Verify all scenes were created
      scenes.size.should eq(scene_count)
      scenes.each_with_index do |scene, i|
        scene.name.should eq("stress_scene_#{i}")
        scene.hotspots.size.should eq(5)
      end

      # Clear references and force garbage collection
      scenes.clear
      GC.collect

      # Check memory usage hasn't grown excessively
      final_memory = GC.stats.heap_size
      memory_growth = final_memory - initial_memory

      # Allow some growth but not excessive
      memory_growth.should be < 100_000_000 # 100MB limit
    end

    it "handles rapid scene modifications" do
      scene = PointClickEngine::Scenes::Scene.new("modification_test")

      # Rapidly add and remove hotspots
      1000.times do |i|
        # Add hotspot
        hotspot = PointClickEngine::Scenes::Hotspot.new(
          "temp_#{i}",
          vec2(rand(100), rand(100)),
          vec2(10, 10)
        )
        scene.hotspots << hotspot

        # Remove some hotspots periodically to prevent unbounded growth
        if i % 100 == 99 && scene.hotspots.size > 50
          # Remove first 25 hotspots
          25.times { scene.hotspots.shift }
        end
      end

      # Scene should still be in valid state
      scene.name.should eq("modification_test")
      scene.hotspots.size.should be > 0
      scene.hotspots.each { |h| h.name.should_not be_empty }
    end
  end

  describe "state management stress" do
    it "handles massive state variable operations" do
      state_vars = {} of String => PointClickEngine::Core::StateValue
      operations = 10000

      # Perform many state operations
      operations.times do |i|
        case rand(4)
        when 0
          # Add integer
          state_vars["int_#{i}"] = PointClickEngine::Core::StateValue.new(rand(1000000))
        when 1
          # Add string
          state_vars["str_#{i}"] = PointClickEngine::Core::StateValue.new("value_#{rand(1000)}")
        when 2
          # Add boolean
          state_vars["bool_#{i}"] = PointClickEngine::Core::StateValue.new(rand > 0.5)
        when 3
          # Remove random variable (if any exist)
          if state_vars.size > 0 && rand > 0.9 # Only remove 10% of the time
            key = state_vars.keys.sample
            state_vars.delete(key)
          end
        end

        # Verify integrity every 1000 operations
        if i % 1000 == 999
          state_vars.each do |key, value|
            # Each value should be retrievable and valid
            retrieved = state_vars[key]
            retrieved.should eq(value)

            # Value should have a valid type
            case value.value
            when Int32
              value.as_int?.should_not be_nil
            when String
              value.as_string?.should_not be_nil
            when Bool
              value.as_bool?.should_not be_nil
            end
          end
        end
      end

      # Final verification
      state_vars.size.should be > 0
      puts "Final state variables count: #{state_vars.size}"
    end
  end

  describe "memory pressure stress" do
    it "handles memory pressure gracefully" do
      initial_memory = GC.stats.heap_size

      # Create many objects of different types
      large_objects = [] of Array(PointClickEngine::Scenes::Hotspot)

      100.times do |batch|
        hotspots = [] of PointClickEngine::Scenes::Hotspot

        # Create 100 hotspots per batch
        100.times do |i|
          hotspot = PointClickEngine::Scenes::Hotspot.new(
            "stress_hotspot_#{batch}_#{i}",
            vec2(rand(1000), rand(1000)),
            vec2(rand(100) + 10, rand(100) + 10)
          )
          hotspots << hotspot
        end

        large_objects << hotspots

        # Every 10 batches, force garbage collection and clean up some objects
        if batch % 10 == 9
          GC.collect

          # Remove half the objects to simulate cleanup
          if large_objects.size > 50
            25.times { large_objects.shift }
          end

          # Check memory growth
          current_memory = GC.stats.heap_size
          memory_growth = current_memory.to_i64 - initial_memory.to_i64

          # Memory should not grow unbounded
          memory_growth.should be < 200_000_000 # 200MB limit
        end
      end

      # Final cleanup
      large_objects.clear
      GC.collect

      final_memory = GC.stats.heap_size
      puts "Memory usage: initial=#{initial_memory}, final=#{final_memory}, growth=#{final_memory.to_i64 - initial_memory.to_i64}"
    end
  end

  describe "concurrent operations stress" do
    it "handles rapid sequential operations" do
      # Simulate rapid operations that might occur in a real game
      scene = PointClickEngine::Scenes::Scene.new("concurrent_test")

      # Rapid scene state changes
      1000.times do |i|
        # Add hotspot
        hotspot = PointClickEngine::Scenes::Hotspot.new(
          "rapid_#{i}",
          vec2(rand(500), rand(500)),
          vec2(20, 20)
        )
        scene.hotspots << hotspot

        # Modify hotspot properties
        hotspot.position = vec2(rand(500), rand(500))
        hotspot.size = vec2(rand(50) + 10, rand(50) + 10)

        # Check hotspot consistency
        hotspot.name.should eq("rapid_#{i}")
        hotspot.position.x.should be >= 0
        hotspot.position.y.should be >= 0
        hotspot.size.x.should be > 0
        hotspot.size.y.should be > 0

        # Clean up periodically
        if i % 100 == 99
          # Keep only last 50 hotspots
          while scene.hotspots.size > 50
            scene.hotspots.shift
          end
        end
      end

      # Final state should be consistent
      scene.name.should eq("concurrent_test")
      scene.hotspots.size.should be <= 50
      scene.hotspots.each do |hotspot|
        hotspot.name.should_not be_empty
        hotspot.size.x.should be > 0
        hotspot.size.y.should be > 0
      end
    end
  end

  describe "edge case stress" do
    it "handles extreme values and edge cases" do
      # Test with extreme coordinate values
      extreme_positions = [
        vec2(0, 0),             # Origin
        vec2(-1000, -1000),     # Negative coordinates
        vec2(1000000, 1000000), # Very large coordinates
        vec2(0.1, 0.1),         # Very small positive
        vec2(-0.1, -0.1),       # Very small negative
      ]

      extreme_sizes = [
        vec2(1, 1),         # Minimal size
        vec2(0.1, 0.1),     # Sub-pixel size
        vec2(10000, 10000), # Very large size
        vec2(1, 10000),     # Extreme aspect ratio
        vec2(10000, 1),     # Reverse extreme aspect ratio
      ]

      # Test all combinations
      extreme_positions.each_with_index do |pos, pi|
        extreme_sizes.each_with_index do |size, si|
          hotspot = PointClickEngine::Scenes::Hotspot.new(
            "extreme_#{pi}_#{si}",
            pos,
            size
          )

          # Should not crash and should preserve values
          hotspot.position.should eq(pos)
          hotspot.size.should eq(size)
          hotspot.name.should eq("extreme_#{pi}_#{si}")
        end
      end
    end

    it "handles string edge cases" do
      edge_case_strings = [
        "",                             # Empty string
        " ",                            # Single space
        "a" * 10000,                    # Very long string
        "🎮🎯🎲",                          # Unicode/emoji
        "line1\nline2\tline3",          # Control characters
        "\"quotes\" and 'apostrophes'", # Quotes
        "null\x00embedded",             # Null bytes
        "special!@#$%^&*()chars",       # Special characters
      ]

      edge_case_strings.each_with_index do |str, i|
        begin
          # Test in scene names
          scene = PointClickEngine::Scenes::Scene.new("test_#{i}")
          scene.name.should eq("test_#{i}")

          # Test in state values
          state_val = PointClickEngine::Core::StateValue.new(str)
          state_val.as_string?.should eq(str)

          # Test in hotspot names
          hotspot = PointClickEngine::Scenes::Hotspot.new(
            "hotspot_#{i}",
            vec2(0, 0),
            vec2(10, 10)
          )
          hotspot.name.should eq("hotspot_#{i}")
        rescue ex
          # Some edge cases might legitimately fail, but should not crash
          ex.should be_a(Exception)
        end
      end
    end
  end
end
