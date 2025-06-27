require "./spec_helper"

describe "PreflightCheck Performance Analysis" do
  before_each do
    cleanup_test_files
  end

  after_each do
    cleanup_test_files
  end

  describe "scene count analysis" do
    it "warns about too many scenes" do
      Dir.mkdir_p("test_game_dir/scenes")

      # Create many scene files
      60.times do |i|
        File.write("test_game_dir/scenes/scene_#{i}.yaml", "name: \"scene_#{i}\"")
      end

      config_yaml = <<-YAML
      game:
        title: "Test Game"
      window:
        width: 1024
        height: 768
      assets:
        scenes:
          - "scenes/*.yaml"
      YAML

      File.write("test_game_dir/game.yaml", config_yaml)

      result = PointClickEngine::Core::PreflightCheck.run("test_game_dir/game.yaml")

      warning_found = result.warnings.any? { |w| w.includes?("Large number of scenes") }
      warning_found.should be_true
    end

    it "accepts reasonable scene counts" do
      Dir.mkdir_p("test_game_dir/scenes")

      # Create reasonable number of scenes
      10.times do |i|
        File.write("test_game_dir/scenes/scene_#{i}.yaml", "name: \"scene_#{i}\"")
      end

      config_yaml = <<-YAML
      game:
        title: "Test Game"
      window:
        width: 1024
        height: 768
      assets:
        scenes:
          - "scenes/*.yaml"
      YAML

      File.write("test_game_dir/game.yaml", config_yaml)

      result = PointClickEngine::Core::PreflightCheck.run("test_game_dir/game.yaml")

      # Should not warn about reasonable scene count
      scene_warnings = result.warnings.select { |w|
        w.includes?("scenes") && w.includes?("Large number")
      }
      scene_warnings.should be_empty
    end
  end

  describe "asset size analysis" do
    it "tracks total asset size" do
      Dir.mkdir_p("test_game_dir/audio")

      # Create some "large" files
      File.write("test_game_dir/audio/music1.ogg", "x" * 15_000_000) # 15MB
      File.write("test_game_dir/audio/music2.ogg", "x" * 20_000_000) # 20MB

      config_yaml = <<-YAML
      game:
        title: "Test Game"
      window:
        width: 1024
        height: 768
      assets:
        audio:
          music:
            track1: "audio/music1.ogg"
            track2: "audio/music2.ogg"
      YAML

      File.write("test_game_dir/game.yaml", config_yaml)

      result = PointClickEngine::Core::PreflightCheck.run("test_game_dir/game.yaml")

      # Should have warnings about large files
      large_asset_warnings = result.warnings.select { |w| w.includes?("Large assets") }
      large_asset_warnings.should_not be_empty
    end

    it "warns about individual large assets" do
      Dir.mkdir_p("test_game_dir/sprites")

      # Create a very large sprite file
      File.write("test_game_dir/sprites/huge_bg.png", "x" * 50_000_000) # 50MB

      config_yaml = <<-YAML
      game:
        title: "Test Game"
      window:
        width: 1024
        height: 768
      scenes:
        - name: "intro"
          background: "sprites/huge_bg.png"
      YAML

      File.write("test_game_dir/game.yaml", config_yaml)

      result = PointClickEngine::Core::PreflightCheck.run("test_game_dir/game.yaml")

      # Should warn about the large file
      size_warnings = result.warnings.select { |w|
        w.includes?("huge_bg.png") && (w.includes?("large") || w.includes?("size"))
      }
      size_warnings.should_not be_empty
    end
  end

  describe "resource usage summary" do
    it "provides resource usage summary" do
      Dir.mkdir_p("test_game_dir/sprites")
      Dir.mkdir_p("test_game_dir/audio")
      Dir.mkdir_p("test_game_dir/scenes")

      # Create various assets
      File.write("test_game_dir/sprites/player.png", "x" * 500_000)
      File.write("test_game_dir/sprites/bg.png", "x" * 2_000_000)
      File.write("test_game_dir/audio/theme.ogg", "x" * 5_000_000)
      File.write("test_game_dir/scenes/intro.yaml", "name: intro")

      config_yaml = <<-YAML
      game:
        title: "Test Game"
      window:
        width: 1024
        height: 768
      player:
        sprite_path: "sprites/player.png"
      assets:
        audio:
          music:
            theme: "audio/theme.ogg"
        scenes:
          - "scenes/*.yaml"
      YAML

      File.write("test_game_dir/game.yaml", config_yaml)

      result = PointClickEngine::Core::PreflightCheck.run("test_game_dir/game.yaml")

      # Should include resource summary in info
      resource_info = result.info.select { |i|
        i.includes?("Resource") || i.includes?("Total") || i.includes?("assets")
      }
      resource_info.should_not be_empty
    end
  end

  describe "memory usage estimation" do
    it "estimates memory usage" do
      Dir.mkdir_p("test_game_dir/sprites")

      # Create multiple sprite files
      10.times do |i|
        File.write("test_game_dir/sprites/sprite_#{i}.png", "x" * 1_000_000) # 1MB each
      end

      config_yaml = <<-YAML
      game:
        title: "Test Game"
      window:
        width: 1024
        height: 768
      preload_all_sprites: true
      YAML

      File.write("test_game_dir/game.yaml", config_yaml)

      result = PointClickEngine::Core::PreflightCheck.run("test_game_dir/game.yaml")

      # Should provide memory usage estimate
      memory_info = result.info.select { |i|
        i.includes?("memory") || i.includes?("Memory") || i.includes?("RAM")
      }
      memory_info.should_not be_empty
    end

    it "warns about high memory usage" do
      Dir.mkdir_p("test_game_dir/sprites")

      # Create many large sprites
      50.times do |i|
        File.write("test_game_dir/sprites/sprite_#{i}.png", "x" * 5_000_000) # 5MB each
      end

      config_yaml = <<-YAML
      game:
        title: "Test Game"
      window:
        width: 1920
        height: 1080
      preload_all_sprites: true
      YAML

      File.write("test_game_dir/game.yaml", config_yaml)

      result = PointClickEngine::Core::PreflightCheck.run("test_game_dir/game.yaml")

      # Should warn about high memory usage
      memory_warnings = result.warnings.select { |w|
        w.includes?("memory") && (w.includes?("high") || w.includes?("usage"))
      }
      memory_warnings.should_not be_empty
    end
  end

  describe "loading time estimation" do
    it "estimates loading times" do
      Dir.mkdir_p("test_game_dir/assets")

      # Create assets of various sizes
      File.write("test_game_dir/assets/small.png", "x" * 100_000)    # 100KB
      File.write("test_game_dir/assets/medium.png", "x" * 1_000_000) # 1MB
      File.write("test_game_dir/assets/large.png", "x" * 10_000_000) # 10MB

      config_yaml = <<-YAML
      game:
        title: "Test Game"
      window:
        width: 1024
        height: 768
      YAML

      File.write("test_game_dir/game.yaml", config_yaml)

      result = PointClickEngine::Core::PreflightCheck.run("test_game_dir/game.yaml")

      # Should provide loading time estimates
      loading_info = result.info.select { |i|
        i.includes?("loading") || i.includes?("Loading") || i.includes?("load time")
      }
      loading_info.should_not be_empty
    end
  end
end
