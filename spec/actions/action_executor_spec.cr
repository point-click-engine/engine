require "../spec_helper"
require "../../src/actions/action"
require "../../src/actions/action_executor"
require "../../src/actions/action_overlay_manager"

describe PointClickEngine::Actions::ActionExecutor do
  describe "#initialize" do
    it "creates with engine reference" do
      with_test_window do
        engine = PointClickEngine::Core::Engine.new(800, 600, "Test")
        executor = PointClickEngine::Actions::ActionExecutor.new(engine)
        executor.should_not be_nil
      end
    end
  end

  describe "parameter helpers" do
    it "extracts string parameters" do
      with_test_window do
        engine = PointClickEngine::Core::Engine.new(800, 600, "Test")
        executor = PointClickEngine::Actions::ActionExecutor.new(engine)

        data = PointClickEngine::Actions::ActionData.create("test",
          character: "player",
          text: "Hello"
        )
        action = PointClickEngine::Actions::ActionInstance.new(data)

        # Parameters are accessible via action.data.params
        action.data.params["character"].as_s.should eq("player")
        action.data.params["text"].as_s.should eq("Hello")
      end
    end

    it "extracts numeric parameters" do
      with_test_window do
        engine = PointClickEngine::Core::Engine.new(800, 600, "Test")
        executor = PointClickEngine::Actions::ActionExecutor.new(engine)

        data = PointClickEngine::Actions::ActionData.create("test",
          duration: 2.5,
          intensity: 5,
          enabled: true
        )
        action = PointClickEngine::Actions::ActionInstance.new(data)

        action.data.params["intensity"].as_i.should eq(5)
        action.data.params["enabled"].as_bool.should be_true
      end
    end
  end

  describe "action lifecycle" do
    it "starts wait action" do
      with_test_window do
        engine = PointClickEngine::Core::Engine.new(800, 600, "Test")
        scene = PointClickEngine::Scenes::Scene.new("test")
        executor = PointClickEngine::Actions::ActionExecutor.new(engine)

        data = PointClickEngine::Actions::ActionData.new("wait", duration: 1.0f32)
        action = PointClickEngine::Actions::ActionInstance.new(data)

        executor.start(action, scene)

        action.started.should be_true
        action.running?.should be_true
      end
    end

    it "completes wait action based on duration" do
      with_test_window do
        engine = PointClickEngine::Core::Engine.new(800, 600, "Test")
        scene = PointClickEngine::Scenes::Scene.new("test")
        executor = PointClickEngine::Actions::ActionExecutor.new(engine)

        data = PointClickEngine::Actions::ActionData.new("wait", duration: 0.1f32)
        action = PointClickEngine::Actions::ActionInstance.new(data)

        executor.start(action, scene)

        # Simulate time passing
        completed = executor.update(action, scene, 0.05f32)
        completed.should be_false

        completed = executor.update(action, scene, 0.1f32)
        completed.should be_true
      end
    end

    it "instant actions complete immediately" do
      with_test_window do
        engine = PointClickEngine::Core::Engine.new(800, 600, "Test")
        scene = PointClickEngine::Scenes::Scene.new("test")
        executor = PointClickEngine::Actions::ActionExecutor.new(engine)

        data = PointClickEngine::Actions::ActionData.new("hide_ui")
        action = PointClickEngine::Actions::ActionInstance.new(data)

        executor.start(action, scene)
        completed = executor.update(action, scene, 0.016f32)

        completed.should be_true
      end
    end
  end

  describe "UI actions" do
    it "hides UI" do
      with_test_window do
        engine = PointClickEngine::Core::Engine.new(800, 600, "Test")
        scene = PointClickEngine::Scenes::Scene.new("test")
        executor = PointClickEngine::Actions::ActionExecutor.new(engine)

        engine.render_manager.show_ui
        engine.render_manager.ui_visible?.should be_true

        data = PointClickEngine::Actions::ActionData.new("hide_ui")
        action = PointClickEngine::Actions::ActionInstance.new(data)

        executor.start(action, scene)

        engine.render_manager.ui_visible?.should be_false
      end
    end

    it "shows UI" do
      with_test_window do
        engine = PointClickEngine::Core::Engine.new(800, 600, "Test")
        scene = PointClickEngine::Scenes::Scene.new("test")
        executor = PointClickEngine::Actions::ActionExecutor.new(engine)

        engine.render_manager.hide_ui

        data = PointClickEngine::Actions::ActionData.new("show_ui")
        action = PointClickEngine::Actions::ActionInstance.new(data)

        executor.start(action, scene)

        engine.render_manager.ui_visible?.should be_true
      end
    end
  end

  describe "player control actions" do
    it "disables player control" do
      with_test_window do
        engine = PointClickEngine::Core::Engine.new(800, 600, "Test")
        scene = PointClickEngine::Scenes::Scene.new("test")
        executor = PointClickEngine::Actions::ActionExecutor.new(engine)

        engine.player_control_enabled = true

        data = PointClickEngine::Actions::ActionData.new("disable_player_control")
        action = PointClickEngine::Actions::ActionInstance.new(data)

        executor.start(action, scene)

        engine.player_control_enabled.should be_false
      end
    end

    it "enables player control" do
      with_test_window do
        engine = PointClickEngine::Core::Engine.new(800, 600, "Test")
        scene = PointClickEngine::Scenes::Scene.new("test")
        executor = PointClickEngine::Actions::ActionExecutor.new(engine)

        engine.player_control_enabled = false

        data = PointClickEngine::Actions::ActionData.new("enable_player_control")
        action = PointClickEngine::Actions::ActionInstance.new(data)

        executor.start(action, scene)

        engine.player_control_enabled.should be_true
      end
    end
  end

  describe "show_text action" do
    it "stores text parameters in custom data" do
      with_test_window do
        engine = PointClickEngine::Core::Engine.new(800, 600, "Test")
        scene = PointClickEngine::Scenes::Scene.new("test")
        executor = PointClickEngine::Actions::ActionExecutor.new(engine)

        data = PointClickEngine::Actions::ActionData.create("show_text",
          duration: 3.0f32,
          text: "Hello World!",
          font_size: 32,
          position: "center"
        )
        action = PointClickEngine::Actions::ActionInstance.new(data)

        executor.start(action, scene)

        action.get_custom("text").not_nil!.as_s.should eq("Hello World!")
        action.get_custom("font_size").not_nil!.as_i.should eq(32)
        action.get_custom("position").not_nil!.as_s.should eq("center")
      end
    end

    it "preserves intro text position aliases" do
      with_test_window do
        engine = PointClickEngine::Core::Engine.new(800, 600, "Test")
        scene = PointClickEngine::Scenes::Scene.new("test")
        executor = PointClickEngine::Actions::ActionExecutor.new(engine)

        top_data = PointClickEngine::Actions::ActionData.create("show_text",
          duration: 2.0f32,
          text: "Top",
          position: "center_top"
        )
        bottom_data = PointClickEngine::Actions::ActionData.create("show_text",
          duration: 2.0f32,
          text: "Bottom",
          position: "center_bottom"
        )

        top_action = PointClickEngine::Actions::ActionInstance.new(top_data)
        bottom_action = PointClickEngine::Actions::ActionInstance.new(bottom_data)

        executor.start(top_action, scene)
        executor.start(bottom_action, scene)

        top_action.get_custom("position").not_nil!.as_s.should eq("center_top")
        bottom_action.get_custom("position").not_nil!.as_s.should eq("center_bottom")
      end
    end
  end

  describe "camera actions" do
    it "accepts target_zoom as an alias for zoom target" do
      with_test_window do
        engine = PointClickEngine::Core::Engine.new(800, 600, "Test")
        scene = PointClickEngine::Scenes::Scene.new("test")
        executor = PointClickEngine::Actions::ActionExecutor.new(engine)

        data = PointClickEngine::Actions::ActionData.create("camera_zoom",
          duration: 1.0f32,
          target_zoom: 1.5
        )
        action = PointClickEngine::Actions::ActionInstance.new(data)

        executor.start(action, scene)

        engine.effect_manager.stats[:camera_effects].should eq(1)
      end
    end
  end

  describe "timed control actions" do
    it "waits for return_to_menu delay before completing" do
      with_test_window do
        engine = PointClickEngine::Core::Engine.new(800, 600, "Test")
        scene = PointClickEngine::Scenes::Scene.new("test")
        executor = PointClickEngine::Actions::ActionExecutor.new(engine)

        data = PointClickEngine::Actions::ActionData.create("return_to_menu", delay: 1.0)
        action = PointClickEngine::Actions::ActionInstance.new(data)

        executor.start(action, scene)
        executor.update(action, scene, 0.5f32).should be_false
        executor.update(action, scene, 0.6f32).should be_true
      end
    end
  end

  describe "scene actions" do
    it "uses a default duration for change_scene when none is provided" do
      with_test_window do
        engine = PointClickEngine::Core::Engine.new(800, 600, "Test")
        engine.init
        executor = PointClickEngine::Actions::ActionExecutor.new(engine)

        start_scene = PointClickEngine::Scenes::Scene.new("start")
        target_scene = PointClickEngine::Scenes::Scene.new("target")
        start_scene.default_transition_duration = 0.2f32

        engine.add_scene(start_scene)
        engine.add_scene(target_scene)
        engine.change_scene("start")

        action = PointClickEngine::Actions::ActionInstance.new(
          PointClickEngine::Actions::ActionData.create("change_scene", target: "target")
        )

        executor.start(action, start_scene)

        20.times do
          engine.update(0.016f32)
        end

        engine.current_scene.not_nil!.name.should eq("target")
      end
    end
  end

  describe PointClickEngine::Actions::ActionOverlayManager do
    it "resolves sprites by basename or stem" do
      manager = PointClickEngine::Actions::ActionOverlayManager.new
      manager.add_sprite("assets/items/crystal.png", Raylib::Vector2.new(x: 0, y: 0))

      manager.has_sprite?("crystal").should be_true
      manager.has_sprite?("crystal.png").should be_true

      manager.remove_sprite("crystal")
      manager.has_sprite?("assets/items/crystal.png").should be_false
    end

    it "maps cinematic canvas coordinates to the current screen" do
      manager = PointClickEngine::Actions::ActionOverlayManager.new
      manager.set_canvas(320, 180)

      position = manager.render_position_for(Raylib::Vector2.new(x: 160, y: 90), 1024, 768)
      scale = manager.render_scale_for(2.0f32, 1024, 768)

      position.x.should be_close(512.0f32, 0.01f32)
      position.y.should be_close(384.0f32, 0.01f32)
      scale.should be_close(6.4f32, 0.01f32)
    end

    it "supports fade-out removal without deleting the sprite immediately" do
      manager = PointClickEngine::Actions::ActionOverlayManager.new
      manager.add_sprite("assets/items/crystal.png", Raylib::Vector2.new(x: 0, y: 0))

      manager.remove_sprite("crystal", 0.5f32)
      manager.has_sprite?("crystal").should be_true

      manager.update(0.25f32)
      manager.has_sprite?("crystal").should be_true

      manager.update(0.3f32)
      manager.has_sprite?("crystal").should be_false
    end
  end

  describe "callback action" do
    it "executes callback on start" do
      with_test_window do
        engine = PointClickEngine::Core::Engine.new(800, 600, "Test")
        scene = PointClickEngine::Scenes::Scene.new("test")
        executor = PointClickEngine::Actions::ActionExecutor.new(engine)

        called = false
        callback = -> { called = true; nil }

        data = PointClickEngine::Actions::ActionData.new("callback")
        action = PointClickEngine::Actions::ActionInstance.new(data, callback)

        executor.start(action, scene)

        called.should be_true
      end
    end
  end
end
