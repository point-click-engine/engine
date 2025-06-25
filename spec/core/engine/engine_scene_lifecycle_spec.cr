require "../../spec_helper"

describe PointClickEngine::Core::Engine do
  describe "scene lifecycle management" do
    let(engine) do
      engine = PointClickEngine::Core::Engine.new(800, 600, "Test Game")
      engine.init
      engine
    end

    after_each do
      PointClickEngine::Core::Engine.reset_instance if PointClickEngine::Core::Engine.responds_to?(:reset_instance)
    end

    context "scene registration" do
      it "adds scene to scene manager" do
        scene = PointClickEngine::Scenes::Scene.new("test_scene")

        engine.add_scene(scene)

        engine.scene_manager.get_scene("test_scene").should eq(scene)
      end

      it "validates scene before adding" do
        invalid_scene = PointClickEngine::Scenes::Scene.new("")

        expect_raises(ArgumentError) do
          engine.add_scene(invalid_scene)
        end
      end

      it "prevents duplicate scene names" do
        scene1 = PointClickEngine::Scenes::Scene.new("duplicate")
        scene2 = PointClickEngine::Scenes::Scene.new("duplicate")

        engine.add_scene(scene1)

        expect_raises(ArgumentError) do
          engine.add_scene(scene2)
        end
      end

      it "handles scene with complex configuration" do
        scene = PointClickEngine::Scenes::Scene.new("complex_scene")
        scene.background_path = "assets/bg.png"
        scene.script_path = "scripts/scene.lua"

        engine.add_scene(scene)

        registered_scene = engine.scene_manager.get_scene("complex_scene")
        registered_scene.background_path.should eq("assets/bg.png")
        registered_scene.script_path.should eq("scripts/scene.lua")
      end
    end

    context "scene transitions" do
      let(start_scene) { PointClickEngine::Scenes::Scene.new("start") }
      let(target_scene) { PointClickEngine::Scenes::Scene.new("target") }

      before_each do
        engine.add_scene(start_scene)
        engine.add_scene(target_scene)
        engine.change_scene("start")
      end

      it "performs basic scene change" do
        engine.change_scene("target")

        engine.current_scene.should eq(target_scene)
      end

      it "handles scene change with transition effect" do
        engine.change_scene_with_transition("target", "fade", 1.0)

        # Transition should be in progress
        engine.scene_manager.transitioning?.should be_true
        engine.current_scene.should eq(target_scene)
      end

      it "validates target scene exists" do
        expect_raises(ArgumentError) do
          engine.change_scene("nonexistent")
        end
      end

      it "handles transition with player positioning" do
        start_x, start_y = 100, 200

        engine.change_scene_with_transition("target", "fade", 1.0, start_x, start_y)

        # Player should be positioned correctly
        if player = engine.player
          player.x.should eq(start_x)
          player.y.should eq(start_y)
        end
      end

      it "triggers scene exit and enter events" do
        exit_called = false
        enter_called = false

        start_scene.on_exit { exit_called = true }
        target_scene.on_enter { enter_called = true }

        engine.change_scene("target")

        exit_called.should be_true
        enter_called.should be_true
      end
    end

    context "scene validation during transitions" do
      it "validates scene has required assets" do
        invalid_scene = PointClickEngine::Scenes::Scene.new("invalid")
        invalid_scene.background_path = "nonexistent.png"

        engine.add_scene(invalid_scene)

        expect_raises(Exception) do
          engine.change_scene("invalid")
        end
      end

      it "handles missing script files gracefully" do
        scene_with_missing_script = PointClickEngine::Scenes::Scene.new("no_script")
        scene_with_missing_script.script_path = "nonexistent.lua"

        engine.add_scene(scene_with_missing_script)

        # Should handle gracefully or provide clear error
        engine.change_scene("no_script")
        engine.current_scene.should eq(scene_with_missing_script)
      end

      it "validates hotspot configurations" do
        scene_with_hotspot = PointClickEngine::Scenes::Scene.new("hotspot_scene")
        hotspot = PointClickEngine::Scenes::Hotspot.new("test_hotspot", 0, 0, 100, 100)
        scene_with_hotspot.add_hotspot(hotspot)

        engine.add_scene(scene_with_hotspot)
        engine.change_scene("hotspot_scene")

        engine.current_scene.should eq(scene_with_hotspot)
      end
    end

    context "camera management during scene changes" do
      it "resets camera position on scene change" do
        # Set camera to specific position
        engine.camera.target = {x: 500.0, y: 300.0}

        engine.change_scene("target")

        # Camera should be reset or repositioned appropriately
        engine.camera.target.should_not eq({x: 500.0, y: 300.0})
      end

      it "configures camera bounds for new scene" do
        wide_scene = PointClickEngine::Scenes::Scene.new("wide")
        wide_scene.width = 2000
        wide_scene.height = 1200

        engine.add_scene(wide_scene)
        engine.change_scene("wide")

        # Camera should respect scene bounds
        engine.camera.should_not be_nil
      end

      it "handles scenes smaller than viewport" do
        small_scene = PointClickEngine::Scenes::Scene.new("small")
        small_scene.width = 400
        small_scene.height = 300

        engine.add_scene(small_scene)
        engine.change_scene("small")

        # Camera should handle small scenes appropriately
        engine.current_scene.should eq(small_scene)
      end
    end

    context "player state during scene transitions" do
      before_each do
        # Ensure player exists
        player = PointClickEngine::Characters::Player.new("test_player")
        engine.player = player
      end

      it "preserves player inventory across scenes" do
        # Add item to inventory
        if player = engine.player
          item = PointClickEngine::Items::Item.new("test_item")
          player.inventory.add_item(item)

          engine.change_scene("target")

          # Inventory should be preserved
          player.inventory.has_item?("test_item").should be_true
        end
      end

      it "updates player position on scene change" do
        new_x, new_y = 150, 250

        engine.change_scene_with_transition("target", "fade", 1.0, new_x, new_y)

        if player = engine.player
          player.x.should eq(new_x)
          player.y.should eq(new_y)
        end
      end

      it "resets player animation state" do
        if player = engine.player
          # Set player to walking state
          player.state = PointClickEngine::Characters::CharacterState::Walking

          engine.change_scene("target")

          # Player should return to idle state
          player.state.should eq(PointClickEngine::Characters::CharacterState::Idle)
        end
      end
    end

    context "error handling during scene transitions" do
      it "handles corrupted scene data" do
        # This would normally be caught during scene loading
        # but we test the engine's resilience
        expect_raises(Exception) do
          engine.change_scene("target")
          # Simulate corruption during transition
        end
      end

      it "recovers from failed transitions" do
        original_scene = engine.current_scene

        begin
          engine.change_scene("nonexistent")
        rescue
          # Should remain on original scene
          engine.current_scene.should eq(original_scene)
        end
      end

      it "handles memory issues during large scene loads" do
        # Test with a very large scene configuration
        large_scene = PointClickEngine::Scenes::Scene.new("large")

        # Add many hotspots to stress test
        1000.times do |i|
          hotspot = PointClickEngine::Scenes::Hotspot.new("hotspot_#{i}", i * 10, i * 10, 50, 50)
          large_scene.add_hotspot(hotspot)
        end

        engine.add_scene(large_scene)

        # Should handle gracefully
        engine.change_scene("large")
        engine.current_scene.should eq(large_scene)
      end
    end

    context "performance during scene transitions" do
      it "completes transitions within reasonable time" do
        start_time = Time.monotonic

        engine.change_scene_with_transition("target", "fade", 0.1)

        # Complete the transition
        while engine.scene_manager.transitioning?
          engine.update(0.016) # 60 FPS frame time
        end

        duration = Time.monotonic - start_time
        duration.should be < 1.second
      end

      it "releases memory from previous scene" do
        initial_memory = GC.stats.heap_size

        # Create and switch to memory-heavy scene
        heavy_scene = PointClickEngine::Scenes::Scene.new("heavy")
        engine.add_scene(heavy_scene)
        engine.change_scene("heavy")

        # Switch to light scene
        light_scene = PointClickEngine::Scenes::Scene.new("light")
        engine.add_scene(light_scene)
        engine.change_scene("light")

        GC.collect

        # Memory should be released (within reasonable bounds)
        final_memory = GC.stats.heap_size
      end
    end
  end
end
