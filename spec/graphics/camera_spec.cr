require "../spec_helper"

describe PointClickEngine::Graphics::Camera do
  describe "#initialize" do
    it "creates a camera with viewport dimensions" do
      camera = PointClickEngine::Graphics::Camera.new(800, 600)
      camera.viewport_width.should eq(800)
      camera.viewport_height.should eq(600)
      camera.position.x.should eq(0.0f32)
      camera.position.y.should eq(0.0f32)
    end

    it "initializes scene size to viewport size" do
      camera = PointClickEngine::Graphics::Camera.new(800, 600)
      camera.scene_width.should eq(800)
      camera.scene_height.should eq(600)
    end
  end

  describe "#set_scene_size" do
    it "updates scene dimensions and bounds" do
      camera = PointClickEngine::Graphics::Camera.new(800, 600)
      camera.set_scene_size(1600, 1200)

      camera.scene_width.should eq(1600)
      camera.scene_height.should eq(1200)
      camera.max_x.should eq(800.0f32) # scene_width - viewport_width
      camera.max_y.should eq(600.0f32) # scene_height - viewport_height
    end

    it "sets max bounds to 0 when scene is smaller than viewport" do
      camera = PointClickEngine::Graphics::Camera.new(800, 600)
      camera.set_scene_size(400, 300)

      camera.max_x.should eq(0.0f32)
      camera.max_y.should eq(0.0f32)
    end
  end

  describe "#screen_to_world" do
    it "converts screen coordinates to world coordinates" do
      camera = PointClickEngine::Graphics::Camera.new(800, 600)
      camera.position = RL::Vector2.new(x: 100, y: 50)

      world_pos = camera.screen_to_world(400, 300)
      world_pos.x.should eq(500.0f32) # 400 + 100
      world_pos.y.should eq(350.0f32) # 300 + 50
    end
  end

  describe "#world_to_screen" do
    it "converts world coordinates to screen coordinates" do
      camera = PointClickEngine::Graphics::Camera.new(800, 600)
      camera.position = RL::Vector2.new(x: 100, y: 50)

      screen_pos = camera.world_to_screen(500.0f32, 350.0f32)
      screen_pos.x.should eq(400.0f32) # 500 - 100
      screen_pos.y.should eq(300.0f32) # 350 - 50
    end
  end

  describe "#is_visible?" do
    it "returns true for objects within viewport" do
      camera = PointClickEngine::Graphics::Camera.new(800, 600)
      camera.position = RL::Vector2.new(x: 100, y: 100)

      camera.is_visible?(150.0f32, 150.0f32).should be_true
      camera.is_visible?(850.0f32, 650.0f32).should be_true
    end

    it "returns false for objects outside viewport" do
      camera = PointClickEngine::Graphics::Camera.new(800, 600)
      camera.position = RL::Vector2.new(x: 100, y: 100)

      camera.is_visible?(50.0f32, 50.0f32).should be_false
      camera.is_visible?(950.0f32, 750.0f32).should be_false
    end

    it "respects margin parameter" do
      camera = PointClickEngine::Graphics::Camera.new(800, 600)
      camera.position = RL::Vector2.new(x: 100, y: 100)

      camera.is_visible?(50.0f32, 150.0f32, 60.0f32).should be_true  # With margin
      camera.is_visible?(50.0f32, 150.0f32, 40.0f32).should be_false # Without enough margin
    end
  end

  describe "#center_on" do
    it "centers camera on a position" do
      camera = PointClickEngine::Graphics::Camera.new(800, 600)
      camera.set_scene_size(1600, 1200)

      camera.center_on(800.0f32, 600.0f32)
      camera.position.x.should eq(400.0f32) # 800 - 400 (half viewport)
      camera.position.y.should eq(300.0f32) # 600 - 300 (half viewport)
    end

    it "constrains to scene bounds" do
      camera = PointClickEngine::Graphics::Camera.new(800, 600)
      camera.set_scene_size(1600, 1200)

      camera.center_on(100.0f32, 100.0f32) # Near top-left
      camera.position.x.should eq(0.0f32)  # Clamped to min
      camera.position.y.should eq(0.0f32)  # Clamped to min
    end
  end

  describe "#follow" do
    it "sets target character" do
      camera = PointClickEngine::Graphics::Camera.new(800, 600)
      character = PointClickEngine::Characters::Player.new("TestChar", RL::Vector2.new(x: 0, y: 0), RL::Vector2.new(x: 32, y: 64))

      camera.follow(character)
      camera.target_character.should eq(character)
    end
  end

  describe "#update" do
    it "follows character smoothly" do
      camera = PointClickEngine::Graphics::Camera.new(800, 600)
      camera.set_scene_size(1600, 1200)

      character = PointClickEngine::Characters::Player.new("TestChar", RL::Vector2.new(x: 0, y: 0), RL::Vector2.new(x: 32, y: 64))
      character.position = RL::Vector2.new(x: 800, y: 600)

      camera.follow(character)
      camera.follow_speed = 5.0f32

      # Update for a small time step
      camera.update(0.1f32, 400, 300)

      # Camera should move towards character center
      camera.position.x.should be > 0.0f32
      camera.position.y.should be > 0.0f32
    end

    it "performs edge scrolling when enabled" do
      camera = PointClickEngine::Graphics::Camera.new(800, 600)
      camera.set_scene_size(1600, 1200)
      camera.edge_scroll_enabled = true
      camera.edge_scroll_speed = 300.0f32

      initial_x = camera.position.x

      # Mouse near left edge
      camera.update(0.1f32, 10, 300)

      # Camera should scroll left (position decreases)
      camera.position.x.should eq(0.0f32) # Clamped to min
    end

    it "does not edge scroll when disabled" do
      camera = PointClickEngine::Graphics::Camera.new(800, 600)
      camera.set_scene_size(1600, 1200)
      camera.edge_scroll_enabled = false

      initial_pos = camera.position

      # Mouse near edge
      camera.update(0.1f32, 10, 300)

      # Camera should not move
      camera.position.should eq(initial_pos)
    end
  end

  describe "#get_visible_area" do
    it "returns rectangle representing visible area" do
      camera = PointClickEngine::Graphics::Camera.new(800, 600)
      camera.position = RL::Vector2.new(x: 100, y: 200)

      area = camera.get_visible_area
      area.x.should eq(100.0f32)
      area.y.should eq(200.0f32)
      area.width.should eq(800.0f32)
      area.height.should eq(600.0f32)
    end
  end
end
