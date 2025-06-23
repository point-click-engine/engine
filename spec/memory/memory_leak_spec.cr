require "../spec_helper"

# Memory leak detection tests
# These tests are specifically designed to detect memory leaks and unbounded growth
describe "Memory Leak Detection" do
  describe "scene lifecycle memory leaks" do
    it "does not leak memory during scene creation/destruction cycles" do
      # Baseline memory measurement
      GC.collect # Force initial cleanup
      sleep(0.01) # Allow GC to complete
      initial_memory = GC.stats.heap_size
      baseline_bytes = GC.stats.total_bytes
      
      # Perform many scene creation/destruction cycles
      cycles = 100
      scenes_per_cycle = 10
      
      cycles.times do |cycle|
        # Create scenes
        scenes = [] of PointClickEngine::Scenes::Scene
        scenes_per_cycle.times do |i|
          scene = PointClickEngine::Scenes::Scene.new("cycle_#{cycle}_scene_#{i}")
          
          # Add complexity to scenes to make leaks more obvious
          10.times do |j|
            hotspot = PointClickEngine::Scenes::Hotspot.new(
              "hotspot_#{j}",
              vec2(rand(100), rand(100)),
              vec2(20, 20)
            )
            scene.hotspots << hotspot
          end
          
          scenes << scene
        end
        
        # Verify scenes were created properly
        scenes.size.should eq(scenes_per_cycle)
        
        # Clear references (simulating scene unloading)
        scenes.clear
        
        # Force garbage collection every few cycles
        if cycle % 10 == 9
          GC.collect
          sleep(0.01)
          
          current_memory = GC.stats.heap_size
          memory_growth = current_memory.to_i64 - initial_memory.to_i64
          
          # Memory growth should be bounded
          # Allow some growth but detect significant leaks
          if memory_growth > 10_000_000 # 10MB threshold
            puts "Warning: Memory growth of #{memory_growth} bytes detected at cycle #{cycle}"
            puts "Initial: #{initial_memory}, Current: #{current_memory}"
          end
          
          # Hard limit to fail test if major leak detected
          memory_growth.should be < 50_000_000 # 50MB hard limit
        end
      end
      
      # Final memory check
      GC.collect
      sleep(0.01)
      final_memory = GC.stats.heap_size
      final_bytes = GC.stats.total_bytes
      
      memory_growth = final_memory.to_i64 - initial_memory.to_i64
      bytes_allocated = final_bytes - baseline_bytes
      
      puts "Memory leak test results:"
      puts "  Cycles: #{cycles}, Scenes per cycle: #{scenes_per_cycle}"
      puts "  Initial memory: #{initial_memory} bytes"
      puts "  Final memory: #{final_memory} bytes" 
      puts "  Memory growth: #{memory_growth} bytes"
      puts "  Total bytes allocated: #{bytes_allocated}"
      puts "  Memory growth per cycle: #{memory_growth / cycles} bytes"
      
      # Assert reasonable memory growth
      memory_growth.should be < 20_000_000 # 20MB total growth limit
    end
  end

  describe "hotspot memory leaks" do
    it "does not leak memory during hotspot manipulation" do
      GC.collect
      initial_memory = GC.stats.heap_size
      
      scene = PointClickEngine::Scenes::Scene.new("hotspot_leak_test")
      
      # Perform many hotspot add/remove cycles
      iterations = 1000
      max_hotspots = 100
      
      iterations.times do |i|
        # Add hotspot
        hotspot = PointClickEngine::Scenes::Hotspot.new(
          "leak_test_#{i}",
          vec2(rand(500), rand(500)),
          vec2(rand(50) + 10, rand(50) + 10)
        )
        scene.hotspots << hotspot
        
        # Remove oldest hotspots to maintain bounded size
        if scene.hotspots.size > max_hotspots
          scene.hotspots.shift
        end
        
        # Periodic memory check
        if i % 100 == 99
          GC.collect
          current_memory = GC.stats.heap_size
          memory_growth = current_memory.to_i64 - initial_memory.to_i64
          
          # Should not grow unbounded
          memory_growth.should be < 30_000_000 # 30MB limit
        end
      end
      
      # Final verification
      scene.hotspots.size.should be <= max_hotspots
      
      # Clear scene and check for leaks
      scene.hotspots.clear
      GC.collect
      
      final_memory = GC.stats.heap_size
      memory_growth = final_memory.to_i64 - initial_memory.to_i64
      
      puts "Hotspot memory test:"
      puts "  Iterations: #{iterations}"
      puts "  Memory growth: #{memory_growth} bytes"
      
      memory_growth.should be < 10_000_000 # 10MB limit after cleanup
    end
  end

  describe "state variable memory leaks" do
    it "does not leak memory during state variable operations" do
      GC.collect
      initial_memory = GC.stats.heap_size
      
      state_vars = {} of String => PointClickEngine::Core::StateValue
      
      # Perform many state operations
      iterations = 5000
      max_vars = 1000
      
      iterations.times do |i|
        case rand(5)
        when 0
          # Add integer
          state_vars["int_#{i}"] = PointClickEngine::Core::StateValue.new(rand(1000))
        when 1
          # Add string
          state_vars["str_#{i}"] = PointClickEngine::Core::StateValue.new("test_#{rand(100)}")
        when 2
          # Add boolean
          state_vars["bool_#{i}"] = PointClickEngine::Core::StateValue.new(rand > 0.5)
        when 3
          # Update existing variable
          if state_vars.size > 0
            key = state_vars.keys.sample
            state_vars[key] = PointClickEngine::Core::StateValue.new(rand(1000))
          end
        when 4
          # Remove variable to prevent unbounded growth
          if state_vars.size > max_vars
            # Remove oldest variables
            keys_to_remove = state_vars.keys.first(100)
            keys_to_remove.each { |key| state_vars.delete(key) }
          end
        end
        
        # Periodic memory check
        if i % 500 == 499
          GC.collect
          current_memory = GC.stats.heap_size
          memory_growth = current_memory.to_i64 - initial_memory.to_i64
          
          puts "State vars at iteration #{i}: count=#{state_vars.size}, memory_growth=#{memory_growth}"
          
          # Should not grow unbounded
          memory_growth.should be < 40_000_000 # 40MB limit
        end
      end
      
      # Clear all state variables
      state_vars.clear
      GC.collect
      
      final_memory = GC.stats.heap_size
      memory_growth = final_memory.to_i64 - initial_memory.to_i64
      
      puts "State variable memory test:"
      puts "  Iterations: #{iterations}"
      puts "  Final memory growth: #{memory_growth} bytes"
      
      memory_growth.should be < 15_000_000 # 15MB limit after cleanup
    end
  end

  describe "long-running memory stability" do
    it "maintains stable memory usage over extended operations" do
      GC.collect
      baseline_memory = GC.stats.heap_size
      memory_samples = [] of UInt64
      
      # Simulate extended gameplay session
      total_operations = 2000
      sample_interval = 100
      
      # Create persistent objects that would exist during gameplay
      persistent_scene = PointClickEngine::Scenes::Scene.new("persistent_scene")
      persistent_state = {} of String => PointClickEngine::Core::StateValue
      
      total_operations.times do |i|
        # Mix of operations that might occur during gameplay
        case rand(6)
        when 0
          # Temporary scene operations
          temp_scene = PointClickEngine::Scenes::Scene.new("temp_#{i}")
          temp_scene.hotspots << PointClickEngine::Scenes::Hotspot.new(
            "temp_hotspot",
            vec2(rand(100), rand(100)),
            vec2(10, 10)
          )
          # temp_scene goes out of scope
          
        when 1
          # Persistent scene modifications
          if persistent_scene.hotspots.size < 50
            hotspot = PointClickEngine::Scenes::Hotspot.new(
              "persistent_#{i}",
              vec2(rand(200), rand(200)),
              vec2(15, 15)
            )
            persistent_scene.hotspots << hotspot
          end
          
        when 2
          # State variable operations
          persistent_state["temp_#{i % 100}"] = PointClickEngine::Core::StateValue.new(rand(1000))
          
        when 3
          # String operations
          test_string = "operation_#{i}_" + ("x" * rand(100))
          state_val = PointClickEngine::Core::StateValue.new(test_string)
          # state_val goes out of scope
          
        when 4
          # Array operations
          temp_array = [] of PointClickEngine::Scenes::Hotspot
          10.times do |j|
            temp_array << PointClickEngine::Scenes::Hotspot.new(
              "array_#{j}",
              vec2(j, j),
              vec2(5, 5)
            )
          end
          # temp_array goes out of scope
          
        when 5
          # Cleanup operations
          if persistent_state.size > 200
            # Remove some old state variables
            keys = persistent_state.keys.first(50)
            keys.each { |k| persistent_state.delete(k) }
          end
        end
        
        # Sample memory usage
        if i % sample_interval == 0
          GC.collect
          current_memory = GC.stats.heap_size
          memory_samples << current_memory
          
          memory_growth = current_memory.to_i64 - baseline_memory.to_i64
          
          if i > 0 && i % (sample_interval * 5) == 0
            puts "Memory at operation #{i}: #{current_memory} bytes (growth: #{memory_growth})"
          end
          
          # Check for memory leaks
          memory_growth.should be < 60_000_000 # 60MB limit
        end
      end
      
      # Analyze memory stability
      if memory_samples.size > 10
        first_half = memory_samples[0...(memory_samples.size // 2)]
        second_half = memory_samples[(memory_samples.size // 2)..-1]
        
        first_avg = first_half.sum / first_half.size
        second_avg = second_half.sum / second_half.size
        
        growth_rate = second_avg.to_i64 - first_avg.to_i64
        
        puts "Long-running memory analysis:"
        puts "  Total operations: #{total_operations}"
        puts "  Memory samples: #{memory_samples.size}"
        puts "  Baseline memory: #{baseline_memory}"
        puts "  First half average: #{first_avg}"
        puts "  Second half average: #{second_avg}"
        puts "  Growth rate: #{growth_rate} bytes"
        puts "  Final memory: #{memory_samples.last}"
        
        # Growth rate should be reasonable (allowing for some growth)
        growth_rate.should be < 30_000_000 # 30MB growth between halves
      end
    end
  end
end