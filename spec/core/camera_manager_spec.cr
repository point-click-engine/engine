require "../spec_helper"

describe PointClickEngine::Core::CameraManager do
  describe "#initialize" do
    it "creates a camera manager with viewport dimensions" do
      manager = PointClickEngine::Core::CameraManager.new(800, 600)
      manager.viewport_width.should eq(800)
      manager.viewport_height.should eq(600)
      manager.current_camera.should_not be_nil
    end

    it "sets main camera as active by default" do
      manager = PointClickEngine::Core::CameraManager.new(800, 600)
      manager.active_camera_name.should eq("main")
      manager.current_camera.should eq(manager.get_camera("main"))
    end
  end

  describe "#add_camera" do
    it "adds a new camera with unique name" do
      manager = PointClickEngine::Core::CameraManager.new(800, 600)
      cutscene_camera = PointClickEngine::Graphics::Camera.new(800, 600)

      result = manager.add_camera("cutscene", cutscene_camera)
      result.success?.should be_true
      manager.get_camera("cutscene").should eq(cutscene_camera)
    end

    it "fails when adding camera with duplicate name" do
      manager = PointClickEngine::Core::CameraManager.new(800, 600)
      camera = PointClickEngine::Graphics::Camera.new(800, 600)

      manager.add_camera("test", camera)
      result = manager.add_camera("test", camera)
      result.failure?.should be_true
    end
  end

  describe "#switch_camera" do
    it "switches to a different camera" do
      manager = PointClickEngine::Core::CameraManager.new(800, 600)
      cutscene_camera = PointClickEngine::Graphics::Camera.new(800, 600)
      manager.add_camera("cutscene", cutscene_camera)

      result = manager.switch_camera("cutscene")
      result.success?.should be_true
      manager.active_camera_name.should eq("cutscene")
      manager.current_camera.should eq(cutscene_camera)
    end

    it "fails when switching to non-existent camera" do
      manager = PointClickEngine::Core::CameraManager.new(800, 600)

      result = manager.switch_camera("non_existent")
      result.failure?.should be_true
    end

    it "supports smooth transitions between cameras" do
      manager = PointClickEngine::Core::CameraManager.new(800, 600)
      camera2 = PointClickEngine::Graphics::Camera.new(800, 600)
      camera2.position = RL::Vector2.new(x: 100, y: 100)
      manager.add_camera("camera2", camera2)

      manager.switch_camera("camera2", transition_duration: 1.0f32)
      manager.is_transitioning?.should be_true

      # Simulate partial transition
      manager.update(0.5f32, 0, 0)

      # Position should be interpolated (or transition should be in progress)
      if manager.is_transitioning?
        # During transition, check that we're making progress
        manager.transition_elapsed.should be > 0
      else
        # If transition completed, check final position
        manager.current_camera.position.x.should be > 0
        manager.current_camera.position.x.should be < 100
      end
    end
  end

  describe "#apply_effect" do
    context "shake effect" do
      it "applies screen shake effect" do
        manager = PointClickEngine::Core::CameraManager.new(800, 600)

        manager.apply_effect(:shake, intensity: 10.0f32, duration: 1.0f32)
        manager.active_effects.size.should eq(1)
        manager.has_effect?(:shake).should be_true
      end

      it "stacks multiple shake effects" do
        manager = PointClickEngine::Core::CameraManager.new(800, 600)

        manager.apply_effect(:shake, intensity: 10.0f32, duration: 1.0f32)
        manager.apply_effect(:shake, intensity: 5.0f32, duration: 0.5f32)

        shake_effects = manager.active_effects.select { |e| e.type == PointClickEngine::Core::CameraEffectType::Shake }
        shake_effects.size.should eq(2)
      end
    end

    context "zoom effect" do
      it "applies zoom effect" do
        manager = PointClickEngine::Core::CameraManager.new(800, 600)

        manager.apply_effect(:zoom, target: 2.0f32, duration: 1.0f32)
        manager.has_effect?(:zoom).should be_true
      end

      it "only allows one zoom effect at a time" do
        manager = PointClickEngine::Core::CameraManager.new(800, 600)

        manager.apply_effect(:zoom, target: 2.0f32, duration: 1.0f32)
        manager.apply_effect(:zoom, target: 0.5f32, duration: 0.5f32)

        zoom_effects = manager.active_effects.select { |e| e.type == PointClickEngine::Core::CameraEffectType::Zoom }
        zoom_effects.size.should eq(1)
        # Should have the latest zoom
        zoom_effects.first.parameters["target"].as(Float32).should eq(0.5f32)
      end
    end

    context "sway effect" do
      it "applies sea-like sway effect" do
        manager = PointClickEngine::Core::CameraManager.new(800, 600)

        manager.apply_effect(:sway, amplitude: 20.0f32, frequency: 0.5f32, duration: 5.0f32)
        manager.has_effect?(:sway).should be_true
      end
    end

    context "follow effect" do
      it "follows a character" do
        manager = PointClickEngine::Core::CameraManager.new(800, 600)
        character = PointClickEngine::Characters::Player.new("TestChar", RL::Vector2.new(x: 0, y: 0), RL::Vector2.new(x: 32, y: 64))

        manager.apply_effect(:follow, target: character, smooth: true, deadzone: 50.0f32)
        manager.has_effect?(:follow).should be_true
      end

      it "only allows one follow effect at a time" do
        manager = PointClickEngine::Core::CameraManager.new(800, 600)
        char1 = PointClickEngine::Characters::Player.new("Char1", RL::Vector2.new(x: 0, y: 0), RL::Vector2.new(x: 32, y: 64))
        char2 = PointClickEngine::Characters::Player.new("Char2", RL::Vector2.new(x: 0, y: 0), RL::Vector2.new(x: 32, y: 64))

        manager.apply_effect(:follow, target: char1)
        manager.apply_effect(:follow, target: char2)

        follow_effects = manager.active_effects.select { |e| e.type == PointClickEngine::Core::CameraEffectType::Follow }
        follow_effects.size.should eq(1)
        follow_effects.first.parameters["target"].as(PointClickEngine::Characters::Character).should eq(char2)
      end
    end

    context "pan effect" do
      it "pans to a position" do
        manager = PointClickEngine::Core::CameraManager.new(800, 600)

        manager.apply_effect(:pan, target_x: 500.0f32, target_y: 300.0f32, duration: 2.0f32)
        manager.has_effect?(:pan).should be_true
      end
    end
  end

  describe "#reset_effects" do
    it "removes all active effects except zoom transition" do
      manager = PointClickEngine::Core::CameraManager.new(800, 600)

      # Add multiple effects
      manager.apply_effect(:shake, intensity: 10.0f32, duration: 1.0f32)
      manager.apply_effect(:zoom, factor: 2.0f32, duration: 1.0f32)
      manager.apply_effect(:sway, amplitude: 5.0f32, frequency: 1.0f32, duration: 2.0f32)

      manager.active_effects.size.should eq(3)

      # Reset all effects
      manager.reset_effects(0.5f32)

      # Should only have zoom transition back to 1.0
      manager.active_effects.size.should eq(1)
      zoom_effect = manager.active_effects.first
      zoom_effect.type.should eq(PointClickEngine::Core::CameraEffectType::Zoom)
    end

    it "smoothly transitions zoom back to 1.0 when zoom effect was active" do
      manager = PointClickEngine::Core::CameraManager.new(800, 600)

      # Apply zoom effect
      manager.apply_effect(:zoom, factor: 2.0f32, duration: 0.1f32)

      # Update to apply the zoom
      manager.update(0.05f32, 0, 0)

      # Zoom should be partially applied
      manager.total_zoom.should_not eq(1.0f32)

      # Now reset with smooth transition
      manager.reset_effects(1.0f32)

      # Should have a zoom effect transitioning back to 1.0
      zoom_effects = manager.active_effects.select { |e| e.type == PointClickEngine::Core::CameraEffectType::Zoom }
      zoom_effects.size.should eq(1)
      zoom_effect = zoom_effects.first
      zoom_effect.parameters["factor"]?.should eq(1.0f32)
    end
  end

  describe "#remove_effect" do
    it "removes specific effect type" do
      manager = PointClickEngine::Core::CameraManager.new(800, 600)

      manager.apply_effect(:shake, intensity: 10.0f32, duration: 1.0f32)
      manager.apply_effect(:zoom, target: 2.0f32, duration: 1.0f32)

      manager.remove_effect(:shake)
      manager.has_effect?(:shake).should be_false
      manager.has_effect?(:zoom).should be_true
    end

    it "removes all effects" do
      manager = PointClickEngine::Core::CameraManager.new(800, 600)

      manager.apply_effect(:shake, intensity: 10.0f32, duration: 1.0f32)
      manager.apply_effect(:zoom, target: 2.0f32, duration: 1.0f32)

      manager.remove_all_effects
      manager.active_effects.empty?.should be_true
    end
  end

  describe "#update" do
    it "updates active effects" do
      manager = PointClickEngine::Core::CameraManager.new(800, 600)

      manager.apply_effect(:shake, intensity: 10.0f32, duration: 0.5f32)
      initial_effects = manager.active_effects.size

      # Update past duration
      manager.update(1.0f32, 0, 0)

      # Effect should be removed after duration
      manager.active_effects.size.should eq(0)
    end

    it "combines multiple effects" do
      manager = PointClickEngine::Core::CameraManager.new(800, 600)
      manager.set_scene_bounds(1600, 1200)

      # Manually move camera to test effects
      manager.current_camera.position = RL::Vector2.new(x: 50, y: 50)

      # Apply shake which should modify the effect offset
      manager.apply_effect(:shake, intensity: 10.0f32, duration: 1.0f32)

      # Also apply zoom
      manager.current_camera.zoom = 1.5f32

      manager.update(0.1f32, 0, 0)

      # Should have active shake effect
      manager.has_effect?(:shake).should be_true
      manager.total_zoom.should eq(1.5f32)
    end

    it "respects scene bounds during effects" do
      manager = PointClickEngine::Core::CameraManager.new(800, 600)
      manager.set_scene_bounds(800, 600) # Same as viewport

      # Try to pan outside bounds
      manager.apply_effect(:pan, target_x: 1000.0f32, target_y: 1000.0f32, duration: 0.1f32)

      manager.update(0.2f32, 0, 0) # Complete the pan

      # Should be constrained to bounds
      manager.current_camera.position.x.should eq(0)
      manager.current_camera.position.y.should eq(0)
    end

    it "returns camera to base position after shake effect ends" do
      manager = PointClickEngine::Core::CameraManager.new(800, 600)
      manager.set_scene_bounds(1600, 1200)

      # Set initial camera position and disable edge scrolling
      initial_x = 100.0f32
      initial_y = 50.0f32
      manager.current_camera.position = RL::Vector2.new(x: initial_x, y: initial_y)
      manager.current_camera.edge_scroll_enabled = false

      # Update once to establish base position
      manager.update(0.01f32, 400, 300)

      # Apply short shake effect
      manager.apply_effect(:shake, intensity: 20.0f32, duration: 0.1f32)

      # Update a few times during shake
      manager.update(0.05f32, 400, 300)

      # Position should be offset during shake (but we won't check exact values due to randomness)
      manager.has_effect?(:shake).should be_true

      # Complete the shake and then some to ensure it's fully done
      manager.update(0.1f32, 400, 300)

      # Camera should return to initial position (within floating point tolerance)
      manager.current_camera.position.x.should be_close(initial_x, 0.1)
      manager.current_camera.position.y.should be_close(initial_y, 0.1)
      manager.active_effects.size.should eq(0)
    end
  end

  describe "#transform_position" do
    it "applies camera transformations to world coordinates" do
      manager = PointClickEngine::Core::CameraManager.new(800, 600)
      manager.current_camera.position = RL::Vector2.new(x: 100, y: 50)

      world_pos = RL::Vector2.new(x: 500, y: 300)
      screen_pos = manager.transform_position(world_pos)

      screen_pos.x.should eq(400) # 500 - 100
      screen_pos.y.should eq(250) # 300 - 50
    end

    it "applies zoom transformation" do
      manager = PointClickEngine::Core::CameraManager.new(800, 600)

      # Directly set the zoom on the camera for testing coordinate transformation
      manager.current_camera.zoom = 2.0f32

      # Check that zoom is applied
      manager.total_zoom.should eq(2.0f32)

      # Test a point at world coordinates (200, 150)
      world_pos = RL::Vector2.new(x: 200, y: 150)
      screen_pos = manager.transform_position(world_pos)

      # With 2x zoom and camera at (0,0):
      # screen_x = 200 - 0 = 200
      # Center is at (400, 300)
      # Zoomed: 400 + (200 - 400) * 2 = 400 + (-200) * 2 = 400 - 400 = 0
      screen_pos.x.should eq(0)

      # screen_y = 150 - 0 = 150
      # Zoomed: 300 + (150 - 300) * 2 = 300 + (-150) * 2 = 300 - 300 = 0
      screen_pos.y.should eq(0)
    end
  end

  describe "#set_scene_bounds" do
    it "updates bounds for all cameras" do
      manager = PointClickEngine::Core::CameraManager.new(800, 600)
      camera2 = PointClickEngine::Graphics::Camera.new(800, 600)
      manager.add_camera("camera2", camera2)

      manager.set_scene_bounds(1600, 1200)

      manager.get_camera("main").not_nil!.scene_width.should eq(1600)
      manager.get_camera("main").not_nil!.scene_height.should eq(1200)
      manager.get_camera("camera2").not_nil!.scene_width.should eq(1600)
      manager.get_camera("camera2").not_nil!.scene_height.should eq(1200)
    end
  end

  describe "#screen_to_world" do
    it "converts screen coordinates to world coordinates" do
      manager = PointClickEngine::Core::CameraManager.new(800, 600)
      manager.current_camera.position = RL::Vector2.new(x: 100, y: 50)

      screen_pos = RL::Vector2.new(x: 400, y: 300)
      world_pos = manager.screen_to_world(screen_pos)

      world_pos.x.should eq(500) # 400 + 100
      world_pos.y.should eq(350) # 300 + 50
    end
  end

  describe "#is_visible?" do
    it "checks if world position is visible" do
      manager = PointClickEngine::Core::CameraManager.new(800, 600)
      manager.current_camera.position = RL::Vector2.new(x: 100, y: 100)

      manager.is_visible?(RL::Vector2.new(x: 150, y: 150)).should be_true
      manager.is_visible?(RL::Vector2.new(x: 50, y: 50)).should be_false
    end
  end

  describe "#center_on" do
    it "centers camera on a position" do
      manager = PointClickEngine::Core::CameraManager.new(800, 600)
      manager.set_scene_bounds(1600, 1200)

      manager.center_on(800.0f32, 600.0f32)

      # Camera should be centered (position is top-left)
      manager.current_camera.position.x.should eq(400) # 800 - 400 (half viewport)
      manager.current_camera.position.y.should eq(300) # 600 - 300 (half viewport)
    end
  end

  describe "#get_visible_area" do
    it "returns the visible rectangle in world coordinates" do
      manager = PointClickEngine::Core::CameraManager.new(800, 600)
      manager.current_camera.position = RL::Vector2.new(x: 100, y: 200)

      area = manager.get_visible_area
      area.x.should eq(100)
      area.y.should eq(200)
      area.width.should eq(800)
      area.height.should eq(600)
    end
  end

  describe "effect persistence" do
    it "saves and restores camera state" do
      manager = PointClickEngine::Core::CameraManager.new(800, 600)

      # Set up camera state directly
      manager.current_camera.position = RL::Vector2.new(x: 100, y: 200)
      manager.current_camera.zoom = 1.5f32

      # Save state
      state = manager.save_state

      # Modify camera
      manager.current_camera.position = RL::Vector2.new(x: 0, y: 0)
      manager.remove_all_effects

      # Restore state
      manager.restore_state(state)

      manager.current_camera.position.x.should eq(100)
      manager.current_camera.position.y.should eq(200)
    end
  end
end
