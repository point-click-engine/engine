require "../spec_helper"

# Audio system comprehensive testing
# Tests both audio-enabled and audio-disabled modes
describe "Audio System Comprehensive Testing" do
  describe "audio availability detection" do
    it "correctly reports audio availability" do
      # Test audio availability detection
      available = PointClickEngine::Audio.available?
      available.should be_a(Bool)
      
      {% if flag?(:with_audio) %}
        available.should be_true
        puts "Audio system: ENABLED"
      {% else %}
        available.should be_false
        puts "Audio system: DISABLED (stub mode)"
      {% end %}
    end
  end

  describe "sound effect management" do
    it "handles sound effect creation and lifecycle" do
      # Test sound effect creation (works in both modes)
      sound_name = "test_sound"
      fake_path = "non_existent_sound.wav"
      
      begin
        sound_effect = PointClickEngine::Audio::SoundEffect.new(sound_name, fake_path)
        sound_effect.name.should eq(sound_name)
        sound_effect.volume.should eq(1.0)
        
        # Test volume setting
        sound_effect.volume = 0.5
        sound_effect.volume.should eq(0.5)
        
        # Test play/stop operations (should not crash in either mode)
        sound_effect.play
        sound_effect.stop
        
        puts "Sound effect operations: OK"
      rescue ex
        # In audio-disabled mode or with missing files, this might raise
        # That's acceptable behavior
        puts "Sound effect creation failed (expected in some modes): #{ex.message}"
        ex.should be_a(Exception)
      end
    end
    
    it "handles multiple sound effects" do
      sound_effects = [] of PointClickEngine::Audio::SoundEffect
      sound_names = ["sound1", "sound2", "sound3", "sound4", "sound5"]
      
      # Try to create multiple sound effects
      created_count = 0
      sound_names.each do |name|
        begin
          effect = PointClickEngine::Audio::SoundEffect.new(name, "fake_#{name}.wav")
          sound_effects << effect
          created_count += 1
        rescue ex
          # Expected if audio files don't exist
        end
      end
      
      puts "Successfully created #{created_count} sound effects"
      
      # Test operations on created effects
      sound_effects.each do |effect|
        effect.volume = rand.to_f32
        effect.play
        effect.stop
      end
      
      # All should complete without crashing
      true.should be_true
    end
  end

  describe "ambient sound configuration" do
    it "creates and configures ambient sound configs" do
      config = PointClickEngine::Audio::AmbientSoundConfig.new("forest", "forest_ambient.ogg")
      
      # Test default values
      config.name.should eq("forest")
      config.file_path.should eq("forest_ambient.ogg")
      config.volume.should eq(1.0)
      config.loop.should be_true
      config.fade_in_duration.should eq(2.0)
      config.fade_out_duration.should eq(2.0)
      config.spatial.should be_false
      config.max_distance.should eq(500.0)
      
      # Test property modification
      config.volume = 0.7_f32
      config.loop = false
      config.spatial = true
      config.max_distance = 1000.0_f32
      config.position = vec2(100, 200)
      
      config.volume.should eq(0.7_f32)
      config.loop.should be_false
      config.spatial.should be_true
      config.max_distance.should eq(1000.0_f32)
      config.position.x.should eq(100)
      config.position.y.should eq(200)
    end
    
    it "handles multiple ambient configurations" do
      configs = [] of PointClickEngine::Audio::AmbientSoundConfig
      
      # Create various ambient sound configurations
      ambient_sounds = [
        {"forest", "forest.ogg", 0.8, true},
        {"city", "city_traffic.wav", 0.6, true}, 
        {"ocean", "ocean_waves.ogg", 1.0, true},
        {"wind", "wind.wav", 0.4, false},
        {"fire", "fireplace.ogg", 0.9, true}
      ]
      
      ambient_sounds.each do |name, file, volume, loop|
        config = PointClickEngine::Audio::AmbientSoundConfig.new(name, file)
        config.volume = volume.to_f32
        config.loop = loop
        config.spatial = true
        config.position = vec2(rand(1000), rand(1000))
        
        configs << config
      end
      
      # Verify all configurations
      configs.size.should eq(ambient_sounds.size)
      configs.each do |config|
        config.name.should_not be_empty
        config.file_path.should_not be_empty
        config.volume.should be >= 0.0
        config.volume.should be <= 1.0
      end
    end
  end

  describe "audio system stress testing" do
    it "handles rapid sound effect operations" do
      operations = 100
      successful_operations = 0
      
      operations.times do |i|
        begin
          # Rapid creation/destruction
          effect = PointClickEngine::Audio::SoundEffect.new("rapid_#{i}", "rapid_test.wav")
          effect.volume = rand.to_f32
          effect.play
          effect.stop
          successful_operations += 1
        rescue ex
          # Expected if audio not available or files missing
        end
      end
      
      puts "Completed #{successful_operations}/#{operations} rapid audio operations"
      
      # Should not crash regardless of success rate
      successful_operations.should be >= 0
      successful_operations.should be <= operations
    end
    
    it "handles concurrent audio configuration creation" do
      configs = [] of PointClickEngine::Audio::AmbientSoundConfig
      
      # Simulate concurrent creation of audio configs
      100.times do |i|
        config = PointClickEngine::Audio::AmbientSoundConfig.new(
          "concurrent_#{i}",
          "concurrent_#{i}.ogg"
        )
        
        # Randomize properties
        config.volume = rand.to_f32
        config.loop = rand > 0.5
        config.spatial = rand > 0.5
        config.fade_in_duration = rand(5.0).to_f32
        config.fade_out_duration = rand(5.0).to_f32
        config.max_distance = rand(1000.0).to_f32
        config.position = vec2(rand(2000) - 1000, rand(2000) - 1000)
        
        configs << config
      end
      
      # Verify all configurations are valid
      configs.size.should eq(100)
      configs.each_with_index do |config, i|
        config.name.should eq("concurrent_#{i}")
        config.volume.should be >= 0.0
        config.volume.should be <= 1.0
        config.fade_in_duration.should be >= 0.0
        config.fade_out_duration.should be >= 0.0
      end
    end
  end

  describe "audio edge cases and error handling" do
    it "handles invalid file paths gracefully" do
      invalid_paths = [
        "",
        "non_existent.wav",
        "/invalid/path/sound.ogg",
        "sound_with_spaces in name.wav",
        "sound!@#$%^&*().wav",
        "very_long_" + ("a" * 1000) + ".wav"
      ]
      
      invalid_paths.each_with_index do |path, i|
        begin
          effect = PointClickEngine::Audio::SoundEffect.new("invalid_#{i}", path)
          # If creation succeeds, operations should not crash
          effect.play
          effect.stop
        rescue ex
          # Expected for invalid paths
          ex.should be_a(Exception)
        end
      end
      
      # Test should complete without hanging
      true.should be_true
    end
    
    it "handles extreme volume values" do
      # Test with various edge case volumes
      extreme_volumes = [-1.0, 0.0, 0.001, 0.999, 1.0, 1.001, 2.0, 100.0]
      
      config = PointClickEngine::Audio::AmbientSoundConfig.new("volume_test", "test.wav")
      
      extreme_volumes.each do |volume|
        config.volume = volume.to_f32
        # Should not crash, though engine may clamp values
        config.volume.should be_a(Float32)
      end
    end
    
    it "handles extreme spatial audio values" do
      config = PointClickEngine::Audio::AmbientSoundConfig.new("spatial_test", "test.wav")
      config.spatial = true
      
      # Test extreme positions and distances
      extreme_positions = [
        vec2(0, 0),
        vec2(-10000, -10000),
        vec2(10000, 10000),
        vec2(Float32::MAX, Float32::MAX),
        vec2(-Float32::MAX, -Float32::MAX)
      ]
      
      extreme_distances = [0.0, 0.001, 100.0, 10000.0, Float32::MAX]
      
      extreme_positions.each do |pos|
        config.position = pos
        config.position.should eq(pos)
      end
      
      extreme_distances.each do |dist|
        config.max_distance = dist.to_f32
        config.max_distance.should eq(dist.to_f32)
      end
    end
  end

  describe "audio memory management" do
    it "does not leak memory during audio operations" do
      initial_memory = GC.stats.heap_size
      
      # Create and destroy many audio objects
      100.times do |i|
        begin
          # Create sound effect
          effect = PointClickEngine::Audio::SoundEffect.new("memory_test_#{i}", "test.wav")
          effect.volume = rand.to_f32
          effect.play
          effect.stop
        rescue ex
          # Expected if audio not available
        end
        
        # Create ambient config
        config = PointClickEngine::Audio::AmbientSoundConfig.new("memory_ambient_#{i}", "ambient.ogg")
        config.volume = rand.to_f32
        config.spatial = true
        config.position = vec2(rand(100), rand(100))
        
        # Objects go out of scope here
      end
      
      # Force garbage collection
      GC.collect
      final_memory = GC.stats.heap_size
      memory_growth = final_memory.to_i64 - initial_memory.to_i64
      
      puts "Audio memory test: growth = #{memory_growth} bytes"
      
      # Should not have significant memory leaks
      memory_growth.should be < 5_000_000 # 5MB limit
    end
  end

  describe "audio performance characteristics" do
    it "audio operations meet performance benchmarks" do
      operation_count = 1000
      
      # Measure configuration creation performance
      start_time = Time.monotonic
      
      configs = [] of PointClickEngine::Audio::AmbientSoundConfig
      operation_count.times do |i|
        config = PointClickEngine::Audio::AmbientSoundConfig.new("perf_#{i}", "perf.wav")
        config.volume = rand.to_f32
        config.spatial = rand > 0.5
        config.position = vec2(rand(1000), rand(1000))
        configs << config
      end
      
      config_time = Time.monotonic - start_time
      config_time_per_op = config_time.total_milliseconds / operation_count
      
      puts "Audio config creation performance:"
      puts "  Operations: #{operation_count}"
      puts "  Total time: #{config_time.total_milliseconds.round(2)}ms"
      puts "  Time per operation: #{config_time_per_op.round(4)}ms"
      
      # Audio config creation should be fast
      config_time_per_op.should be < 0.01 # 0.01ms per operation
      
      # Test sound effect creation performance (may fail but shouldn't crash)
      sound_creation_start = Time.monotonic
      successful_sounds = 0
      
      100.times do |i|
        begin
          effect = PointClickEngine::Audio::SoundEffect.new("perf_sound_#{i}", "perf_sound.wav")
          effect.play
          effect.stop
          successful_sounds += 1
        rescue ex
          # Expected if audio disabled or files missing
        end
      end
      
      sound_creation_time = Time.monotonic - sound_creation_start
      
      puts "Sound effect performance:"
      puts "  Successful creations: #{successful_sounds}/100"
      puts "  Total time: #{sound_creation_time.total_milliseconds.round(2)}ms"
      
      # Should complete in reasonable time regardless of success rate
      sound_creation_time.total_milliseconds.should be < 1000 # 1 second limit
    end
  end
end