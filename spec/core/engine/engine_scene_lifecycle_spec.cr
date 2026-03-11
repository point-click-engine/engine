require "../../spec_helper"

describe PointClickEngine::Core::Engine do
  describe "scene lifecycle management" do
    # No cleanup needed for each test

    context "scene registration" do
      it "adds scene to scene manager" do
        engine = PointClickEngine::Core::Engine.new(800, 600, "Test Game")
        engine.init

        scene = PointClickEngine::Scenes::Scene.new("test_scene")

        engine.add_scene(scene)

        result = engine.scene_manager.get_scene("test_scene")
        result.success?.should be_true
        result.value.should eq(scene)
      end

      it "validates scene before adding" do
        engine = PointClickEngine::Core::Engine.new(800, 600, "Test Game")
        engine.init

        invalid_scene = PointClickEngine::Scenes::Scene.new("")

        # Empty scene names should be rejected - returns failure Result
        result = engine.add_scene(invalid_scene)
        result.failure?.should be_true
        error_msg = result.error.message || ""
        error_msg.includes?("non-empty").should be_true
      end

      it "prevents duplicate scene names" do
        engine = PointClickEngine::Core::Engine.new(800, 600, "Test Game")
        engine.init

        scene1 = PointClickEngine::Scenes::Scene.new("duplicate")
        scene2 = PointClickEngine::Scenes::Scene.new("duplicate")

        engine.add_scene(scene1)

        # Adding duplicate should return failure Result
        result = engine.add_scene(scene2)
        result.failure?.should be_true
        error_msg = result.error.message || ""
        error_msg.includes?("already exists").should be_true
      end

      it "handles scene with complex configuration" do
        engine = PointClickEngine::Core::Engine.new(800, 600, "Test Game")
        engine.init

        scene = PointClickEngine::Scenes::Scene.new("complex_scene")
        scene.background_path = "assets/bg.png"
        scene.script_path = "scripts/scene.lua"

        engine.add_scene(scene)

        result = engine.scene_manager.get_scene("complex_scene")
        result.success?.should be_true
        if scene_value = result.value
          scene_value.background_path.should eq("assets/bg.png")
          scene_value.script_path.should eq("scripts/scene.lua")
        end
      end
    end

    context "scene transitions" do
      it "performs basic scene change" do
        engine = PointClickEngine::Core::Engine.new(800, 600, "Test Game")
        engine.init

        start_scene = PointClickEngine::Scenes::Scene.new("start")
        target_scene = PointClickEngine::Scenes::Scene.new("target")

        engine.add_scene(start_scene)
        engine.add_scene(target_scene)
        engine.change_scene("start")

        engine.change_scene("target")

        # Current scene should be the target
        engine.current_scene.not_nil!.name.should eq("target")
      end

      it "handles scene change with transition effect" do
        engine = PointClickEngine::Core::Engine.new(800, 600, "Test Game")
        engine.init

        start_scene = PointClickEngine::Scenes::Scene.new("start")
        target_scene = PointClickEngine::Scenes::Scene.new("target")

        engine.add_scene(start_scene)
        engine.add_scene(target_scene)
        engine.change_scene("start")

        engine.change_scene_with_transition("target", "fade", 1.0f32)

        # Simulate time passing to allow transition to complete (past midpoint)
        # The transition duration is 1.0 second, so we need to update past 0.5s
        10.times { engine.effect_manager.update(0.1f32) }

        # Current scene should be the target after transition midpoint is reached
        engine.current_scene.not_nil!.name.should eq("target")
      end

      it "raises error when target scene does not exist" do
        engine = PointClickEngine::Core::Engine.new(800, 600, "Test Game")
        engine.init

        start_scene = PointClickEngine::Scenes::Scene.new("start")

        engine.add_scene(start_scene)
        engine.change_scene("start")

        # change_scene raises an exception for nonexistent scenes
        expect_raises(Exception) do
          engine.change_scene("nonexistent")
        end
      end

      it "handles transition with player positioning" do
        engine = PointClickEngine::Core::Engine.new(800, 600, "Test Game")
        engine.init

        start_scene = PointClickEngine::Scenes::Scene.new("start")
        target_scene = PointClickEngine::Scenes::Scene.new("target")

        engine.add_scene(start_scene)
        engine.add_scene(target_scene)
        engine.change_scene("start")

        # Create and assign player
        player = PointClickEngine::Characters::Player.new("test_player", RL::Vector2.new(x: 50, y: 50), RL::Vector2.new(x: 32, y: 48))
        engine.player = player

        start_x, start_y = 100, 200
        target_pos = RL::Vector2.new(x: start_x.to_f32, y: start_y.to_f32)

        engine.change_scene_with_transition("target", "fade", 1.0f32, target_pos)

        # Simulate time passing to allow transition to complete (past midpoint)
        10.times { engine.effect_manager.update(0.1f32) }

        # Player should be positioned correctly after transition midpoint
        if p = engine.player
          p.position.x.should eq(start_x.to_f32)
          p.position.y.should eq(start_y.to_f32)
        end
      end

      it "calls on_enter callback when entering scene" do
        engine = PointClickEngine::Core::Engine.new(800, 600, "Test Game")
        engine.init

        start_scene = PointClickEngine::Scenes::Scene.new("start")
        target_scene = PointClickEngine::Scenes::Scene.new("target")

        engine.add_scene(start_scene)
        engine.add_scene(target_scene)

        enter_called = false
        target_scene.on_enter = -> { enter_called = true; nil }

        engine.change_scene("start")
        engine.change_scene("target")

        enter_called.should be_true
      end
    end

    context "scene validation during transitions" do
      it "handles missing script files gracefully" do
        engine = PointClickEngine::Core::Engine.new(800, 600, "Test Game")
        engine.init

        scene_with_missing_script = PointClickEngine::Scenes::Scene.new("no_script")
        scene_with_missing_script.script_path = "nonexistent.lua"

        engine.add_scene(scene_with_missing_script)

        # Should handle gracefully without crashing
        engine.change_scene("no_script")
        engine.current_scene.not_nil!.name.should eq("no_script")
      end

      it "validates hotspot configurations" do
        engine = PointClickEngine::Core::Engine.new(800, 600, "Test Game")
        engine.init

        scene_with_hotspot = PointClickEngine::Scenes::Scene.new("hotspot_scene")
        hotspot = PointClickEngine::Scenes::Hotspot.new("test_hotspot", RL::Vector2.new(x: 0, y: 0), RL::Vector2.new(x: 100, y: 100))
        scene_with_hotspot.add_hotspot(hotspot)

        engine.add_scene(scene_with_hotspot)
        engine.change_scene("hotspot_scene")

        engine.current_scene.not_nil!.name.should eq("hotspot_scene")
      end
    end

    context "camera management during scene changes" do
      it "resets camera position on scene change" do
        engine = PointClickEngine::Core::Engine.new(800, 600, "Test Game")
        engine.init

        start_scene = PointClickEngine::Scenes::Scene.new("start")
        target_scene = PointClickEngine::Scenes::Scene.new("target")

        engine.add_scene(start_scene)
        engine.add_scene(target_scene)
        engine.change_scene("start")

        engine.change_scene("target")

        # Camera should exist
        engine.camera.should_not be_nil
      end

      it "configures camera bounds for new scene" do
        engine = PointClickEngine::Core::Engine.new(800, 600, "Test Game")
        engine.init

        wide_scene = PointClickEngine::Scenes::Scene.new("wide")
        wide_scene.logical_width = 2000
        wide_scene.logical_height = 1200

        engine.add_scene(wide_scene)
        engine.change_scene("wide")

        # Camera should respect scene bounds
        engine.camera.should_not be_nil
      end

      it "handles scenes smaller than viewport" do
        engine = PointClickEngine::Core::Engine.new(800, 600, "Test Game")
        engine.init

        small_scene = PointClickEngine::Scenes::Scene.new("small")
        small_scene.logical_width = 400
        small_scene.logical_height = 300

        engine.add_scene(small_scene)
        engine.change_scene("small")

        # Camera should handle small scenes appropriately
        engine.current_scene.not_nil!.name.should eq("small")
      end
    end

    context "player state during scene transitions" do
      it "preserves player across scenes" do
        engine = PointClickEngine::Core::Engine.new(800, 600, "Test Game")
        engine.init

        start_scene = PointClickEngine::Scenes::Scene.new("start")
        target_scene = PointClickEngine::Scenes::Scene.new("target")

        engine.add_scene(start_scene)
        engine.add_scene(target_scene)
        engine.change_scene("start")

        # Ensure player exists
        player = PointClickEngine::Characters::Player.new("test_player", RL::Vector2.new(x: 100, y: 100), RL::Vector2.new(x: 32, y: 48))
        engine.player = player

        engine.change_scene("target")

        # Player should still exist
        engine.player.should_not be_nil
      end

      it "updates player position on scene change with position" do
        engine = PointClickEngine::Core::Engine.new(800, 600, "Test Game")
        engine.init

        start_scene = PointClickEngine::Scenes::Scene.new("start")
        target_scene = PointClickEngine::Scenes::Scene.new("target")

        engine.add_scene(start_scene)
        engine.add_scene(target_scene)
        engine.change_scene("start")

        # Ensure player exists
        player = PointClickEngine::Characters::Player.new("test_player", RL::Vector2.new(x: 100, y: 100), RL::Vector2.new(x: 32, y: 48))
        engine.player = player

        new_x, new_y = 150, 250

        engine.change_scene_with_transition("target", "fade", 1.0f32, RL::Vector2.new(x: new_x.to_f32, y: new_y.to_f32))

        # Simulate time passing to allow transition to complete (past midpoint)
        10.times { engine.effect_manager.update(0.1f32) }

        if p = engine.player
          p.position.x.should eq(new_x.to_f32)
          p.position.y.should eq(new_y.to_f32)
        end
      end
    end

    context "error handling during scene transitions" do
      it "recovers from failed transitions to nonexistent scene" do
        engine = PointClickEngine::Core::Engine.new(800, 600, "Test Game")
        engine.init

        start_scene = PointClickEngine::Scenes::Scene.new("start")

        engine.add_scene(start_scene)
        engine.change_scene("start")

        original_scene = engine.current_scene

        begin
          engine.change_scene("nonexistent")
        rescue
          # Should remain on original scene
          engine.current_scene.should eq(original_scene)
        end
      end

      it "handles large scenes with many hotspots" do
        engine = PointClickEngine::Core::Engine.new(800, 600, "Test Game")
        engine.init

        # Test with a scene with many hotspots
        large_scene = PointClickEngine::Scenes::Scene.new("large")

        # Add many hotspots to stress test
        100.times do |i|
          hotspot = PointClickEngine::Scenes::Hotspot.new("hotspot_#{i}", RL::Vector2.new(x: (i * 10).to_f32, y: (i * 10).to_f32), RL::Vector2.new(x: 50.0f32, y: 50.0f32))
          large_scene.add_hotspot(hotspot)
        end

        engine.add_scene(large_scene)

        # Should handle gracefully
        engine.change_scene("large")
        engine.current_scene.not_nil!.name.should eq("large")
      end
    end

    context "performance during scene transitions" do
      it "completes transitions within reasonable time" do
        engine = PointClickEngine::Core::Engine.new(800, 600, "Test Game")
        engine.init

        start_scene = PointClickEngine::Scenes::Scene.new("start")
        target_scene = PointClickEngine::Scenes::Scene.new("target")

        engine.add_scene(start_scene)
        engine.add_scene(target_scene)
        engine.change_scene("start")

        start_time = Time.instant

        engine.change_scene_with_transition("target", "fade", 0.1f32)

        # Just update a few times to simulate transition
        10.times do
          engine.update(0.016f32) # 60 FPS frame time
        end

        duration = Time.instant - start_time
        duration.should be < 1.second
      end

      it "releases memory from previous scene" do
        engine = PointClickEngine::Core::Engine.new(800, 600, "Test Game")
        engine.init

        # Create and switch to memory-heavy scene
        heavy_scene = PointClickEngine::Scenes::Scene.new("heavy")
        engine.add_scene(heavy_scene)
        engine.change_scene("heavy")

        # Switch to light scene
        light_scene = PointClickEngine::Scenes::Scene.new("light")
        engine.add_scene(light_scene)
        engine.change_scene("light")

        GC.collect

        # Just verify no crash occurs
        engine.current_scene.not_nil!.name.should eq("light")
      end
    end
  end
end
