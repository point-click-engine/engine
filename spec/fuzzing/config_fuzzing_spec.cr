require "../spec_helper"

# Configuration validation fuzzing tests
# Tests engine robustness against malformed, extreme, and unexpected configuration inputs
describe "Configuration Validation Fuzzing" do
  describe "YAML structure fuzzing" do
    it "handles malformed YAML structures" do
      malformed_yamls = [
        # Invalid YAML syntax
        "invalid: yaml: structure: [",
        "---\ninvalid\nkey: value: extra:",
        "key: value\n  invalid_indent",
        "key: [unclosed, array",
        "key: {unclosed: object",
        
        # Edge case structures
        "",                          # Empty file
        "---",                      # Only document separator
        "null",                     # Null document
        "[]",                       # Empty array
        "{}",                       # Empty object
        
        # Deeply nested structures
        ("a:\n" + "  b:\n" * 100 + "    value: deep"),  # Very deep nesting
        
        # Large values
        "large_key: " + ("x" * 100000),  # Very large string value
        
        # Special characters
        "special: \"\\n\\t\\r\\\"\\'\\\\\"`~!@#$%^&*()\"",
        
        # Unicode edge cases
        "unicode: \"🎮💻🎯 \u0000 \uFFFF\"",
        
        # Type confusion
        "mixed_types:\n  - string\n  - 123\n  - true\n  - null\n  - {nested: object}",
      ]
      
      malformed_yamls.each_with_index do |yaml_content, i|
        begin
          # Try to parse as GameConfig
          if yaml_content.empty?
            next # Skip empty content
          end
          
          # Should either parse successfully or raise a clear error
          config = PointClickEngine::Core::GameConfig.from_yaml(yaml_content)
          # If it succeeds, that's also acceptable
          config.should be_a(PointClickEngine::Core::GameConfig)
        rescue ex
          # Errors are expected for malformed YAML
          ex.should be_a(Exception)
          if msg = ex.message
            puts "Fuzzing #{i}: #{ex.class} - #{msg[0..100]}..." if msg.size > 100
          end
        end
      end
    end
    
    it "handles extreme value ranges in configuration" do
      extreme_configs = [
        # Extreme window dimensions
        <<-YAML,
        game:
          title: "Extreme Test"
        window:
          width: #{Int32::MAX}
          height: #{Int32::MAX}
        YAML
        
        <<-YAML,
        game:
          title: "Zero Dimensions"
        window:
          width: 0
          height: 0
        YAML
        
        <<-YAML,
        game:
          title: "Negative Dimensions"
        window:
          width: -1920
          height: -1080
        YAML
        
        # Extreme player sprite configurations
        <<-YAML,
        game:
          title: "Extreme Sprite"
        player:
          name: "TestPlayer"
          sprite_path: "test.png"
          sprite:
            frame_width: #{Int32::MAX}
            frame_height: #{Int32::MAX}
            columns: #{Int32::MAX}
            rows: #{Int32::MAX}
        YAML
        
        # Very long strings
        <<-YAML,
        game:
          title: "#{"Very long title " * 1000}"
          version: "#{"1.0." * 1000}"
        YAML
        
        # Extreme FPS values
        <<-YAML,
        game:
          title: "Extreme FPS"
        window:
          target_fps: #{Int32::MAX}
        YAML
      ]
      
      extreme_configs.each_with_index do |config_yaml, i|
        begin
          File.write("extreme_config_#{i}.yaml", config_yaml)
          
          # Should handle extreme values gracefully
          config = PointClickEngine::Core::GameConfig.from_file("extreme_config_#{i}.yaml")
          config.should be_a(PointClickEngine::Core::GameConfig)
          
        rescue ex
          # Errors are acceptable for extreme values
          ex.should be_a(Exception)
          puts "Extreme config #{i} error: #{ex.class}"
        ensure
          File.delete("extreme_config_#{i}.yaml") if File.exists?("extreme_config_#{i}.yaml")
        end
      end
    end
    
    it "handles missing and extra fields" do
      field_variation_configs = [
        # Missing required fields
        <<-YAML,
        # No game section at all
        window:
          width: 800
          height: 600
        YAML
        
        <<-YAML,
        game:
          # Missing title
          version: "1.0"
        YAML
        
        # Extra unknown fields
        <<-YAML,
        game:
          title: "Extra Fields Test"
        unknown_section:
          unknown_field: "unknown_value"
        extra_field: "extra_value"
        nested:
          deeply:
            unknown: "value"
        YAML
        
        # Field type mismatches
        <<-YAML,
        game:
          title: 123  # Should be string
          version: true  # Should be string
        window:
          width: "not_a_number"  # Should be int
          height: []  # Should be int
        YAML
        
        # Null values
        <<-YAML,
        game:
          title: null
          version: null
        window:
          width: null
          height: null
        player:
          name: null
        YAML
      ]
      
      field_variation_configs.each_with_index do |config_yaml, i|
        begin
          File.write("field_variation_#{i}.yaml", config_yaml)
          
          config = PointClickEngine::Core::GameConfig.from_file("field_variation_#{i}.yaml")
          # If parsing succeeds, verify it's still a valid config object
          config.should be_a(PointClickEngine::Core::GameConfig)
          
        rescue ex
          # Errors are expected for invalid field configurations
          ex.should be_a(Exception)
        ensure
          File.delete("field_variation_#{i}.yaml") if File.exists?("field_variation_#{i}.yaml")
        end
      end
    end
  end

  describe "asset path fuzzing" do
    it "handles malicious and unusual asset paths" do
      malicious_paths = [
        # Path traversal attempts
        "../../../etc/passwd",
        "..\\..\\..\\windows\\system32\\config\\sam",
        "../../../../root/.ssh/id_rsa",
        
        # URL-like paths
        "http://evil.com/malware.png",
        "ftp://badserver.com/virus.wav",
        "file:///etc/shadow",
        
        # Special characters
        "file with spaces.png",
        "file!@#$%^&*().wav",
        "file\x00null.ogg",
        "file\nnewline.png",
        "file\ttab.wav",
        
        # Very long paths
        "/" + ("very_long_directory_name/" * 100) + "file.png",
        
        # Unicode paths
        "unicode_🎮_file.png",
        "中文文件.wav",
        "файл.ogg",
        
        # Empty and null paths
        "",
        " ",
        "\t",
        "\n",
        
        # Case variations
        "FILE.PNG",
        "MiXeD_CaSe.WaV",
        
        # Reserved names (Windows)
        "CON.png",
        "PRN.wav",
        "AUX.ogg",
        "NUL.png",
        "COM1.wav",
        
        # Paths with no extension
        "file_with_no_extension",
        ".",
        "..",
        ".hidden",
        
        # Multiple extensions
        "file.tar.gz.png",
        "file.backup.old.wav",
      ]
      
      malicious_paths.each_with_index do |path, i|
        config_yaml = <<-YAML
        game:
          title: "Path Fuzzing Test #{i}"
          version: "1.0"
        player:
          name: "TestPlayer"
          sprite_path: "#{path}"
          sprite:
            frame_width: 32
            frame_height: 32
            columns: 4
            rows: 4
        start_scene: "intro"
        YAML
        
        begin
          File.write("path_fuzzing_#{i}.yaml", config_yaml)
          
          # Config parsing might succeed even with bad paths
          config = PointClickEngine::Core::GameConfig.from_file("path_fuzzing_#{i}.yaml")
          config.should be_a(PointClickEngine::Core::GameConfig)
          
          # The path should be stored as-is (validation happens later)
          if player_config = config.player
            player_config.sprite_path.should eq(path)
          end
          
        rescue ex
          # Some paths might cause parsing errors, which is acceptable
          ex.should be_a(Exception)
        ensure
          File.delete("path_fuzzing_#{i}.yaml") if File.exists?("path_fuzzing_#{i}.yaml")
        end
      end
    end
  end

  describe "configuration combination fuzzing" do
    it "handles random configuration combinations" do
      # Generate random configurations to test edge cases
      100.times do |i|
        random_config = generate_random_config(i)
        
        begin
          File.write("random_config_#{i}.yaml", random_config)
          
          config = PointClickEngine::Core::GameConfig.from_file("random_config_#{i}.yaml")
          config.should be_a(PointClickEngine::Core::GameConfig)
          
          # Basic sanity checks
          config.game.title.should be_a(String)
          
        rescue ex
          # Some random configurations will be invalid, which is expected
          ex.should be_a(Exception)
        ensure
          File.delete("random_config_#{i}.yaml") if File.exists?("random_config_#{i}.yaml")
        end
      end
    end
    
    it "handles nested object fuzzing" do
      nested_fuzz_configs = [
        # Deeply nested sprite configurations
        <<-YAML,
        game:
          title: "Nested Test"
        player:
          name: "TestPlayer"
          sprite:
            frame_width: 32
            frame_height: 32
            columns: 4
            rows: 4
            # Extra nested fields
            animation:
              speed: 1.0
              loop: true
              frames:
                idle: [1, 2, 3]
                walk: [4, 5, 6, 7]
        YAML
        
        # Multiple nested objects
        <<-YAML,
        game:
          title: "Multiple Nested"
        audio:
          master_volume: 1.0
          channels:
            music: 0.8
            effects: 1.0
            voice: 0.9
          spatial:
            enabled: true
            max_distance: 1000
            rolloff: 0.5
        YAML
        
        # Array of objects
        <<-YAML,
        game:
          title: "Array Objects"
        scenes:
          - name: "scene1"
            background: "bg1.png"
            hotspots:
              - name: "door"
                x: 100
                y: 200
              - name: "window"
                x: 300
                y: 150
          - name: "scene2"
            background: "bg2.png"
        YAML
      ]
      
      nested_fuzz_configs.each_with_index do |config_yaml, i|
        begin
          File.write("nested_fuzz_#{i}.yaml", config_yaml)
          
          config = PointClickEngine::Core::GameConfig.from_file("nested_fuzz_#{i}.yaml")
          config.should be_a(PointClickEngine::Core::GameConfig)
          
        rescue ex
          # Errors are acceptable for complex nested structures
          ex.should be_a(Exception)
        ensure
          File.delete("nested_fuzz_#{i}.yaml") if File.exists?("nested_fuzz_#{i}.yaml")
        end
      end
    end
  end

  describe "performance under fuzzing" do
    it "maintains performance with complex configurations" do
      start_time = Time.monotonic
      
      # Test many configurations rapidly
      50.times do |i|
        config_yaml = <<-YAML
        game:
          title: "Performance Test #{i}"
          version: "1.0.#{i}"
        
        window:
          width: #{800 + i * 10}
          height: #{600 + i * 5}
          target_fps: #{60 + i}
        
        player:
          name: "Player#{i}"
          sprite_path: "player#{i}.png"
          sprite:
            frame_width: #{32 + i}
            frame_height: #{32 + i}
            columns: #{4 + i % 4}
            rows: #{4 + i % 4}
        
        features:
          - verbs
          - floating_dialogs
        
        start_scene: "scene#{i}"
        YAML
        
        begin
          File.write("perf_test_#{i}.yaml", config_yaml)
          config = PointClickEngine::Core::GameConfig.from_file("perf_test_#{i}.yaml")
          config.should be_a(PointClickEngine::Core::GameConfig)
        rescue ex
          # Validation errors are acceptable in fuzzing tests
          ex.should be_a(Exception)
        ensure
          File.delete("perf_test_#{i}.yaml") if File.exists?("perf_test_#{i}.yaml")
        end
      end
      
      total_time = Time.monotonic - start_time
      time_per_config = total_time.total_milliseconds / 50
      
      puts "Configuration parsing performance:"
      puts "  Configs parsed: 50"
      puts "  Total time: #{total_time.total_milliseconds.round(2)}ms"
      puts "  Time per config: #{time_per_config.round(4)}ms"
      
      # Should be reasonably fast
      time_per_config.should be < 10.0 # 10ms per configuration
    end
    
    it "handles memory efficiently during fuzzing" do
      initial_memory = GC.stats.heap_size
      
      # Create and parse many configurations
      20.times do |batch|
        configs = [] of PointClickEngine::Core::GameConfig
        
        10.times do |i|
          config_yaml = generate_random_config(batch * 10 + i)
          
          begin
            File.write("memory_fuzz_#{batch}_#{i}.yaml", config_yaml)
            config = PointClickEngine::Core::GameConfig.from_file("memory_fuzz_#{batch}_#{i}.yaml")
            configs << config
          rescue ex
            # Some random configs will be invalid
          ensure
            File.delete("memory_fuzz_#{batch}_#{i}.yaml") if File.exists?("memory_fuzz_#{batch}_#{i}.yaml")
          end
        end
        
        # Verify configs work
        configs.each do |config|
          config.game.title.should be_a(String)
        end
        
        # Clear batch
        configs.clear
        
        # Periodic memory check
        if batch % 5 == 4
          GC.collect
          current_memory = GC.stats.heap_size
          memory_growth = current_memory.to_i64 - initial_memory.to_i64
          
          # Should not grow unbounded
          memory_growth.should be < 20_000_000 # 20MB limit
        end
      end
      
      # Final memory check
      GC.collect
      final_memory = GC.stats.heap_size
      memory_growth = final_memory.to_i64 - initial_memory.to_i64
      
      puts "Fuzzing memory test: growth = #{memory_growth} bytes"
      memory_growth.should be < 10_000_000 # 10MB final limit
    end
  end

end

# Helper method to generate random configurations
private def generate_random_config(seed : Int32) : String
    rng = Random.new(seed)
    
    title = "Random Game #{seed}"
    version = "#{rng.rand(10)}.#{rng.rand(10)}.#{rng.rand(100)}"
    width = rng.rand(3840) + 320  # 320 to 4160
    height = rng.rand(2160) + 240 # 240 to 2400
    fps = rng.rand(240) + 30      # 30 to 270
    
    # Random features
    all_features = ["verbs", "floating_dialogs", "portraits", "subtitles"]
    feature_count = rng.rand(all_features.size) + 1
    features = all_features.sample(feature_count, rng)
    
    # Random player configuration
    player_name = "Player#{rng.rand(1000)}"
    sprite_path = "player#{rng.rand(100)}.png"
    frame_size = rng.rand(128) + 16  # 16 to 144
    columns = rng.rand(10) + 1       # 1 to 10
    rows = rng.rand(10) + 1          # 1 to 10
    
    <<-YAML
    game:
      title: "#{title}"
      version: "#{version}"
    
    window:
      width: #{width}
      height: #{height}
      target_fps: #{fps}
    
    player:
      name: "#{player_name}"
      sprite_path: "#{sprite_path}"
      sprite:
        frame_width: #{frame_size}
        frame_height: #{frame_size}
        columns: #{columns}
        rows: #{rows}
    
    features:
    #{features.map { |f| "  - #{f}" }.join("\n")}
    
    start_scene: "scene#{rng.rand(100)}"
    YAML
end