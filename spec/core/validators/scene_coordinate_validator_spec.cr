require "../../spec_helper"
require "../../../src/core/game_config"
require "../../../src/core/validators/scene_coordinate_validator"

def with_temp_scene_coordinate_game(&)
  temp_dir = File.tempname("scene_coordinate_validator")
  Dir.mkdir_p(temp_dir)
  yield temp_dir
ensure
  FileUtils.rm_rf(temp_dir) if temp_dir && Dir.exists?(temp_dir)
end

def load_scene_coordinate_config(config_path : String) : PointClickEngine::Core::GameConfig
  PointClickEngine::Core::GameConfig.from_file(config_path, skip_preflight: true)
end

describe PointClickEngine::Core::Validators::SceneCoordinateValidator do
  describe "#validate" do
    it "resolves scene globs relative to the config file and reports logical dimension issues" do
      with_temp_scene_coordinate_game do |temp_dir|
        scenes_dir = File.join(temp_dir, "scenes")
        Dir.mkdir_p(scenes_dir)

        File.write(File.join(temp_dir, "game_config.yaml"), <<-YAML
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

        File.write(File.join(scenes_dir, "scene1.yaml"), <<-YAML
          name: scene1
          background_path: bg.png
        YAML
        )

        File.write(File.join(scenes_dir, "scene2.yaml"), <<-YAML
          name: scene2
          background_path: bg.png
          logical_width: 0
          logical_height: -100
        YAML
        )

        File.write(File.join(scenes_dir, "scene3.yaml"), <<-YAML
          name: scene3
          background_path: bg.png
          logical_width: 320
          logical_height: 240
        YAML
        )

        File.write(File.join(scenes_dir, "scene4.yaml"), <<-YAML
          name: scene4
          background_path: bg.png
          logical_width: 1024
          logical_height: 768
        YAML
        )

        validator = PointClickEngine::Core::Validators::SceneCoordinateValidator.new
        result = validator.validate(load_scene_coordinate_config(File.join(temp_dir, "game_config.yaml")))

        result.errors.size.should eq(1)
        result.errors[0].should contain("Invalid logical dimensions")
        result.warnings.size.should eq(2)
        result.warnings.any? { |warning| warning.includes?("smaller than recommended minimum") }.should be_true

        info_messages = result.infos.select { |msg| msg.includes?("Using default logical dimensions") }
        info_messages.size.should eq(1)
      end
    end

    it "warns when scene geometry falls outside logical dimensions" do
      with_temp_scene_coordinate_game do |temp_dir|
        scenes_dir = File.join(temp_dir, "scenes")
        Dir.mkdir_p(scenes_dir)

        File.write(File.join(temp_dir, "game_config.yaml"), <<-YAML
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

        File.write(File.join(scenes_dir, "test_scene.yaml"), <<-YAML
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
                  - {x: 900, y: 100}
                  - {x: 900, y: 700}
                  - {x: 100, y: 700}
          hotspots:
            - name: door
              x: 750
              y: 300
              width: 100
              height: 50
          characters:
            - name: npc
              position:
                x: 850
                y: 650
        YAML
        )

        validator = PointClickEngine::Core::Validators::SceneCoordinateValidator.new
        result = validator.validate(load_scene_coordinate_config(File.join(temp_dir, "game_config.yaml")))

        vertex_warnings = result.warnings.select { |w| w.includes?("vertex") }
        vertex_warnings.size.should eq(4)

        hotspot_warnings = result.warnings.select { |w| w.includes?("Hotspot") }
        hotspot_warnings.size.should eq(1)

        character_warnings = result.warnings.select { |w| w.includes?("Character") }
        character_warnings.size.should eq(2)
      end
    end
  end
end
