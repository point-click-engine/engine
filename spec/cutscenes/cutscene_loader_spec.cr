require "../spec_helper"

describe PointClickEngine::Cutscenes::CutsceneLoader do
  describe ".load_from_yaml" do
    it "loads a basic cutscene with wait actions" do
      yaml_content = <<-YAML
      name: "test_cutscene"
      skippable: true
      actions:
        - type: wait
          duration: 1.0
        - type: wait
          duration: 2.0
      YAML

      File.write("test_cutscene.yaml", yaml_content)
      cutscene = PointClickEngine::Cutscenes::CutsceneLoader.load_from_yaml("test_cutscene.yaml")

      cutscene.name.should eq("test_cutscene")
      cutscene.skippable.should be_true
      cutscene.actions.size.should eq(2)

      File.delete("test_cutscene.yaml")
    end

    it "loads fade actions" do
      yaml_content = <<-YAML
      name: "fade_test"
      actions:
        - type: fade_in
          duration: 1.5
          color: [0, 0, 0, 255]
        - type: fade_out
          duration: 2.0
      YAML

      File.write("fade_test.yaml", yaml_content)
      cutscene = PointClickEngine::Cutscenes::CutsceneLoader.load_from_yaml("fade_test.yaml")

      cutscene.actions.size.should eq(2)
      cutscene.actions[0].should be_a(PointClickEngine::Cutscenes::FadeAction)
      cutscene.actions[1].should be_a(PointClickEngine::Cutscenes::FadeAction)

      File.delete("fade_test.yaml")
    end

    it "loads show_text action with position string" do
      yaml_content = <<-YAML
      name: "text_test"
      actions:
        - type: show_text
          text: "Hello World"
          font_size: 32
          position: "center"
          duration: 3.0
      YAML

      File.write("text_test.yaml", yaml_content)
      cutscene = PointClickEngine::Cutscenes::CutsceneLoader.load_from_yaml("text_test.yaml")

      cutscene.actions.size.should eq(1)
      action = cutscene.actions[0]
      action.should be_a(PointClickEngine::Cutscenes::ShowTextAction)

      File.delete("text_test.yaml")
    end

    it "loads change_scene action with transition" do
      yaml_content = <<-YAML
      name: "scene_test"
      actions:
        - type: change_scene
          target: "laboratory"
          transition: "fade"
          duration: 1.5
      YAML

      File.write("scene_test.yaml", yaml_content)
      cutscene = PointClickEngine::Cutscenes::CutsceneLoader.load_from_yaml("scene_test.yaml")

      cutscene.actions.size.should eq(1)
      action = cutscene.actions[0]
      action.should be_a(PointClickEngine::Cutscenes::ChangeSceneAction)

      File.delete("scene_test.yaml")
    end

    it "loads particle_effect with position vector" do
      yaml_content = <<-YAML
      name: "particle_test"
      actions:
        - type: particle_effect
          effect: "sparkles"
          position: {x: 100, y: 200}
          intensity: 0.5
          duration: 2.0
      YAML

      File.write("particle_test.yaml", yaml_content)
      cutscene = PointClickEngine::Cutscenes::CutsceneLoader.load_from_yaml("particle_test.yaml")

      cutscene.actions.size.should eq(1)
      action = cutscene.actions[0]
      action.should be_a(PointClickEngine::Cutscenes::ParticleEffectAction)

      File.delete("particle_test.yaml")
    end

    it "loads particle_effect with fullscreen position" do
      yaml_content = <<-YAML
      name: "particle_fullscreen_test"
      actions:
        - type: particle_effect
          effect: "rain"
          position: "fullscreen"
          intensity: 0.7
      YAML

      File.write("particle_fullscreen_test.yaml", yaml_content)
      cutscene = PointClickEngine::Cutscenes::CutsceneLoader.load_from_yaml("particle_fullscreen_test.yaml")

      cutscene.actions.size.should eq(1)
      action = cutscene.actions[0]
      action.should be_a(PointClickEngine::Cutscenes::ParticleEffectAction)

      File.delete("particle_fullscreen_test.yaml")
    end

    it "loads character_enter with direction string" do
      yaml_content = <<-YAML
      name: "char_enter_test"
      actions:
        - type: character_enter
          character: "player"
          from: "left"
          to: {x: 160, y: 140}
          animation: "walk"
          duration: 2.0
      YAML

      File.write("char_enter_test.yaml", yaml_content)
      cutscene = PointClickEngine::Cutscenes::CutsceneLoader.load_from_yaml("char_enter_test.yaml")

      cutscene.actions.size.should eq(1)
      action = cutscene.actions[0]
      action.should be_a(PointClickEngine::Cutscenes::CharacterEnterAction)

      File.delete("char_enter_test.yaml")
    end

    it "loads character_enter with position vector for from" do
      yaml_content = <<-YAML
      name: "char_enter_pos_test"
      actions:
        - type: character_enter
          character: "player"
          from: {x: 50, y: 100}
          to: {x: 160, y: 140}
          duration: 2.0
      YAML

      File.write("char_enter_pos_test.yaml", yaml_content)
      cutscene = PointClickEngine::Cutscenes::CutsceneLoader.load_from_yaml("char_enter_pos_test.yaml")

      cutscene.actions.size.should eq(1)
      action = cutscene.actions[0].as(PointClickEngine::Cutscenes::CharacterEnterAction)
      action.from_position.should_not be_nil

      File.delete("char_enter_pos_test.yaml")
    end

    it "loads camera actions" do
      yaml_content = <<-YAML
      name: "camera_test"
      actions:
        - type: camera_shake
          intensity: 5.0
          duration: 0.5
        - type: camera_pan
          to: {x: 200, y: 100}
          duration: 2.0
        - type: camera_zoom
          target: 1.5
          duration: 1.0
      YAML

      File.write("camera_test.yaml", yaml_content)
      cutscene = PointClickEngine::Cutscenes::CutsceneLoader.load_from_yaml("camera_test.yaml")

      cutscene.actions.size.should eq(3)
      cutscene.actions[0].should be_a(PointClickEngine::Cutscenes::CameraShakeAction)
      cutscene.actions[1].should be_a(PointClickEngine::Cutscenes::CameraPanAction)
      cutscene.actions[2].should be_a(PointClickEngine::Cutscenes::CameraZoomAction)

      File.delete("camera_test.yaml")
    end

    it "loads UI actions" do
      yaml_content = <<-YAML
      name: "ui_test"
      actions:
        - type: hide_ui
        - type: set_letterbox
          enabled: true
          ratio: 2.35
        - type: show_ui
      YAML

      File.write("ui_test.yaml", yaml_content)
      cutscene = PointClickEngine::Cutscenes::CutsceneLoader.load_from_yaml("ui_test.yaml")

      cutscene.actions.size.should eq(3)
      cutscene.actions[0].should be_a(PointClickEngine::Cutscenes::UIVisibilityAction)
      cutscene.actions[1].should be_a(PointClickEngine::Cutscenes::LetterboxAction)
      cutscene.actions[2].should be_a(PointClickEngine::Cutscenes::UIVisibilityAction)

      File.delete("ui_test.yaml")
    end

    it "loads game state action" do
      yaml_content = <<-YAML
      name: "state_test"
      actions:
        - type: set_game_state
          flags:
            - "intro_completed"
            - "met_scientist"
          variables:
            progress: 1
            player_name: "Detective"
      YAML

      File.write("state_test.yaml", yaml_content)
      cutscene = PointClickEngine::Cutscenes::CutsceneLoader.load_from_yaml("state_test.yaml")

      cutscene.actions.size.should eq(1)
      cutscene.actions[0].should be_a(PointClickEngine::Cutscenes::SetGameStateAction)

      File.delete("state_test.yaml")
    end

    it "uses default name from filename if not specified" do
      yaml_content = <<-YAML
      actions:
        - type: wait
          duration: 1.0
      YAML

      File.write("my_cutscene.yaml", yaml_content)
      cutscene = PointClickEngine::Cutscenes::CutsceneLoader.load_from_yaml("my_cutscene.yaml")

      cutscene.name.should eq("my_cutscene")

      File.delete("my_cutscene.yaml")
    end

    it "skips unknown action types gracefully" do
      yaml_content = <<-YAML
      name: "unknown_test"
      actions:
        - type: wait
          duration: 1.0
        - type: unknown_action_type
          foo: bar
        - type: wait
          duration: 2.0
      YAML

      File.write("unknown_test.yaml", yaml_content)
      cutscene = PointClickEngine::Cutscenes::CutsceneLoader.load_from_yaml("unknown_test.yaml")

      # Should have 2 actions (unknown type is skipped)
      cutscene.actions.size.should eq(2)

      File.delete("unknown_test.yaml")
    end
  end
end
