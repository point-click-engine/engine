require "../spec_helper"

# Performance regression detection tests
# These tests measure performance and detect regressions in critical operations
describe "Performance Regression Detection" do
  describe "scene operations performance" do
    it "scene creation performance meets benchmarks" do
      # Baseline performance measurement
      scene_count = 1000
      start_time = Time.monotonic
      
      # Measure scene creation time
      scenes = [] of PointClickEngine::Scenes::Scene
      scene_count.times do |i|
        scene = PointClickEngine::Scenes::Scene.new("perf_scene_#{i}")
        scenes << scene
      end
      
      creation_time = Time.monotonic - start_time
      creation_time_per_scene = creation_time.total_milliseconds / scene_count
      
      puts "Scene creation performance:"
      puts "  Total scenes: #{scene_count}"
      puts "  Total time: #{creation_time.total_milliseconds.round(2)}ms"
      puts "  Time per scene: #{creation_time_per_scene.round(4)}ms"
      
      # Performance regression check
      # Scenes should be created very quickly (adjust threshold as needed)
      creation_time_per_scene.should be < 0.1 # 0.1ms per scene
      
      # Verify all scenes were created correctly
      scenes.size.should eq(scene_count)
    end
    
    it "hotspot operations performance meets benchmarks" do
      scene = PointClickEngine::Scenes::Scene.new("hotspot_perf_test")
      hotspot_count = 5000
      
      # Measure hotspot creation time
      start_time = Time.monotonic
      
      hotspot_count.times do |i|
        hotspot = PointClickEngine::Scenes::Hotspot.new(
          "perf_hotspot_#{i}",
          vec2(rand(1000), rand(1000)),
          vec2(rand(50) + 10, rand(50) + 10)
        )
        scene.hotspots << hotspot
      end
      
      creation_time = Time.monotonic - start_time
      creation_time_per_hotspot = creation_time.total_milliseconds / hotspot_count
      
      puts "Hotspot creation performance:"
      puts "  Total hotspots: #{hotspot_count}"
      puts "  Total time: #{creation_time.total_milliseconds.round(2)}ms"
      puts "  Time per hotspot: #{creation_time_per_hotspot.round(4)}ms"
      
      # Performance regression check
      creation_time_per_hotspot.should be < 0.05 # 0.05ms per hotspot
      
      # Test hotspot access performance
      access_start = Time.monotonic
      
      # Access each hotspot and verify properties
      scene.hotspots.each_with_index do |hotspot, i|
        hotspot.name.should eq("perf_hotspot_#{i}")
        hotspot.position.x.should be >= 0
        hotspot.position.y.should be >= 0
      end
      
      access_time = Time.monotonic - access_start
      access_time_per_hotspot = access_time.total_milliseconds / hotspot_count
      
      puts "Hotspot access performance:"
      puts "  Time per access: #{access_time_per_hotspot.round(4)}ms"
      
      access_time_per_hotspot.should be < 0.01 # 0.01ms per access
    end
  end

  describe "state management performance" do
    it "state variable operations performance meets benchmarks" do
      state_vars = {} of String => PointClickEngine::Core::StateValue
      operation_count = 10000
      
      # Measure state variable creation performance
      start_time = Time.monotonic
      
      operation_count.times do |i|
        case i % 4
        when 0
          state_vars["int_#{i}"] = PointClickEngine::Core::StateValue.new(rand(1000))
        when 1
          state_vars["str_#{i}"] = PointClickEngine::Core::StateValue.new("value_#{i}")
        when 2
          state_vars["bool_#{i}"] = PointClickEngine::Core::StateValue.new(rand > 0.5)
        when 3
          state_vars["float_#{i}"] = PointClickEngine::Core::StateValue.new(rand.to_f32)
        end
      end
      
      creation_time = Time.monotonic - start_time
      creation_time_per_op = creation_time.total_milliseconds / operation_count
      
      puts "State variable creation performance:"
      puts "  Total operations: #{operation_count}"
      puts "  Total time: #{creation_time.total_milliseconds.round(2)}ms"
      puts "  Time per operation: #{creation_time_per_op.round(4)}ms"
      
      creation_time_per_op.should be < 0.01 # 0.01ms per operation
      
      # Measure state variable access performance
      access_start = Time.monotonic
      
      # Access and type-check each state variable
      state_vars.each do |key, value|
        case value.value
        when Int32
          value.as_int?.should_not be_nil
        when String
          value.as_string?.should_not be_nil
        when Bool
          value.as_bool?.should_not be_nil
        when Float32
          value.as_float?.should_not be_nil
        end
      end
      
      access_time = Time.monotonic - access_start
      access_time_per_var = access_time.total_milliseconds / state_vars.size
      
      puts "State variable access performance:"
      puts "  Variables accessed: #{state_vars.size}"
      puts "  Time per access: #{access_time_per_var.round(4)}ms"
      
      access_time_per_var.should be < 0.005 # 0.005ms per access
    end
  end

  describe "memory allocation performance" do
    it "object allocation performance meets benchmarks" do
      allocation_cycles = 100
      objects_per_cycle = 100
      
      # Measure allocation performance
      start_time = Time.monotonic
      
      allocation_cycles.times do |cycle|
        # Create temporary objects
        temp_objects = [] of PointClickEngine::Scenes::Hotspot
        
        objects_per_cycle.times do |i|
          hotspot = PointClickEngine::Scenes::Hotspot.new(
            "temp_#{cycle}_#{i}",
            vec2(rand(100), rand(100)),
            vec2(10, 10)
          )
          temp_objects << hotspot
        end
        
        # Verify objects were created
        temp_objects.size.should eq(objects_per_cycle)
        
        # Objects go out of scope here
      end
      
      allocation_time = Time.monotonic - start_time
      total_objects = allocation_cycles * objects_per_cycle
      time_per_allocation = allocation_time.total_milliseconds / total_objects
      
      puts "Object allocation performance:"
      puts "  Total objects: #{total_objects}"
      puts "  Total time: #{allocation_time.total_milliseconds.round(2)}ms"
      puts "  Time per allocation: #{time_per_allocation.round(4)}ms"
      
      time_per_allocation.should be < 0.02 # 0.02ms per allocation
      
      # Force garbage collection and measure time
      gc_start = Time.monotonic
      GC.collect
      gc_time = Time.monotonic - gc_start
      
      puts "Garbage collection performance:"
      puts "  GC time: #{gc_time.total_milliseconds.round(2)}ms"
      
      # GC should complete reasonably quickly
      gc_time.total_milliseconds.should be < 100 # 100ms GC limit
    end
  end

  describe "collection operations performance" do
    it "array operations performance meets benchmarks" do
      array_size = 10000
      hotspots = [] of PointClickEngine::Scenes::Hotspot
      
      # Measure array append performance
      start_time = Time.monotonic
      
      array_size.times do |i|
        hotspot = PointClickEngine::Scenes::Hotspot.new(
          "array_perf_#{i}",
          vec2(i, i),
          vec2(10, 10)
        )
        hotspots << hotspot
      end
      
      append_time = Time.monotonic - start_time
      append_time_per_item = append_time.total_milliseconds / array_size
      
      puts "Array append performance:"
      puts "  Array size: #{array_size}"
      puts "  Total time: #{append_time.total_milliseconds.round(2)}ms"
      puts "  Time per append: #{append_time_per_item.round(4)}ms"
      
      append_time_per_item.should be < 0.005 # 0.005ms per append
      
      # Measure array iteration performance
      iteration_start = Time.monotonic
      
      count = 0
      hotspots.each do |hotspot|
        count += 1 if hotspot.name.includes?("array_perf")
      end
      
      iteration_time = Time.monotonic - iteration_start
      iteration_time_per_item = iteration_time.total_milliseconds / array_size
      
      puts "Array iteration performance:"
      puts "  Items processed: #{count}"
      puts "  Time per iteration: #{iteration_time_per_item.round(4)}ms"
      
      iteration_time_per_item.should be < 0.001 # 0.001ms per iteration
      count.should eq(array_size)
    end
    
    it "hash operations performance meets benchmarks" do
      hash_size = 10000
      scenes = {} of String => PointClickEngine::Scenes::Scene
      
      # Measure hash insertion performance
      start_time = Time.monotonic
      
      hash_size.times do |i|
        key = "hash_perf_#{i}"
        scene = PointClickEngine::Scenes::Scene.new(key)
        scenes[key] = scene
      end
      
      insertion_time = Time.monotonic - start_time
      insertion_time_per_item = insertion_time.total_milliseconds / hash_size
      
      puts "Hash insertion performance:"
      puts "  Hash size: #{hash_size}"
      puts "  Total time: #{insertion_time.total_milliseconds.round(2)}ms"
      puts "  Time per insertion: #{insertion_time_per_item.round(4)}ms"
      
      insertion_time_per_item.should be < 0.01 # 0.01ms per insertion
      
      # Measure hash lookup performance
      lookup_start = Time.monotonic
      
      found_count = 0
      hash_size.times do |i|
        key = "hash_perf_#{i}"
        if scenes.has_key?(key)
          scene = scenes[key]
          found_count += 1 if scene.name == key
        end
      end
      
      lookup_time = Time.monotonic - lookup_start
      lookup_time_per_item = lookup_time.total_milliseconds / hash_size
      
      puts "Hash lookup performance:"
      puts "  Items found: #{found_count}"
      puts "  Time per lookup: #{lookup_time_per_item.round(4)}ms"
      
      lookup_time_per_item.should be < 0.001 # 0.001ms per lookup
      found_count.should eq(hash_size)
    end
  end

  describe "comprehensive performance baseline" do
    it "establishes performance baseline for complex operations" do
      # This test combines multiple operations to establish a comprehensive baseline
      start_time = Time.monotonic
      
      # Create scene with complex structure
      main_scene = PointClickEngine::Scenes::Scene.new("comprehensive_perf_test")
      
      # Add many hotspots
      100.times do |i|
        hotspot = PointClickEngine::Scenes::Hotspot.new(
          "complex_hotspot_#{i}",
          vec2(rand(1000), rand(1000)),
          vec2(rand(100) + 10, rand(100) + 10)
        )
        main_scene.hotspots << hotspot
      end
      
      # Create state management system
      state_vars = {} of String => PointClickEngine::Core::StateValue
      
      # Add various state variables
      500.times do |i|
        state_vars["complex_var_#{i}"] = PointClickEngine::Core::StateValue.new(
          case i % 4
          when 0 then rand(1000)
          when 1 then "complex_string_#{i}"
          when 2 then rand > 0.5
          else        rand.to_f32
          end
        )
      end
      
      # Perform complex operations
      operations = 0
      10.times do |round|
        # Scene operations
        main_scene.hotspots.each do |hotspot|
          hotspot.position = vec2(rand(1000), rand(1000))
          operations += 1
        end
        
        # State operations
        state_vars.each do |key, value|
          case value.value
          when Int32
            value.as_int?
          when String
            value.as_string?
          when Bool
            value.as_bool?
          when Float32
            value.as_float?
          end
          operations += 1
        end
      end
      
      total_time = Time.monotonic - start_time
      time_per_operation = total_time.total_milliseconds / operations
      
      puts "Comprehensive performance baseline:"
      puts "  Total operations: #{operations}"
      puts "  Total time: #{total_time.total_milliseconds.round(2)}ms"
      puts "  Time per operation: #{time_per_operation.round(6)}ms"
      puts "  Operations per second: #{(operations / total_time.total_seconds).round(0)}"
      
      # Comprehensive performance should meet baseline
      time_per_operation.should be < 0.01 # 0.01ms average per operation
      
      # Should be able to do at least 10,000 operations per second
      operations_per_second = operations / total_time.total_seconds
      operations_per_second.should be > 10000
    end
  end
end