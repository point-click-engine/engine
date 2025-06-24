require "../spec_helper"

describe PointClickEngine::Scenes::TransitionType do
  it "includes all cheesy transition types" do
    # Basic transitions - just verify they exist as enum values
    PointClickEngine::Scenes::TransitionType::Instant
    PointClickEngine::Scenes::TransitionType::Fade
    PointClickEngine::Scenes::TransitionType::Slide
    PointClickEngine::Scenes::TransitionType::Iris

    # Cheesy/retro transitions
    PointClickEngine::Scenes::TransitionType::Swirl
    PointClickEngine::Scenes::TransitionType::StarWipe
    PointClickEngine::Scenes::TransitionType::HeartWipe
    PointClickEngine::Scenes::TransitionType::Curtain
    PointClickEngine::Scenes::TransitionType::Ripple
    PointClickEngine::Scenes::TransitionType::Checkerboard

    # Movie-like transitions
    PointClickEngine::Scenes::TransitionType::Warp
    PointClickEngine::Scenes::TransitionType::MatrixRain
    PointClickEngine::Scenes::TransitionType::Vortex
    PointClickEngine::Scenes::TransitionType::PageTurn
    PointClickEngine::Scenes::TransitionType::Fire

    # If we get here without compile errors, all types exist
    true.should be_true
  end
end

describe PointClickEngine::Scenes::SceneLoader do
  describe "transition type loading" do
    it "creates exit zones with cheesy transition types" do
      # Create a temporary YAML file for testing
      yaml_content = <<-YAML
      name: test_scene
      background_path: test.png
      hotspots:
        - name: cheesy_exit
          type: exit
          x: 100
          y: 100
          width: 100
          height: 100
          target_scene: other_scene
          transition_type: heart_wipe
      YAML

      Dir.mkdir_p("/tmp/point_click_test")
      File.write("/tmp/point_click_test/test_scene.yaml", yaml_content)

      scene = PointClickEngine::Scenes::SceneLoader.load_from_yaml("/tmp/point_click_test/test_scene.yaml")
      exit_zone = scene.hotspots.find { |h| h.is_a?(PointClickEngine::Scenes::ExitZone) }
      exit_zone.should_not be_nil

      if ez = exit_zone.as?(PointClickEngine::Scenes::ExitZone)
        ez.transition_type.should eq(PointClickEngine::Scenes::TransitionType::HeartWipe)
      end

      # Cleanup
      File.delete("/tmp/point_click_test/test_scene.yaml")
      Dir.delete("/tmp/point_click_test")
    end

    it "supports all transition type names in YAML" do
      transitions = {
        "instant"      => PointClickEngine::Scenes::TransitionType::Instant,
        "fade"         => PointClickEngine::Scenes::TransitionType::Fade,
        "slide"        => PointClickEngine::Scenes::TransitionType::Slide,
        "iris"         => PointClickEngine::Scenes::TransitionType::Iris,
        "swirl"        => PointClickEngine::Scenes::TransitionType::Swirl,
        "star_wipe"    => PointClickEngine::Scenes::TransitionType::StarWipe,
        "heart_wipe"   => PointClickEngine::Scenes::TransitionType::HeartWipe,
        "curtain"      => PointClickEngine::Scenes::TransitionType::Curtain,
        "ripple"       => PointClickEngine::Scenes::TransitionType::Ripple,
        "checkerboard" => PointClickEngine::Scenes::TransitionType::Checkerboard,
        "warp"         => PointClickEngine::Scenes::TransitionType::Warp,
        "matrix_rain"  => PointClickEngine::Scenes::TransitionType::MatrixRain,
        "vortex"       => PointClickEngine::Scenes::TransitionType::Vortex,
        "page_turn"    => PointClickEngine::Scenes::TransitionType::PageTurn,
        "fire"         => PointClickEngine::Scenes::TransitionType::Fire,
      }

      Dir.mkdir_p("/tmp/point_click_test")

      transitions.each do |name, expected_type|
        yaml_content = <<-YAML
        name: test_scene_#{name}
        background_path: test.png
        hotspots:
          - name: exit_#{name}
            type: exit
            x: 100
            y: 100
            width: 100
            height: 100
            target_scene: other_scene
            transition_type: #{name}
        YAML

        File.write("/tmp/point_click_test/test_#{name}.yaml", yaml_content)

        scene = PointClickEngine::Scenes::SceneLoader.load_from_yaml("/tmp/point_click_test/test_#{name}.yaml")
        exit_zone = scene.hotspots.find { |h| h.is_a?(PointClickEngine::Scenes::ExitZone) }
        exit_zone.should_not be_nil

        if ez = exit_zone.as?(PointClickEngine::Scenes::ExitZone)
          ez.transition_type.should eq(expected_type)
        end

        File.delete("/tmp/point_click_test/test_#{name}.yaml")
      end

      # Cleanup
      Dir.delete("/tmp/point_click_test")
    end
  end
end

describe "ExitZone transitions" do
  it "can be assigned all cheesy transition types" do
    position = RL::Vector2.new(x: 400f32, y: 300f32)
    size = RL::Vector2.new(x: 100f32, y: 100f32)

    [
      PointClickEngine::Scenes::TransitionType::Fade,
      PointClickEngine::Scenes::TransitionType::Swirl,
      PointClickEngine::Scenes::TransitionType::HeartWipe,
      PointClickEngine::Scenes::TransitionType::StarWipe,
      PointClickEngine::Scenes::TransitionType::Curtain,
      PointClickEngine::Scenes::TransitionType::Vortex,
      PointClickEngine::Scenes::TransitionType::Fire,
      PointClickEngine::Scenes::TransitionType::MatrixRain,
    ].each do |transition_type|
      exit_zone = PointClickEngine::Scenes::ExitZone.new(
        "test_exit",
        position,
        size,
        "target_scene"
      )
      exit_zone.transition_type = transition_type

      # Verify the exit zone can be created with the transition type
      exit_zone.transition_type.should eq(transition_type)
    end
  end
end

describe "Transition duration" do
  it "uses extra long transition duration for cheesy effect" do
    # This test documents that transitions are intentionally long (4.5 seconds)
    # for maximum cheese factor
    source = File.read("src/core/engine/verb_input_system.cr")
    source.should contain("transition_duration = 4.5f32")
  end
end
