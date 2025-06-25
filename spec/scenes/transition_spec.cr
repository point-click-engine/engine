require "../spec_helper"

describe PointClickEngine::Graphics::TransitionEffect do
  it "includes all cheesy transition types" do
    # Basic transitions - just verify they exist as enum values
    PointClickEngine::Graphics::TransitionEffect::Fade
    PointClickEngine::Graphics::TransitionEffect::Dissolve
    PointClickEngine::Graphics::TransitionEffect::SlideLeft
    PointClickEngine::Graphics::TransitionEffect::SlideRight
    PointClickEngine::Graphics::TransitionEffect::SlideUp
    PointClickEngine::Graphics::TransitionEffect::SlideDown
    PointClickEngine::Graphics::TransitionEffect::Iris

    # Cheesy/retro transitions
    PointClickEngine::Graphics::TransitionEffect::Swirl
    PointClickEngine::Graphics::TransitionEffect::StarWipe
    PointClickEngine::Graphics::TransitionEffect::HeartWipe
    PointClickEngine::Graphics::TransitionEffect::Curtain
    PointClickEngine::Graphics::TransitionEffect::Ripple
    PointClickEngine::Graphics::TransitionEffect::Checkerboard

    # Movie-like transitions
    PointClickEngine::Graphics::TransitionEffect::Warp
    PointClickEngine::Graphics::TransitionEffect::MatrixRain
    PointClickEngine::Graphics::TransitionEffect::Vortex
    PointClickEngine::Graphics::TransitionEffect::PageTurn
    PointClickEngine::Graphics::TransitionEffect::Fire

    # If we get here without compile errors, all types exist
    true.should be_true
  end
end

describe PointClickEngine::Scenes::TransitionHelper do
  describe "parse_transition_command" do
    it "parses full transition command" do
      result = PointClickEngine::Scenes::TransitionHelper.parse_transition_command("transition:garden:swirl:4.5:300,400")

      result.should_not be_nil
      if result
        result[:scene].should eq("garden")
        result[:effect].should eq(PointClickEngine::Graphics::TransitionEffect::Swirl)
        result[:duration].should eq(4.5f32)
        result[:position].should_not be_nil
        if pos = result[:position]
          pos.x.should eq(300f32)
          pos.y.should eq(400f32)
        end
      end
    end

    it "parses transition with minimal parameters" do
      result = PointClickEngine::Scenes::TransitionHelper.parse_transition_command("transition:lobby")

      result.should_not be_nil
      if result
        result[:scene].should eq("lobby")
        result[:effect].should eq(PointClickEngine::Graphics::TransitionEffect::Fade)
        result[:duration].should eq(1.0f32)
        result[:position].should be_nil
      end
    end

    it "returns nil for non-transition commands" do
      result = PointClickEngine::Scenes::TransitionHelper.parse_transition_command("examine_painting")
      result.should be_nil
    end
  end
end

describe PointClickEngine::Scenes::SceneLoader do
  describe "action-based transitions" do
    it "loads hotspots with transition actions" do
      # Create a temporary YAML file for testing
      yaml_content = <<-YAML
      name: test_scene
      background_path: test.png
      hotspots:
        - name: magic_door
          x: 100
          y: 100
          width: 100
          height: 100
          description: "A magical door"
          default_verb: open
          object_type: door
          actions:
            look: "It's a door glowing with magical energy"
            open: "transition:wizard_tower:heart_wipe:3.0:500,300"
            use: "transition:wizard_tower:heart_wipe:3.0:500,300"
      YAML

      Dir.mkdir_p("/tmp/point_click_test")
      File.write("/tmp/point_click_test/test_scene.yaml", yaml_content)

      scene = PointClickEngine::Scenes::SceneLoader.load_from_yaml("/tmp/point_click_test/test_scene.yaml")
      door = scene.hotspots.find { |h| h.name == "magic_door" }
      door.should_not be_nil

      if d = door
        d.action_commands["open"].should eq("transition:wizard_tower:heart_wipe:3.0:500,300")
        d.action_commands["use"].should eq("transition:wizard_tower:heart_wipe:3.0:500,300")
        d.default_verb.should eq(PointClickEngine::UI::VerbType::Open)
        d.object_type.should eq(PointClickEngine::UI::ObjectType::Door)
      end

      # Cleanup
      File.delete("/tmp/point_click_test/test_scene.yaml")
      Dir.delete("/tmp/point_click_test")
    end

    it "loads hotspots with various action types" do
      yaml_content = <<-YAML
      name: test_scene
      background_path: test.png
      hotspots:
        - name: npc_teleporter
          x: 200
          y: 200
          width: 64
          height: 96
          description: "A mysterious wizard"
          default_verb: talk
          object_type: character
          actions:
            look: "A wizard in flowing robes"
            talk: "transition:wizard_tower:vortex:2.0:500,300"
        - name: magic_button
          x: 300
          y: 300
          width: 50
          height: 50
          description: "A glowing button"
          default_verb: use
          object_type: device
          actions:
            look: "It pulses with magical energy"
            use: "transition:control_room:matrix_rain:3.0"
            push: "transition:control_room:matrix_rain:3.0"
      YAML

      Dir.mkdir_p("/tmp/point_click_test2")
      File.write("/tmp/point_click_test2/test_scene.yaml", yaml_content)

      scene = PointClickEngine::Scenes::SceneLoader.load_from_yaml("/tmp/point_click_test2/test_scene.yaml")

      # Debug: print loaded hotspots
      scene.hotspots.size.should eq(2)

      wizard = scene.hotspots.find { |h| h.name == "npc_teleporter" }
      wizard.should_not be_nil
      if w = wizard
        w.action_commands["talk"].should eq("transition:wizard_tower:vortex:2.0:500,300")
        w.default_verb.should eq(PointClickEngine::UI::VerbType::Talk)
      end

      button = scene.hotspots.find { |h| h.name == "magic_button" }
      button.should_not be_nil
      if b = button
        b.action_commands["use"].should eq("transition:control_room:matrix_rain:3.0")
        b.action_commands["push"].should eq("transition:control_room:matrix_rain:3.0")
        b.default_verb.should eq(PointClickEngine::UI::VerbType::Use)
      end

      # Cleanup
      File.delete("/tmp/point_click_test2/test_scene.yaml")
      Dir.delete("/tmp/point_click_test2")
    end
  end
end
