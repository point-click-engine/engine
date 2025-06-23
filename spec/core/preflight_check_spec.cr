require "../spec_helper"
require "yaml"

describe PointClickEngine::Core::PreflightCheck do
  describe "CheckResult" do
    it "initializes with default values" do
      result = PointClickEngine::Core::PreflightCheck::CheckResult.new
      result.passed.should be_true
      result.errors.should be_empty
      result.warnings.should be_empty
      result.info.should be_empty
    end
  end

  describe ".run" do
    it "returns success for valid configuration" do
      temp_dir = File.tempname("preflight_test")
      Dir.mkdir_p("#{temp_dir}/assets")
      Dir.mkdir_p("#{temp_dir}/scenes")

      begin
        # Create valid config
        config_yaml = <<-YAML
        game:
          title: "Test Game"
          version: "1.0.0"
        window:
          width: 1024
          height: 768
        assets:
          scenes:
            - "scenes/*.yaml"
        YAML

        config_path = "#{temp_dir}/config.yaml"
        File.write(config_path, config_yaml)

        # Create a valid scene
        scene_yaml = <<-YAML
        name: test_scene
        background_path: assets/bg.png
        YAML
        File.write("#{temp_dir}/scenes/test_scene.yaml", scene_yaml)

        # Create the background asset
        File.write("#{temp_dir}/assets/bg.png", "fake png")

        result = PointClickEngine::Core::PreflightCheck.run(config_path)

        result.passed.should be_true
        result.errors.should be_empty
        result.info.should contain("✓ Configuration loaded successfully")
        result.info.should contain("✓ All assets validated")
        result.info.should contain("✓ 1 scene(s) validated")
      ensure
        FileUtils.rm_rf(temp_dir) if Dir.exists?(temp_dir)
      end
    end

    it "fails on configuration errors" do
      temp_file = File.tempname("bad_config", ".yaml")
      File.write(temp_file, "invalid yaml content:")

      begin
        result = PointClickEngine::Core::PreflightCheck.run(temp_file)

        result.passed.should be_false
        result.errors.should_not be_empty
        result.errors.first.should contain("Configuration Error")
      ensure
        File.delete(temp_file) if File.exists?(temp_file)
      end
    end

    it "fails on validation errors" do
      temp_dir = File.tempname("validation_test")
      Dir.mkdir_p(temp_dir)

      begin
        # Config with validation errors
        config_yaml = <<-YAML
        game:
          title: ""
        window:
          width: -100
          height: 768
        YAML

        config_path = "#{temp_dir}/config.yaml"
        File.write(config_path, config_yaml)

        result = PointClickEngine::Core::PreflightCheck.run(config_path)

        result.passed.should be_false
        result.errors.should contain("Game title cannot be empty")
        result.errors.should contain("Window width must be positive (got -100)")
      ensure
        FileUtils.rm_rf(temp_dir) if Dir.exists?(temp_dir)
      end
    end

    it "detects missing assets" do
      temp_dir = File.tempname("asset_test")
      Dir.mkdir_p("#{temp_dir}/scenes")

      begin
        config_yaml = <<-YAML
        game:
          title: "Test Game"
        player:
          sprite_path: "missing_player.png"
          sprite:
            frame_width: 32
            frame_height: 48
            columns: 4
            rows: 4
        assets:
          scenes: []
          audio:
            music:
              theme: "missing_theme.ogg"
        YAML

        config_path = "#{temp_dir}/config.yaml"
        File.write(config_path, config_yaml)

        result = PointClickEngine::Core::PreflightCheck.run(config_path)

        result.passed.should be_false
        result.errors.any? { |e| e.includes?("Missing sprite: missing_player.png") }.should be_true
        result.errors.any? { |e| e.includes?("Missing music: missing_theme.ogg") }.should be_true
      ensure
        FileUtils.rm_rf(temp_dir) if Dir.exists?(temp_dir)
      end
    end

    it "validates scene files" do
      temp_dir = File.tempname("scene_validation")
      Dir.mkdir_p("#{temp_dir}/scenes")

      begin
        config_yaml = <<-YAML
        game:
          title: "Test Game"
        assets:
          scenes:
            - "scenes/*.yaml"
        YAML

        config_path = "#{temp_dir}/config.yaml"
        File.write(config_path, config_yaml)

        # Create invalid scene
        scene_yaml = <<-YAML
        name: wrong_name
        YAML
        File.write("#{temp_dir}/scenes/test_scene.yaml", scene_yaml)

        result = PointClickEngine::Core::PreflightCheck.run(config_path)

        result.passed.should be_false
        result.errors.any? { |e| e.includes?("Scene 'test_scene.yaml':") }.should be_true
        result.errors.any? { |e| e.includes?("Missing required field 'background_path'") }.should be_true
      ensure
        FileUtils.rm_rf(temp_dir) if Dir.exists?(temp_dir)
      end
    end

    it "generates warnings for common issues" do
      temp_dir = File.tempname("warning_test")
      Dir.mkdir_p(temp_dir)

      begin
        config_yaml = <<-YAML
        game:
          title: "Test Game"
        window:
          width: 4096
          height: 2160
        start_scene: "missing_scene"
        assets:
          scenes: []
        YAML

        config_path = "#{temp_dir}/config.yaml"
        File.write(config_path, config_yaml)

        result = PointClickEngine::Core::PreflightCheck.run(config_path)

        # Should pass but with warnings
        result.passed.should be_true
        result.warnings.should contain("Window size (4096x2160) is larger than 1920x1080 - may cause performance issues")
        result.warnings.should contain("Start scene 'missing_scene' not found in scene files")
      ensure
        FileUtils.rm_rf(temp_dir) if Dir.exists?(temp_dir)
      end
    end

    it "checks performance considerations" do
      temp_dir = File.tempname("performance_test")
      Dir.mkdir_p("#{temp_dir}/music")
      Dir.mkdir_p("#{temp_dir}/scenes")

      begin
        # Create large music file (simulate)
        File.write("#{temp_dir}/music/theme.ogg", "x" * (15 * 1024 * 1024)) # 15MB

        # Create many scenes
        60.times do |i|
          scene_yaml = <<-YAML
          name: scene#{i}
          background_path: bg.png
          YAML
          File.write("#{temp_dir}/scenes/scene#{i}.yaml", scene_yaml)
        end

        config_yaml = <<-YAML
        game:
          title: "Test Game"
        assets:
          scenes:
            - "scenes/*.yaml"
          audio:
            music:
              theme: "music/theme.ogg"
        YAML

        config_path = "#{temp_dir}/config.yaml"
        File.write(config_path, config_yaml)

        result = PointClickEngine::Core::PreflightCheck.run(config_path)

        result.warnings.any? { |w| w.includes?("Large assets detected") }.should be_true
        result.warnings.any? { |w| w.includes?("Music 'theme': 15.0 MB") }.should be_true
        result.warnings.should contain("Large number of scenes (60) may increase loading time")
      ensure
        FileUtils.rm_rf(temp_dir) if Dir.exists?(temp_dir)
      end
    end

    it "validates rendering and player setup" do
      temp_dir = File.tempname("rendering_test")
      Dir.mkdir_p("#{temp_dir}/assets/sprites")
      Dir.mkdir_p("#{temp_dir}/assets/backgrounds")
      Dir.mkdir_p("#{temp_dir}/scenes")

      begin
        # Create player sprite file
        File.write("#{temp_dir}/assets/sprites/player.png", "fake png")

        # Create background files
        File.write("#{temp_dir}/assets/backgrounds/scene1.png", "fake bg")
        File.write("#{temp_dir}/assets/backgrounds/small_bg.png", "small bg")

        config_yaml = <<-YAML
        game:
          title: "Test Game"
        window:
          width: 1024
          height: 768
        player:
          name: "Hero"
          sprite_path: "assets/sprites/player.png"
          sprite:
            frame_width: 32
            frame_height: 48
            columns: 4
            rows: 4
          start_position:
            x: 100.0
            y: 200.0
        assets:
          scenes:
            - "scenes/*.yaml"
        start_scene: "scene1"
        YAML

        config_path = "#{temp_dir}/config.yaml"
        File.write(config_path, config_yaml)

        # Create scene with valid background
        scene1_yaml = <<-YAML
        name: scene1
        background_path: assets/backgrounds/scene1.png
        walkable_areas:
          regions:
            - name: main_area
              walkable: true
              vertices:
                - {x: 50, y: 150}
                - {x: 300, y: 150}
                - {x: 300, y: 400}
                - {x: 50, y: 400}
        YAML
        File.write("#{temp_dir}/scenes/scene1.yaml", scene1_yaml)

        # Create scene with missing background
        scene2_yaml = <<-YAML
        name: scene2
        background_path: assets/backgrounds/missing.png
        YAML
        File.write("#{temp_dir}/scenes/scene2.yaml", scene2_yaml)

        # Create scene with potentially small background
        scene3_yaml = <<-YAML
        name: scene3
        background_path: assets/backgrounds/small_320x180_bg.png
        YAML
        File.write("#{temp_dir}/scenes/scene3.yaml", scene3_yaml)

        result = PointClickEngine::Core::PreflightCheck.run(config_path)

        # Should detect player sprite correctly
        result.info.should contain("✓ Player sprite found: assets/sprites/player.png")

        # Should detect valid backgrounds
        result.info.should contain("✓ Background found for scene 'scene1': assets/backgrounds/scene1.png")

        # Should detect missing background
        result.errors.should contain("Background image not found for scene 'scene2.yaml': assets/backgrounds/missing.png")

        # Should warn about potentially small backgrounds
        result.warnings.any? { |w| w.includes?("background may be too small") && w.includes?("320x180") }.should be_true
      ensure
        FileUtils.rm_rf(temp_dir) if Dir.exists?(temp_dir)
      end
    end

    it "detects missing player sprite" do
      temp_dir = File.tempname("player_sprite_test")
      Dir.mkdir_p(temp_dir)

      begin
        config_yaml = <<-YAML
        game:
          title: "Test Game"
        player:
          name: "Hero"
          sprite_path: "assets/sprites/missing_player.png"
          sprite:
            frame_width: 32
            frame_height: 48
            columns: 4
            rows: 4
        YAML

        config_path = "#{temp_dir}/config.yaml"
        File.write(config_path, config_yaml)

        result = PointClickEngine::Core::PreflightCheck.run(config_path)

        result.passed.should be_false
        result.errors.should contain("Player sprite not found: assets/sprites/missing_player.png")
      ensure
        FileUtils.rm_rf(temp_dir) if Dir.exists?(temp_dir)
      end
    end

    it "warns about missing player sprite path" do
      temp_dir = File.tempname("no_sprite_path_test")
      Dir.mkdir_p(temp_dir)

      begin
        config_yaml = <<-YAML
        game:
          title: "Test Game"
        player:
          name: "Hero"
          sprite:
            frame_width: 32
            frame_height: 48
            columns: 4
            rows: 4
        YAML

        config_path = "#{temp_dir}/config.yaml"
        File.write(config_path, config_yaml)

        result = PointClickEngine::Core::PreflightCheck.run(config_path)

        result.warnings.should contain("No player sprite path specified - player will be invisible")
      ensure
        FileUtils.rm_rf(temp_dir) if Dir.exists?(temp_dir)
      end
    end

    it "validates player sprite dimensions" do
      temp_dir = File.tempname("sprite_dimensions_test")
      Dir.mkdir_p("#{temp_dir}/assets/sprites")

      begin
        # Create player sprite file
        File.write("#{temp_dir}/assets/sprites/player.png", "fake png")

        config_yaml = <<-YAML
        game:
          title: "Test Game"
        player:
          name: "Hero"
          sprite_path: "assets/sprites/player.png"
          sprite:
            frame_width: 0
            frame_height: -10
            columns: 4
            rows: 4
        YAML

        config_path = "#{temp_dir}/config.yaml"
        File.write(config_path, config_yaml)

        result = PointClickEngine::Core::PreflightCheck.run(config_path)

        result.passed.should be_false
        result.errors.should contain("Invalid player sprite dimensions: 0x-10")
      ensure
        FileUtils.rm_rf(temp_dir) if Dir.exists?(temp_dir)
      end
    end

    it "warns about missing player sprite dimensions" do
      temp_dir = File.tempname("no_sprite_dims_test")
      Dir.mkdir_p("#{temp_dir}/assets/sprites")

      begin
        # Create player sprite file
        File.write("#{temp_dir}/assets/sprites/player.png", "fake png")

        config_yaml = <<-YAML
        game:
          title: "Test Game"
        player:
          name: "Hero"
          sprite_path: "assets/sprites/player.png"
        YAML

        config_path = "#{temp_dir}/config.yaml"
        File.write(config_path, config_yaml)

        result = PointClickEngine::Core::PreflightCheck.run(config_path)

        result.warnings.should contain("No player sprite dimensions specified - may cause rendering issues")
      ensure
        FileUtils.rm_rf(temp_dir) if Dir.exists?(temp_dir)
      end
    end

    it "detects missing player configuration" do
      temp_dir = File.tempname("no_player_test")
      Dir.mkdir_p(temp_dir)

      begin
        config_yaml = <<-YAML
        game:
          title: "Test Game"
        YAML

        config_path = "#{temp_dir}/config.yaml"
        File.write(config_path, config_yaml)

        result = PointClickEngine::Core::PreflightCheck.run(config_path)

        result.passed.should be_false
        result.errors.should contain("No player configuration found")
      ensure
        FileUtils.rm_rf(temp_dir) if Dir.exists?(temp_dir)
      end
    end

    it "warns about start scene spawn positions" do
      temp_dir = File.tempname("spawn_position_test")
      Dir.mkdir_p("#{temp_dir}/scenes")

      begin
        config_yaml = <<-YAML
        game:
          title: "Test Game"
        start_scene: "main"
        assets:
          scenes:
            - "scenes/*.yaml"
        YAML

        config_path = "#{temp_dir}/config.yaml"
        File.write(config_path, config_yaml)

        # Create start scene without spawn position
        scene_yaml = <<-YAML
        name: main
        background_path: bg.png
        YAML
        File.write("#{temp_dir}/scenes/main.yaml", scene_yaml)

        result = PointClickEngine::Core::PreflightCheck.run(config_path)

        result.warnings.should contain("Start scene 'main' may not have proper player spawn position defined")
      ensure
        FileUtils.rm_rf(temp_dir) if Dir.exists?(temp_dir)
      end
    end

    it "detects player starting in non-walkable area" do
      temp_dir = File.tempname("walkable_area_test")
      Dir.mkdir_p("#{temp_dir}/scenes")

      begin
        config_yaml = <<-YAML
        game:
          title: "Test Game"
        player:
          name: "Hero"
          sprite_path: "player.png"
          sprite:
            frame_width: 32
            frame_height: 48
            columns: 4
            rows: 4
          start_position:
            x: 500.0
            y: 400.0
        start_scene: "library"
        assets:
          scenes:
            - "scenes/*.yaml"
        YAML

        config_path = "#{temp_dir}/config.yaml"
        File.write(config_path, config_yaml)

        # Create scene with walkable areas where player starts in non-walkable area
        scene_yaml = <<-YAML
        name: library
        background_path: bg.png
        walkable_areas:
          regions:
            - name: main_floor
              walkable: true
              vertices:
                - {x: 100, y: 350}
                - {x: 900, y: 350}
                - {x: 900, y: 700}
                - {x: 100, y: 700}
            - name: desk_area
              walkable: false
              vertices:
                - {x: 380, y: 380}
                - {x: 620, y: 380}
                - {x: 620, y: 550}
                - {x: 380, y: 550}
        YAML
        File.write("#{temp_dir}/scenes/library.yaml", scene_yaml)

        result = PointClickEngine::Core::PreflightCheck.run(config_path)

        result.passed.should be_false
        result.errors.should contain("Player starting position (500.0, 400.0) is in a non-walkable area in scene 'library'")
      ensure
        FileUtils.rm_rf(temp_dir) if Dir.exists?(temp_dir)
      end
    end

    it "validates player starting in walkable area" do
      temp_dir = File.tempname("valid_walkable_test")
      Dir.mkdir_p("#{temp_dir}/scenes")

      begin
        config_yaml = <<-YAML
        game:
          title: "Test Game"
        player:
          name: "Hero"
          sprite_path: "player.png"
          sprite:
            frame_width: 32
            frame_height: 48
            columns: 4
            rows: 4
          start_position:
            x: 300.0
            y: 450.0
        start_scene: "library"
        assets:
          scenes:
            - "scenes/*.yaml"
        YAML

        config_path = "#{temp_dir}/config.yaml"
        File.write(config_path, config_yaml)

        # Create scene with walkable areas where player starts in walkable area
        scene_yaml = <<-YAML
        name: library
        background_path: bg.png
        walkable_areas:
          regions:
            - name: main_floor
              walkable: true
              vertices:
                - {x: 100, y: 350}
                - {x: 900, y: 350}
                - {x: 900, y: 700}
                - {x: 100, y: 700}
            - name: desk_area
              walkable: false
              vertices:
                - {x: 380, y: 380}
                - {x: 620, y: 380}
                - {x: 620, y: 550}
                - {x: 380, y: 550}
        YAML
        File.write("#{temp_dir}/scenes/library.yaml", scene_yaml)

        result = PointClickEngine::Core::PreflightCheck.run(config_path)

        result.info.should contain("✓ Player starting position is in walkable area in scene 'library'")
      ensure
        FileUtils.rm_rf(temp_dir) if Dir.exists?(temp_dir)
      end
    end

    it "warns when player starts outside any walkable area" do
      temp_dir = File.tempname("outside_walkable_test")
      Dir.mkdir_p("#{temp_dir}/scenes")

      begin
        config_yaml = <<-YAML
        game:
          title: "Test Game"
        player:
          name: "Hero"
          sprite_path: "player.png"
          sprite:
            frame_width: 32
            frame_height: 48
            columns: 4
            rows: 4
          start_position:
            x: 50.0
            y: 200.0
        start_scene: "test_scene"
        assets:
          scenes:
            - "scenes/*.yaml"
        YAML

        config_path = "#{temp_dir}/config.yaml"
        File.write(config_path, config_yaml)

        # Create scene with walkable areas where player is completely outside
        scene_yaml = <<-YAML
        name: test_scene
        background_path: bg.png
        walkable_areas:
          regions:
            - name: main_area
              walkable: true
              vertices:
                - {x: 100, y: 300}
                - {x: 500, y: 300}
                - {x: 500, y: 600}
                - {x: 100, y: 600}
        YAML
        File.write("#{temp_dir}/scenes/test_scene.yaml", scene_yaml)

        result = PointClickEngine::Core::PreflightCheck.run(config_path)

        result.warnings.should contain("Player starting position (50.0, 200.0) may not be in any walkable area in scene 'test_scene'")
      ensure
        FileUtils.rm_rf(temp_dir) if Dir.exists?(temp_dir)
      end
    end

    it "handles scenes without walkable areas" do
      temp_dir = File.tempname("no_walkable_areas_test")
      Dir.mkdir_p("#{temp_dir}/scenes")

      begin
        config_yaml = <<-YAML
        game:
          title: "Test Game"
        player:
          name: "Hero"
          sprite_path: "player.png"
          sprite:
            frame_width: 32
            frame_height: 48
            columns: 4
            rows: 4
          start_position:
            x: 300.0
            y: 400.0
        start_scene: "simple_scene"
        assets:
          scenes:
            - "scenes/*.yaml"
        YAML

        config_path = "#{temp_dir}/config.yaml"
        File.write(config_path, config_yaml)

        # Create scene without walkable areas
        scene_yaml = <<-YAML
        name: simple_scene
        background_path: bg.png
        hotspots:
          - name: test_hotspot
            x: 100
            y: 100
            width: 50
            height: 50
        YAML
        File.write("#{temp_dir}/scenes/simple_scene.yaml", scene_yaml)

        result = PointClickEngine::Core::PreflightCheck.run(config_path)

        # Should not produce walkable area warnings for scenes without walkable areas
        result.warnings.none? { |w| w.includes?("walkable area") }.should be_true
        result.errors.none? { |e| e.includes?("walkable area") }.should be_true
      ensure
        FileUtils.rm_rf(temp_dir) if Dir.exists?(temp_dir)
      end
    end

    it "handles complex polygon walkable areas" do
      temp_dir = File.tempname("complex_polygon_test")
      Dir.mkdir_p("#{temp_dir}/scenes")

      begin
        config_yaml = <<-YAML
        game:
          title: "Test Game"
        player:
          name: "Hero"
          sprite_path: "player.png"
          sprite:
            frame_width: 32
            frame_height: 48
            columns: 4
            rows: 4
          start_position:
            x: 250.0
            y: 300.0
        start_scene: "complex_scene"
        assets:
          scenes:
            - "scenes/*.yaml"
        YAML

        config_path = "#{temp_dir}/config.yaml"
        File.write(config_path, config_yaml)

        # Create scene with complex polygon walkable area
        scene_yaml = <<-YAML
        name: complex_scene
        background_path: bg.png
        walkable_areas:
          regions:
            - name: L_shaped_area
              walkable: true
              vertices:
                - {x: 100, y: 200}
                - {x: 400, y: 200}
                - {x: 400, y: 350}
                - {x: 300, y: 350}
                - {x: 300, y: 500}
                - {x: 100, y: 500}
        YAML
        File.write("#{temp_dir}/scenes/complex_scene.yaml", scene_yaml)

        result = PointClickEngine::Core::PreflightCheck.run(config_path)

        result.info.should contain("✓ Player starting position is in walkable area in scene 'complex_scene'")
      ensure
        FileUtils.rm_rf(temp_dir) if Dir.exists?(temp_dir)
      end
    end

    it "detects overlapping hotspots" do
      temp_dir = File.tempname("overlapping_hotspots_test")
      Dir.mkdir_p("#{temp_dir}/scenes")

      begin
        config_yaml = <<-YAML
        game:
          title: "Test Game"
        assets:
          scenes:
            - "scenes/*.yaml"
        YAML

        config_path = "#{temp_dir}/config.yaml"
        File.write(config_path, config_yaml)

        # Create scene with overlapping hotspots
        scene_yaml = <<-YAML
        name: test_scene
        background_path: bg.png
        hotspots:
          - name: hotspot1
            x: 100
            y: 100
            width: 200
            height: 150
            actions:
              look: "First hotspot"
          - name: hotspot2
            x: 150
            y: 120
            width: 180
            height: 120
            actions:
              look: "Second hotspot"
        YAML
        File.write("#{temp_dir}/scenes/test_scene.yaml", scene_yaml)

        result = PointClickEngine::Core::PreflightCheck.run(config_path)

        result.warnings.should contain("Scene 'test_scene': Hotspots 'hotspot1' and 'hotspot2' overlap - may cause interaction issues")
      ensure
        FileUtils.rm_rf(temp_dir) if Dir.exists?(temp_dir)
      end
    end

    it "detects character blocked by hotspot" do
      temp_dir = File.tempname("character_blocked_test")
      Dir.mkdir_p("#{temp_dir}/scenes")

      begin
        config_yaml = <<-YAML
        game:
          title: "Test Game"
        assets:
          scenes:
            - "scenes/*.yaml"
        YAML

        config_path = "#{temp_dir}/config.yaml"
        File.write(config_path, config_yaml)

        # Create scene where character is blocked by hotspot
        scene_yaml = <<-YAML
        name: test_scene
        background_path: bg.png
        hotspots:
          - name: desk
            x: 380
            y: 380
            width: 240
            height: 170
            actions:
              look: "A large desk"
        characters:
          - name: butler
            position:
              x: 400
              y: 450
            sprite_path: butler.png
        YAML
        File.write("#{temp_dir}/scenes/test_scene.yaml", scene_yaml)

        result = PointClickEngine::Core::PreflightCheck.run(config_path)

        result.warnings.should contain("Scene 'test_scene': Character 'butler' at (400.0, 450.0) may be blocked by hotspot 'desk'")
      ensure
        FileUtils.rm_rf(temp_dir) if Dir.exists?(temp_dir)
      end
    end
  end

  describe ".run!" do
    it "raises on failure" do
      temp_file = File.tempname("bad_config", ".yaml")
      File.write(temp_file, "invalid yaml:")

      begin
        expect_raises(PointClickEngine::Core::ValidationError) do
          PointClickEngine::Core::PreflightCheck.run!(temp_file)
        end
      ensure
        File.delete(temp_file) if File.exists?(temp_file)
      end
    end

    it "succeeds without raising for valid config" do
      temp_dir = File.tempname("valid_config")
      Dir.mkdir_p(temp_dir)

      begin
        config_yaml = <<-YAML
        game:
          title: "Test Game"
        YAML

        config_path = "#{temp_dir}/config.yaml"
        File.write(config_path, config_yaml)

        # Should not raise
        PointClickEngine::Core::PreflightCheck.run!(config_path)
      ensure
        FileUtils.rm_rf(temp_dir) if Dir.exists?(temp_dir)
      end
    end
  end
end
