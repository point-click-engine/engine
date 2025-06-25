require "../../spec_helper"
require "../../../src/core/validation_result"

describe "SceneCoordinateValidator" do
  describe "#validate" do
    it "validates logical dimensions" do
      # Create a temporary test config and scene files
      temp_dir = File.tempname
      Dir.mkdir_p(temp_dir)

      # Config file
      config_path = File.join(temp_dir, "game_config.yaml")
      File.write(config_path, <<-YAML
        game:
          title: "Test Game"
        window:
          width: 1024
          height: 768
        assets:
          scenes:
            - "scenes/*.yaml"
        YAML
      )

      # Scene directory
      scenes_dir = File.join(temp_dir, "scenes")
      Dir.mkdir_p(scenes_dir)

      # Scene with missing logical dimensions
      scene1_path = File.join(scenes_dir, "scene1.yaml")
      File.write(scene1_path, <<-YAML
        name: scene1
        background_path: bg.png
        YAML
      )

      # Scene with invalid logical dimensions
      scene2_path = File.join(scenes_dir, "scene2.yaml")
      File.write(scene2_path, <<-YAML
        name: scene2
        background_path: bg.png
        logical_width: 0
        logical_height: -100
        YAML
      )

      # Scene with small logical dimensions
      scene3_path = File.join(scenes_dir, "scene3.yaml")
      File.write(scene3_path, <<-YAML
        name: scene3
        background_path: bg.png
        logical_width: 320
        logical_height: 240
        YAML
      )

      # Scene with good logical dimensions
      scene4_path = File.join(scenes_dir, "scene4.yaml")
      File.write(scene4_path, <<-YAML
        name: scene4
        background_path: bg.png
        logical_width: 1024
        logical_height: 768
        YAML
      )

      # Load config and validate
      config = PointClickEngine::Core::GameConfig.from_yaml(config_path)
      validator = PointClickEngine::Core::Validators::SceneCoordinateValidator.new
      result = validator.validate(config)

      # Check results
      result.errors.size.should eq(1)
      result.errors[0].should contain("Invalid logical dimensions")

      result.warnings.size.should eq(1)
      result.warnings[0].should contain("smaller than recommended minimum")

      info_messages = result.infos.select { |msg| msg.includes?("Using default logical dimensions") }
      info_messages.size.should eq(1)

      # Cleanup
      FileUtils.rm_rf(temp_dir)
    end

    it "validates coordinates against logical dimensions" do
      temp_dir = File.tempname
      Dir.mkdir_p(temp_dir)

      # Config file
      config_path = File.join(temp_dir, "game_config.yaml")
      File.write(config_path, <<-YAML
        game:
          title: "Test Game"
        window:
          width: 1024
          height: 768
        assets:
          scenes:
            - "scenes/*.yaml"
        YAML
      )

      # Scene directory
      scenes_dir = File.join(temp_dir, "scenes")
      Dir.mkdir_p(scenes_dir)

      # Scene with out-of-bounds coordinates
      scene_path = File.join(scenes_dir, "test_scene.yaml")
      File.write(scene_path, <<-YAML
        name: test_scene
        background_path: bg.png
        logical_width: 800
        logical_height: 600
        walkable_areas:
          regions:
            - name: floor
              walkable: true
              vertices:
                - {x: 100, y: 100}
                - {x: 900, y: 100}  # X exceeds logical_width
                - {x: 900, y: 700}  # Both exceed limits
                - {x: 100, y: 700}  # Y exceeds logical_height
        hotspots:
          - name: door
            x: 750
            y: 300
            width: 100  # Will extend past logical_width
            height: 50
        characters:
          - name: npc
            position:
              x: 850  # Exceeds logical_width
              y: 650  # Exceeds logical_height
        YAML
      )

      # Load config and validate
      config = PointClickEngine::Core::GameConfig.from_yaml(config_path)
      validator = PointClickEngine::Core::Validators::SceneCoordinateValidator.new
      result = validator.validate(config)

      # Check warnings
      vertex_warnings = result.warnings.select { |w| w.includes?("vertex") }
      vertex_warnings.size.should eq(4) # 2 X and 2 Y warnings

      hotspot_warnings = result.warnings.select { |w| w.includes?("Hotspot") }
      hotspot_warnings.size.should eq(1) # Extends outside width

      character_warnings = result.warnings.select { |w| w.includes?("Character") }
      character_warnings.size.should eq(2) # X and Y position warnings

      # Cleanup
      FileUtils.rm_rf(temp_dir)
    end
  end
end
