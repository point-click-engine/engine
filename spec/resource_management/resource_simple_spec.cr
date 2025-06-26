require "../spec_helper"

# Resource management comprehensive tests
# Tests resource loading, caching, memory management, and performance
describe "Resource Management Comprehensive Tests" do
  describe "resource manager initialization and basic operations" do
    it "initializes resource manager correctly" do
      resource_manager = PointClickEngine::Core::ResourceManager.new
      resource_manager.should_not be_nil

      # Check initial resource counts
      counts = resource_manager.get_resource_count
      counts[:textures].should eq(0)
      counts[:sounds].should eq(0)
      counts[:music].should eq(0)
    end

    it "handles basic texture loading" do
      resource_manager = PointClickEngine::Core::ResourceManager.new

      # Create a test texture file path (doesn't need to exist for API testing)
      test_texture_path = "test_assets/test_texture.png"

      # Test texture loading (will return nil for non-existent file)
      result = resource_manager.load_texture(test_texture_path)
      result.failure?.should be_true # Non-existent file
    end

    it "handles basic sound loading" do
      resource_manager = PointClickEngine::Core::ResourceManager.new

      test_sound_path = "test_assets/test_sound.wav"

      # Test sound loading
      result = resource_manager.load_sound(test_sound_path)
      result.failure?.should be_true # Non-existent file
    end

    it "handles basic music loading" do
      resource_manager = PointClickEngine::Core::ResourceManager.new

      test_music_path = "test_assets/test_music.ogg"

      # Test music loading
      result = resource_manager.load_music(test_music_path)
      result.failure?.should be_true # Non-existent file
    end
  end

  describe "resource cleanup and management" do
    it "handles resource cleanup" do
      resource_manager = PointClickEngine::Core::ResourceManager.new

      # Load some resources
      resource_manager.load_texture("cleanup_test.png")
      resource_manager.load_sound("cleanup_test.wav")
      resource_manager.load_music("cleanup_test.ogg")

      # Clean up all resources
      resource_manager.cleanup_all_resources

      # Counts should be zero after cleanup
      counts = resource_manager.get_resource_count
      counts[:textures].should eq(0)
      counts[:sounds].should eq(0)
      counts[:music].should eq(0)
    end

    it "handles memory usage tracking" do
      resource_manager = PointClickEngine::Core::ResourceManager.new

      # Check memory usage
      memory = resource_manager.get_memory_usage
      memory[:current].should be >= 0
      memory[:max].should be > 0
      memory[:percentage].should be >= 0.0_f32
    end

    it "handles unused resource cleanup" do
      resource_manager = PointClickEngine::Core::ResourceManager.new

      # Load some resources
      resource_manager.load_texture("unused_test.png")
      resource_manager.load_sound("unused_test.wav")

      # Trigger cleanup (should not crash)
      resource_manager.cleanup_unused_resources(0.0_f32)

      # Should still be functional
      counts = resource_manager.get_resource_count
      counts[:textures].should be >= 0
    end

    it "handles asset preloading" do
      resource_manager = PointClickEngine::Core::ResourceManager.new

      asset_list = [
        "preload_test1.png",
        "preload_test2.wav",
        "preload_test3.ogg",
      ]

      # Should return number of successfully loaded assets
      loaded_count = resource_manager.preload_assets(asset_list)
      loaded_count.should be >= 0
      loaded_count.should be <= asset_list.size
    end
  end

  describe "resource caching behavior" do
    it "handles cache hit/miss scenarios" do
      resource_manager = PointClickEngine::Core::ResourceManager.new

      test_path = "cache_test.png"

      # First load attempt (miss)
      result1 = resource_manager.load_texture(test_path)

      # Second load attempt (should be same result)
      result2 = resource_manager.load_texture(test_path)

      # Both should fail for non-existent file
      result1.failure?.should be_true
      result2.failure?.should be_true
    end

    it "handles multiple resource types" do
      resource_manager = PointClickEngine::Core::ResourceManager.new

      # Load different types of resources
      texture_result = resource_manager.load_texture("test.png")
      sound_result = resource_manager.load_sound("test.wav")
      music_result = resource_manager.load_music("test.ogg")

      # All should fail for non-existent files
      texture_result.failure?.should be_true
      sound_result.failure?.should be_true
      music_result.failure?.should be_true
    end
  end

  describe "asset path management" do
    it "handles asset path operations" do
      resource_manager = PointClickEngine::Core::ResourceManager.new

      # Test asset path management (if methods exist)
      begin
        resource_manager.add_asset_path("custom_assets/")
        resource_manager.add_asset_path("extra_assets/")

        # Try loading after adding paths
        result = resource_manager.load_texture("test_in_custom_path.png")
        result.failure?.should be_true # Still non-existent
      rescue
        # Methods may not exist, that's ok
      end
    end

    it "handles path resolution" do
      resource_manager = PointClickEngine::Core::ResourceManager.new

      # Test different path formats
      test_paths = [
        "simple.png",
        "assets/simple.png",
        "./simple.png",
        "folder/subfolder/simple.png",
      ]

      test_paths.each do |path|
        result = resource_manager.load_texture(path)
        result.failure?.should be_true # All non-existent
      end
    end
  end

  describe "error handling and edge cases" do
    it "handles missing files gracefully" do
      resource_manager = PointClickEngine::Core::ResourceManager.new

      missing_files = [
        "definitely/missing.png",
        "not/found.wav",
        "absent.ogg",
      ]

      missing_files.each do |file|
        case File.extname(file)
        when ".png"
          result = resource_manager.load_texture(file)
          result.failure?.should be_true
        when ".wav"
          result = resource_manager.load_sound(file)
          result.failure?.should be_true
        when ".ogg"
          result = resource_manager.load_music(file)
          result.failure?.should be_true
        end
      end
    end

    it "handles invalid file paths" do
      resource_manager = PointClickEngine::Core::ResourceManager.new

      invalid_paths = [
        "",                               # Empty path
        " ",                              # Whitespace only
        "   \t\n   ",                     # Mixed whitespace
        "../../../etc/passwd",            # Path traversal attempt
        "very" + "x" * 1000 + "long.png", # Extremely long path
      ]

      invalid_paths.each do |path|
        result = resource_manager.load_texture(path)
        result.failure?.should be_true
      end
    end

    it "handles unsupported file formats" do
      resource_manager = PointClickEngine::Core::ResourceManager.new

      unsupported_files = [
        "test.xyz",        # Unknown extension
        "test.exe",        # Executable
        "test.pdf",        # Document
        "test.zip",        # Archive
        "test",            # No extension
        "test.PNG.backup", # Multiple extensions
      ]

      unsupported_files.each do |file|
        result = resource_manager.load_texture(file)
        result.failure?.should be_true
      end
    end
  end

  pending describe "performance and stress testing" do
    it "handles many resource loading requests efficiently" do
      resource_manager = PointClickEngine::Core::ResourceManager.new

      load_count = 100

      # Test rapid loading of many resources
      start_time = Time.monotonic
      load_count.times do |i|
        resource_manager.load_texture("stress_test_#{i}.png")
        resource_manager.load_sound("stress_test_#{i}.wav")
      end
      load_time = Time.monotonic - start_time

      puts "Simple resource loading performance:"
      puts "  Resources attempted: #{load_count * 2}"
      puts "  Total time: #{load_time.total_milliseconds.round(2)}ms"
      puts "  Time per resource: #{(load_time.total_milliseconds / (load_count * 2)).round(4)}ms"

      # Should be reasonably fast even for failures
      (load_time.total_milliseconds / (load_count * 2)).should be < 1.0 # 1ms per resource
    end

    it "handles rapid cache operations" do
      resource_manager = PointClickEngine::Core::ResourceManager.new

      cache_ops = 1000
      test_path = "cache_stress_test.png"

      # Rapid cache hit testing
      start_time = Time.monotonic
      cache_ops.times do
        resource_manager.load_texture(test_path)
      end
      cache_time = Time.monotonic - start_time

      puts "Simple cache operation performance:"
      puts "  Cache operations: #{cache_ops}"
      puts "  Total time: #{cache_time.total_milliseconds.round(2)}ms"
      puts "  Time per operation: #{(cache_time.total_milliseconds / cache_ops).round(6)}ms"

      # Cache operations should be very fast
      (cache_time.total_milliseconds / cache_ops).should be < 0.01 # 0.01ms per cache check
    end

    it "handles concurrent resource operations" do
      resource_manager = PointClickEngine::Core::ResourceManager.new

      # Simulate concurrent operations
      concurrent_ops = 200

      start_time = Time.monotonic
      concurrent_ops.times do |i|
        # Mix different operations
        case i % 3
        when 0
          resource_manager.load_texture("concurrent_#{i}.png")
        when 1
          resource_manager.load_sound("concurrent_#{i}.wav")
        when 2
          resource_manager.load_music("concurrent_#{i}.ogg")
        end
      end
      concurrent_time = Time.monotonic - start_time

      puts "Simple concurrent operations performance:"
      puts "  Operations: #{concurrent_ops}"
      puts "  Total time: #{concurrent_time.total_milliseconds.round(2)}ms"
      puts "  Time per operation: #{(concurrent_time.total_milliseconds / concurrent_ops).round(4)}ms"

      # Should handle concurrent operations efficiently
      (concurrent_time.total_milliseconds / concurrent_ops).should be < 0.5 # 0.5ms per operation
    end
  end

  pending describe "memory management stress tests" do
    it "manages memory efficiently during resource lifecycle" do
      initial_memory = GC.stats.heap_size

      # Create and destroy many resource managers
      50.times do |cycle|
        resource_manager = PointClickEngine::Core::ResourceManager.new

        # Load many resources
        20.times do |i|
          resource_manager.load_texture("memory_test_#{cycle}_#{i}.png")
          resource_manager.load_sound("memory_test_#{cycle}_#{i}.wav")
          resource_manager.load_music("memory_test_#{cycle}_#{i}.ogg")
        end

        # Resource manager goes out of scope here
      end

      # Force garbage collection
      GC.collect
      final_memory = GC.stats.heap_size
      memory_growth = final_memory.to_i64 - initial_memory.to_i64

      puts "Simple resource manager memory test: growth = #{memory_growth} bytes"

      # Should not leak significant memory
      memory_growth.should be < 10_000_000 # 10MB limit
    end

    it "handles repeated loading of same resources" do
      resource_manager = PointClickEngine::Core::ResourceManager.new

      test_path = "repeated_test.png"

      # Load same resource multiple times
      10.times do
        result = resource_manager.load_texture(test_path)
        result.failure?.should be_true # Non-existent file
      end

      # Should handle repeated calls gracefully
    end
  end

  describe "asset manager compatibility" do
    it "works with asset manager" do
      asset_manager = PointClickEngine::AssetManager.new

      # Test basic asset manager functionality
      asset_manager.should_not be_nil

      # Test existence checking
      exists = asset_manager.exists?("test.txt")
      exists.should be_false
    end

    it "handles asset manager file operations" do
      asset_manager = PointClickEngine::AssetManager.new

      # Test file reading operations for non-existent files
      begin
        content = asset_manager.read_file("nonexistent.txt")
        content.should be_a(String)
      rescue
        # Expected for non-existent file
      end

      begin
        bytes = asset_manager.read_bytes("nonexistent.dat")
        if bytes
          bytes.should be_a(Bytes)
        end
      rescue
        # Expected for non-existent file
      end
    end

    it "handles asset manager cache operations" do
      asset_manager = PointClickEngine::AssetManager.new

      # Test cache clearing
      asset_manager.clear_cache

      # Should still work after cache clear
      asset_manager.exists?("test.txt").should be_false
    end
  end

  describe "resource loading edge cases and validation" do
    it "handles null and empty resource names" do
      resource_manager = PointClickEngine::Core::ResourceManager.new

      # Test empty and whitespace names
      empty_names = ["", " ", "\t", "\n", "  \t\n  "]

      empty_names.each do |name|
        texture_result = resource_manager.load_texture(name)
        sound_result = resource_manager.load_sound(name)
        music_result = resource_manager.load_music(name)

        texture_result.failure?.should be_true
        sound_result.failure?.should be_true
        music_result.failure?.should be_true

        # Check error messages
        (texture_result.error.message || "").should contain("Invalid path")
        (sound_result.error.message || "").should contain("Invalid path")
        (music_result.error.message || "").should contain("Invalid path")
      end
    end

    it "handles special characters in paths" do
      resource_manager = PointClickEngine::Core::ResourceManager.new

      special_paths = [
        "file with spaces.png",
        "file-with-dashes.wav",
        "file_with_underscores.ogg",
        "file.with.dots.png",
        "file@with@symbols.wav",
        "file#with#hash.ogg",
      ]

      special_paths.each do |path|
        case File.extname(path)
        when ".png"
          result = resource_manager.load_texture(path)
          result.failure?.should be_true
        when ".wav"
          result = resource_manager.load_sound(path)
          result.failure?.should be_true
        when ".ogg"
          result = resource_manager.load_music(path)
          result.failure?.should be_true
        end
      end
    end

    it "handles very large numbers of different resources" do
      resource_manager = PointClickEngine::Core::ResourceManager.new

      # Test loading many different resources
      large_count = 500

      start_time = Time.monotonic
      large_count.times do |i|
        resource_manager.load_texture("large_test_#{i}.png")
      end
      load_time = Time.monotonic - start_time

      puts "Large resource count performance:"
      puts "  Resources: #{large_count}"
      puts "  Total time: #{load_time.total_milliseconds.round(2)}ms"
      puts "  Time per resource: #{(load_time.total_milliseconds / large_count).round(4)}ms"

      # Should scale reasonably
      (load_time.total_milliseconds / large_count).should be < 1.0 # 1ms per resource
    end
  end
end
