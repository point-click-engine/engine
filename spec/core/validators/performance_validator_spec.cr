require "../../spec_helper"
require "../../../src/core/enhanced_preflight_check"
require "../../../src/core/game_config"

def create_test_asset_files(files : Hash(String, Int32))
  files.each do |path, size|
    Dir.mkdir_p(File.dirname(path))
    File.write(path, "x" * size)
  end
end

def cleanup_test_assets(files : Array(String))
  files.each { |f| File.delete(f) if File.exists?(f) }
  ["test_assets", "test_scenes", "test_audio"].each { |d| Dir.delete(d) if Dir.exists?(d) rescue nil }
end

describe "Performance Validation" do
  after_each do
    cleanup_test_assets([
      "test_assets/large_background.png",
      "test_assets/huge_sprite.png",
      "test_scenes/scene1.yaml",
      "test_scenes/scene2.yaml",
      "test_audio/music.ogg",
      "test_audio/huge_sound.wav",
      "test_config.yaml",
    ])
  end

  describe "asset size analysis" do
    it "identifies oversized background images" do
      # Create large background file (>10MB)
      large_background_size = 12 * 1024 * 1024 # 12MB
      create_test_asset_files({
        "test_assets/large_background.png" => large_background_size,
      })

      config_content = <<-YAML
      game:
        title: "Performance Test"
        version: "1.0.0"
      window:
        width: 800
        height: 600
      assets:
        scenes: ["test_scenes/*.yaml"]
      start_scene: "test"
      YAML

      scene_content = <<-YAML
      name: "test"
      background_path: "test_assets/large_background.png"
      YAML

      Dir.mkdir_p("test_scenes")
      File.write("test_config.yaml", config_content)
      File.write("test_scenes/test.yaml", scene_content)

      result = PointClickEngine::Core::EnhancedPreflightCheck.run("test_config.yaml")

      # Should warn about large background image
      result.performance_hints.any? { |hint|
        hint.includes?("large") && hint.includes?("background")
      }.should be_true
    end

    it "calculates total asset memory footprint" do
      # Create multiple assets of varying sizes
      create_test_asset_files({
        "test_assets/bg1.png"    => 2 * 1024 * 1024, # 2MB
        "test_assets/bg2.png"    => 3 * 1024 * 1024, # 3MB
        "test_assets/sprite.png" => 500 * 1024,      # 500KB
        "test_audio/music.ogg"   => 8 * 1024 * 1024, # 8MB
      })

      config_content = <<-YAML
      game:
        title: "Memory Test"
        version: "1.0.0"
      window:
        width: 800
        height: 600
      assets:
        scenes: ["test_scenes/*.yaml"]
      start_scene: "test"
      YAML

      scene_content = <<-YAML
      name: "test"
      background_path: "test_assets/bg1.png"
      YAML

      Dir.mkdir_p("test_scenes")
      File.write("test_config.yaml", config_content)
      File.write("test_scenes/test.yaml", scene_content)

      result = PointClickEngine::Core::EnhancedPreflightCheck.run("test_config.yaml")

      # Should provide memory usage analysis
      result.info.any? { |info|
        info.includes?("memory") || info.includes?("MB")
      }.should be_true
    end

    it "warns about excessive number of assets" do
      # Create many small assets
      assets = {} of String => Int32
      100.times do |i|
        assets["test_assets/asset_#{i}.png"] = 10 * 1024 # 10KB each
      end
      create_test_asset_files(assets)

      config_content = <<-YAML
      game:
        title: "Asset Count Test"
        version: "1.0.0"
      window:
        width: 800
        height: 600
      assets:
        scenes: ["test_scenes/*.yaml"]
      start_scene: "test"
      YAML

      scene_content = <<-YAML
      name: "test"
      background_path: "test_assets/asset_1.png"
      YAML

      Dir.mkdir_p("test_scenes")
      File.write("test_config.yaml", config_content)
      File.write("test_scenes/test.yaml", scene_content)

      result = PointClickEngine::Core::EnhancedPreflightCheck.run("test_config.yaml")

      # Should warn about high asset count
      result.performance_hints.any? { |hint|
        hint.includes?("many") || hint.includes?("assets") || hint.includes?("count")
      }.should be_true
    end

    it "analyzes audio file sizes and formats" do
      # Create large uncompressed audio file
      large_audio_size = 50 * 1024 * 1024 # 50MB uncompressed
      create_test_asset_files({
        "test_audio/huge_sound.wav" => large_audio_size,
        "test_audio/compressed.ogg" => 2 * 1024 * 1024, # 2MB compressed
      })

      config_content = <<-YAML
      game:
        title: "Audio Performance Test"
        version: "1.0.0"
      window:
        width: 800
        height: 600
      assets:
        scenes: ["test_scenes/*.yaml"]
      start_scene: "test"
      YAML

      scene_content = <<-YAML
      name: "test"
      background_path: "test_assets/bg.png"
      audio:
        background_music: "test_audio/huge_sound.wav"
      YAML

      Dir.mkdir_p("test_scenes")
      File.write("test_config.yaml", config_content)
      File.write("test_scenes/test.yaml", scene_content)

      result = PointClickEngine::Core::EnhancedPreflightCheck.run("test_config.yaml")

      # Should suggest compression for large audio files
      result.performance_hints.any? { |hint|
        hint.includes?("audio") && (hint.includes?("compress") || hint.includes?("large"))
      }.should be_true
    end
  end

  describe "rendering performance analysis" do
    it "warns about high resolution assets vs window size" do
      # Create 4K asset for small window
      create_test_asset_files({
        "test_assets/4k_background.png" => 20 * 1024 * 1024, # 20MB 4K image
      })

      config_content = <<-YAML
      game:
        title: "Resolution Test"
        version: "1.0.0"
      window:
        width: 800
        height: 600
      assets:
        scenes: ["test_scenes/*.yaml"]
      start_scene: "test"
      YAML

      scene_content = <<-YAML
      name: "test"
      background_path: "test_assets/4k_background.png"
      YAML

      Dir.mkdir_p("test_scenes")
      File.write("test_config.yaml", config_content)
      File.write("test_scenes/test.yaml", scene_content)

      result = PointClickEngine::Core::EnhancedPreflightCheck.run("test_config.yaml")

      # Should warn about resolution mismatch
      result.performance_hints.any? { |hint|
        hint.includes?("resolution") || hint.includes?("downscale")
      }.should be_true
    end

    it "analyzes sprite sheet efficiency" do
      config_content = <<-YAML
      game:
        title: "Sprite Test"
        version: "1.0.0"
      window:
        width: 800
        height: 600
      player:
        sprite_path: "test_assets/inefficient_sprite.png"
        sprite:
          frame_width: 1000
          frame_height: 1000
          columns: 2
          rows: 2
      start_scene: "test"
      YAML

      # Create sprite file
      create_test_asset_files({
        "test_assets/inefficient_sprite.png" => 8 * 1024 * 1024, # 8MB sprite
      })

      scene_content = <<-YAML
      name: "test"
      background_path: "test_assets/bg.png"
      YAML

      Dir.mkdir_p("test_scenes")
      File.write("test_config.yaml", config_content)
      File.write("test_scenes/test.yaml", scene_content)

      result = PointClickEngine::Core::EnhancedPreflightCheck.run("test_config.yaml")

      # Should suggest sprite optimization
      result.performance_hints.any? { |hint|
        hint.includes?("sprite") && (hint.includes?("large") || hint.includes?("optimize"))
      }.should be_true
    end
  end

  describe "memory usage estimation" do
    it "estimates texture memory usage" do
      # Create assets that would consume significant texture memory
      create_test_asset_files({
        "test_assets/bg1.png"     => 4 * 1024 * 1024,
        "test_assets/bg2.png"     => 4 * 1024 * 1024,
        "test_assets/bg3.png"     => 4 * 1024 * 1024,
        "test_assets/sprites.png" => 2 * 1024 * 1024,
      })

      config_content = <<-YAML
      game:
        title: "Memory Estimation Test"
        version: "1.0.0"
      window:
        width: 1920
        height: 1080
      assets:
        scenes: ["test_scenes/*.yaml"]
      start_scene: "scene1"
      YAML

      # Create multiple scenes with different backgrounds
      Dir.mkdir_p("test_scenes")
      ["scene1", "scene2", "scene3"].each_with_index do |scene, i|
        scene_content = <<-YAML
        name: "#{scene}"
        background_path: "test_assets/bg#{i + 1}.png"
        YAML
        File.write("test_scenes/#{scene}.yaml", scene_content)
      end

      File.write("test_config.yaml", config_content)

      result = PointClickEngine::Core::EnhancedPreflightCheck.run("test_config.yaml")

      # Should provide memory usage estimates
      result.info.any? { |info|
        info.includes?("texture") && info.includes?("memory")
      }.should be_true
    end

    it "warns about potential memory pressure" do
      # Create configuration that would use lots of memory
      large_assets = {} of String => Int32
      20.times do |i|
        large_assets["test_assets/large_#{i}.png"] = 5 * 1024 * 1024 # 5MB each
      end
      create_test_asset_files(large_assets)

      config_content = <<-YAML
      game:
        title: "Memory Pressure Test"
        version: "1.0.0"
      window:
        width: 1920
        height: 1080
      assets:
        scenes: ["test_scenes/*.yaml"]
      start_scene: "test"
      YAML

      scene_content = <<-YAML
      name: "test"
      background_path: "test_assets/large_1.png"
      YAML

      Dir.mkdir_p("test_scenes")
      File.write("test_config.yaml", config_content)
      File.write("test_scenes/test.yaml", scene_content)

      result = PointClickEngine::Core::EnhancedPreflightCheck.run("test_config.yaml")

      # Should warn about high memory usage
      result.performance_hints.any? { |hint|
        hint.includes?("memory") && (hint.includes?("high") || hint.includes?("pressure"))
      }.should be_true
    end
  end

  describe "loading performance analysis" do
    it "estimates scene loading times" do
      # Create assets with different sizes to test loading estimates
      create_test_asset_files({
        "test_assets/quick_bg.png"   => 100 * 1024,       # 100KB - fast
        "test_assets/slow_bg.png"    => 15 * 1024 * 1024, # 15MB - slow
        "test_audio/quick_music.ogg" => 1 * 1024 * 1024,  # 1MB
        "test_audio/slow_music.wav"  => 30 * 1024 * 1024, # 30MB
      })

      config_content = <<-YAML
      game:
        title: "Loading Test"
        version: "1.0.0"
      window:
        width: 800
        height: 600
      assets:
        scenes: ["test_scenes/*.yaml"]
      start_scene: "slow_scene"
      YAML

      slow_scene_content = <<-YAML
      name: "slow_scene"
      background_path: "test_assets/slow_bg.png"
      audio:
        background_music: "test_audio/slow_music.wav"
      YAML

      Dir.mkdir_p("test_scenes")
      File.write("test_config.yaml", config_content)
      File.write("test_scenes/slow_scene.yaml", slow_scene_content)

      result = PointClickEngine::Core::EnhancedPreflightCheck.run("test_config.yaml")

      # Should warn about slow loading times
      result.performance_hints.any? { |hint|
        hint.includes?("load") && (hint.includes?("slow") || hint.includes?("time"))
      }.should be_true
    end

    it "suggests asset optimization strategies" do
      create_test_asset_files({
        "test_assets/unoptimized.png" => 25 * 1024 * 1024, # 25MB unoptimized
      })

      config_content = <<-YAML
      game:
        title: "Optimization Test"
        version: "1.0.0"
      window:
        width: 800
        height: 600
      assets:
        scenes: ["test_scenes/*.yaml"]
      start_scene: "test"
      YAML

      scene_content = <<-YAML
      name: "test"
      background_path: "test_assets/unoptimized.png"
      YAML

      Dir.mkdir_p("test_scenes")
      File.write("test_config.yaml", config_content)
      File.write("test_scenes/test.yaml", scene_content)

      result = PointClickEngine::Core::EnhancedPreflightCheck.run("test_config.yaml")

      # Should suggest specific optimization techniques
      result.performance_hints.any? { |hint|
        hint.includes?("optimize") || hint.includes?("compress") || hint.includes?("reduce")
      }.should be_true
    end
  end

  describe "performance thresholds" do
    it "applies different thresholds based on target platform" do
      # Mobile-targeted configuration should have stricter thresholds
      config_content = <<-YAML
      game:
        title: "Mobile Performance Test"
        version: "1.0.0"
      window:
        width: 1080
        height: 1920
      performance:
        target_platform: "mobile"
        max_memory_mb: 512
      assets:
        scenes: ["test_scenes/*.yaml"]
      start_scene: "test"
      YAML

      # Create asset that would be fine for desktop but too large for mobile
      create_test_asset_files({
        "test_assets/mobile_bg.png" => 8 * 1024 * 1024, # 8MB
      })

      scene_content = <<-YAML
      name: "test"  
      background_path: "test_assets/mobile_bg.png"
      YAML

      Dir.mkdir_p("test_scenes")
      File.write("test_config.yaml", config_content)
      File.write("test_scenes/test.yaml", scene_content)

      result = PointClickEngine::Core::EnhancedPreflightCheck.run("test_config.yaml")

      # Should apply mobile-specific performance warnings
      result.performance_hints.any? { |hint|
        hint.includes?("mobile") || hint.includes?("memory limit")
      }.should be_true
    end

    it "considers target frame rate in performance analysis" do
      config_content = <<-YAML
      game:
        title: "High FPS Test"
        version: "1.0.0"
      window:
        width: 800
        height: 600
      performance:
        target_fps: 120
      assets:
        scenes: ["test_scenes/*.yaml"] 
      start_scene: "test"
      YAML

      # Create complex scene that might struggle at high FPS
      scene_content = <<-YAML
      name: "test"
      background_path: "test_assets/complex_bg.png"
      hotspots:
      YAML

      # Add many hotspots to increase rendering complexity
      100.times do |i|
        scene_content += "  - name: \"hotspot_#{i}\"\n"
        scene_content += "    x: #{i * 10}\n"
        scene_content += "    y: #{i * 10}\n"
        scene_content += "    width: 50\n"
        scene_content += "    height: 50\n"
      end

      create_test_asset_files({
        "test_assets/complex_bg.png" => 5 * 1024 * 1024,
      })

      Dir.mkdir_p("test_scenes")
      File.write("test_config.yaml", config_content)
      File.write("test_scenes/test.yaml", scene_content)

      result = PointClickEngine::Core::EnhancedPreflightCheck.run("test_config.yaml")

      # Should warn about performance impact at high FPS
      result.performance_hints.any? { |hint|
        hint.includes?("fps") || hint.includes?("complex") || hint.includes?("performance")
      }.should be_true
    end
  end
end
