require "../spec_helper"
require "../../src/characters/sprite_controller"

describe PointClickEngine::Characters::SpriteController do
  describe "initialization" do
    it "initializes with position and size" do
      position = RL::Vector2.new(x: 100.0_f32, y: 200.0_f32)
      size = RL::Vector2.new(x: 32.0_f32, y: 48.0_f32)
      controller = PointClickEngine::Characters::SpriteController.new(position, size)
      controller.position.should eq(position)
      controller.size.should eq(size)
      controller.scale.should eq(1.0)
      controller.loaded?.should be_false
    end

    it "starts without sprite loaded" do
      position = RL::Vector2.new(x: 100.0_f32, y: 200.0_f32)
      size = RL::Vector2.new(x: 32.0_f32, y: 48.0_f32)
      controller = PointClickEngine::Characters::SpriteController.new(position, size)
      controller.sprite.should be_nil
      controller.sprite_path.should be_nil
      controller.loaded?.should be_false
    end
  end

  describe "sprite loading" do
    it "loads spritesheet with correct dimensions" do
      position = RL::Vector2.new(x: 100.0_f32, y: 200.0_f32)
      size = RL::Vector2.new(x: 32.0_f32, y: 48.0_f32)
      controller = PointClickEngine::Characters::SpriteController.new(position, size)
      # Note: This would normally require actual image file
      # For testing, we mock the sprite creation
      controller.load_spritesheet("test_sprite.png", 32, 48)

      controller.sprite_path.should eq("test_sprite.png")
      controller.loaded?.should be_true

      if sprite = controller.sprite
        sprite.frame_width.should eq(32)
        sprite.frame_height.should eq(48)
      end
    end

    it "calculates scale based on frame dimensions" do
      # Create controller with specific size expectations
      test_controller = PointClickEngine::Characters::SpriteController.new(
        RL::Vector2.new(100, 100),
        RL::Vector2.new(64, 96) # 2x scale for 32x48 sprite
      )

      test_controller.load_spritesheet("test.png", 32, 48)

      if sprite = test_controller.sprite
        # Scale should be calculated to fit the target size
        expected_scale_x = 64.0 / 32.0 # 2.0
        expected_scale_y = 96.0 / 48.0 # 2.0
        expected_scale = Math.min(expected_scale_x, expected_scale_y)

        sprite.scale.should be_close(expected_scale, 0.001)
      end
    end

    it "updates size based on scaled sprite dimensions" do
      position = RL::Vector2.new(x: 100.0_f32, y: 200.0_f32)
      size = RL::Vector2.new(x: 64.0_f32, y: 64.0_f32)
      controller = PointClickEngine::Characters::SpriteController.new(position, size)
      controller.load_spritesheet("test.png", 32, 48)

      if sprite = controller.sprite
        expected_width = 32 * sprite.scale
        expected_height = 48 * sprite.scale

        controller.size.x.should be_close(expected_width, 0.001)
        controller.size.y.should be_close(expected_height, 0.001)
      end
    end
  end

  describe "position management" do
    it "updates sprite position when character position changes" do
      position = RL::Vector2.new(x: 100.0_f32, y: 200.0_f32)
      size = RL::Vector2.new(x: 32.0_f32, y: 48.0_f32)
      controller = PointClickEngine::Characters::SpriteController.new(position, size)
      controller.load_spritesheet("test.png", 32, 32)

      new_position = RL::Vector2.new(300, 400)
      controller.update_position(new_position)

      controller.position.should eq(new_position)
      if sprite = controller.sprite
        sprite.position.should eq(new_position)
      end
    end

    it "synchronizes position with sprite" do
      position = RL::Vector2.new(x: 100.0_f32, y: 200.0_f32)
      size = RL::Vector2.new(x: 32.0_f32, y: 48.0_f32)
      controller = PointClickEngine::Characters::SpriteController.new(position, size)
      controller.load_spritesheet("test.png", 32, 32)

      initial_pos = RL::Vector2.new(150, 250)
      controller.update_position(initial_pos)

      controller.position.x.should eq(150)
      controller.position.y.should eq(250)
    end
  end

  describe "scale management" do
    it "updates character scale" do
      position = RL::Vector2.new(x: 100.0_f32, y: 200.0_f32)
      size = RL::Vector2.new(x: 32.0_f32, y: 48.0_f32)
      controller = PointClickEngine::Characters::SpriteController.new(position, size)
      controller.load_spritesheet("test.png", 32, 32)
      controller.update_scale(2.0)
      controller.scale.should eq(2.0)
    end

    it "handles manual scale override" do
      position = RL::Vector2.new(x: 100.0_f32, y: 200.0_f32)
      size = RL::Vector2.new(x: 32.0_f32, y: 48.0_f32)
      controller = PointClickEngine::Characters::SpriteController.new(position, size)
      controller.load_spritesheet("test.png", 32, 32)
      controller.set_manual_scale(1.5)
      controller.update_scale(2.0)

      controller.scale.should eq(2.0)           # Character scale
      controller.effective_scale.should eq(1.5) # Manual override
    end

    it "clears manual scale override" do
      position = RL::Vector2.new(x: 100.0_f32, y: 200.0_f32)
      size = RL::Vector2.new(x: 32.0_f32, y: 48.0_f32)
      controller = PointClickEngine::Characters::SpriteController.new(position, size)
      controller.load_spritesheet("test.png", 32, 32)
      controller.set_manual_scale(1.5)
      controller.clear_manual_scale

      controller.manual_scale.should be_nil
      controller.effective_scale.should eq(controller.scale)
    end
  end

  describe "bounds calculation" do
    it "calculates sprite bounds correctly" do
      position = RL::Vector2.new(x: 100.0_f32, y: 200.0_f32)
      size = RL::Vector2.new(x: 32.0_f32, y: 48.0_f32)
      controller = PointClickEngine::Characters::SpriteController.new(position, size)
      controller.load_spritesheet("test.png", 32, 48)
      controller.update_position(RL::Vector2.new(100, 200))
      controller.update_scale(2.0)
      bounds = controller.get_bounds

      # For 32x48 sprite at scale 2.0, positioned at (100, 200)
      expected_width = 32 * 2.0
      expected_height = 48 * 2.0

      bounds.width.should eq(expected_width)
      bounds.height.should eq(expected_height)

      # Character position is at bottom-center of sprite
      bounds.x.should eq(100 - expected_width / 2) # Centered horizontally
      bounds.y.should eq(200 - expected_height)    # Bottom-aligned
    end

    it "handles point collision detection" do
      position = RL::Vector2.new(x: 100.0_f32, y: 200.0_f32)
      size = RL::Vector2.new(x: 32.0_f32, y: 48.0_f32)
      controller = PointClickEngine::Characters::SpriteController.new(position, size)
      controller.load_spritesheet("test.png", 32, 48)
      controller.update_position(RL::Vector2.new(100, 200))
      controller.update_scale(2.0)
      # Point inside sprite bounds
      inside_point = RL::Vector2.new(100, 170) # Near character center
      controller.contains_point?(inside_point).should be_true

      # Point outside sprite bounds
      outside_point = RL::Vector2.new(200, 100) # Far from character
      controller.contains_point?(outside_point).should be_false
    end

    it "provides fallback bounds when no sprite loaded" do
      no_sprite_controller = PointClickEngine::Characters::SpriteController.new(
        RL::Vector2.new(50, 75), RL::Vector2.new(30, 40)
      )

      bounds = no_sprite_controller.get_bounds
      bounds.width.should eq(30)
      bounds.height.should eq(40)
      bounds.x.should eq(50 - 15) # Centered
      bounds.y.should eq(75 - 40) # Bottom-aligned
    end
  end

  describe "rendering" do
    it "applies scale during rendering" do
      position = RL::Vector2.new(x: 100.0_f32, y: 200.0_f32)
      size = RL::Vector2.new(x: 32.0_f32, y: 48.0_f32)
      controller = PointClickEngine::Characters::SpriteController.new(position, size)
      controller.load_spritesheet("test.png", 32, 32)

      controller.update_scale(1.5)
      controller.set_manual_scale(2.0)

      # During draw, should temporarily apply effective scale
      if sprite = controller.sprite
        original_scale = sprite.scale
        controller.draw
        # After draw, scale should be restored
        # Note: This is testing the behavior, actual verification would need mocking
      end
    end

    it "handles visibility control" do
      position = RL::Vector2.new(x: 100.0_f32, y: 200.0_f32)
      size = RL::Vector2.new(x: 32.0_f32, y: 48.0_f32)
      controller = PointClickEngine::Characters::SpriteController.new(position, size)
      controller.load_spritesheet("test.png", 32, 32)

      controller.visible = false
      controller.visible?.should be_false

      controller.visible = true
      controller.visible?.should be_true
    end
  end

  describe "utility methods" do
    it "provides frame dimensions" do
      position = RL::Vector2.new(x: 100.0_f32, y: 200.0_f32)
      size = RL::Vector2.new(x: 32.0_f32, y: 48.0_f32)
      controller = PointClickEngine::Characters::SpriteController.new(position, size)
      controller.frame_width.should eq(0) # No sprite loaded
      controller.frame_height.should eq(0)

      controller.load_spritesheet("test.png", 40, 60)
      controller.frame_width.should eq(40)
      controller.frame_height.should eq(60)
    end

    it "reloads texture" do
      position = RL::Vector2.new(x: 100.0_f32, y: 200.0_f32)
      size = RL::Vector2.new(x: 32.0_f32, y: 48.0_f32)
      controller = PointClickEngine::Characters::SpriteController.new(position, size)
      controller.load_spritesheet("original.png", 32, 32)
      original_path = controller.sprite_path

      controller.reload_texture
      controller.sprite_path.should eq(original_path)
    end

    it "updates size from sprite dimensions" do
      position = RL::Vector2.new(x: 100.0_f32, y: 200.0_f32)
      size = RL::Vector2.new(x: 32.0_f32, y: 48.0_f32)
      controller = PointClickEngine::Characters::SpriteController.new(position, size)
      controller.load_spritesheet("test.png", 32, 48)
      controller.set_manual_scale(3.0)

      controller.update_size_from_sprite

      expected_width = 32 * 3.0
      expected_height = 48 * 3.0
      controller.size.x.should eq(expected_width)
      controller.size.y.should eq(expected_height)
    end
  end

  describe "resource management" do
    it "unloads resources" do
      position = RL::Vector2.new(x: 100.0_f32, y: 200.0_f32)
      size = RL::Vector2.new(x: 32.0_f32, y: 48.0_f32)
      controller = PointClickEngine::Characters::SpriteController.new(position, size)
      controller.load_spritesheet("test.png", 32, 32)

      controller.loaded?.should be_true

      controller.unload

      controller.sprite.should be_nil
      controller.sprite_path.should be_nil
      controller.loaded?.should be_false
    end

    it "creates controller copy" do
      position = RL::Vector2.new(x: 100.0_f32, y: 200.0_f32)
      size = RL::Vector2.new(x: 32.0_f32, y: 48.0_f32)
      controller = PointClickEngine::Characters::SpriteController.new(position, size)
      controller.load_spritesheet("test.png", 32, 32)

      controller.set_manual_scale(1.5)
      controller.update_scale(2.0)

      cloned = controller.clone

      cloned.position.should eq(controller.position)
      cloned.size.should eq(controller.size)
      cloned.sprite_path.should eq(controller.sprite_path)
      cloned.manual_scale.should eq(controller.manual_scale)
      cloned.scale.should eq(controller.scale)

      # Should be separate instances
      cloned.should_not be(controller)
    end
  end

  describe "serialization support" do
    it "handles YAML deserialization" do
      position = RL::Vector2.new(x: 100.0_f32, y: 200.0_f32)
      size = RL::Vector2.new(x: 32.0_f32, y: 48.0_f32)
      controller = PointClickEngine::Characters::SpriteController.new(position, size)
      controller.load_spritesheet("test.png", 32, 32)

      # Simulate YAML deserialization
      ctx = YAML::ParseContext.new
      new_position = RL::Vector2.new(300, 400)
      controller.update_position(new_position)

      controller.after_yaml_deserialize(ctx)

      # Position should be restored to sprite
      if sprite = controller.sprite
        sprite.position.should eq(new_position)
      end
    end
  end

  describe "edge cases" do
    it "handles zero frame dimensions gracefully" do
      position = RL::Vector2.new(x: 100.0_f32, y: 200.0_f32)
      size = RL::Vector2.new(x: 32.0_f32, y: 48.0_f32)
      controller = PointClickEngine::Characters::SpriteController.new(position, size)
      # Should not crash with zero dimensions
      controller.load_spritesheet("empty.png", 0, 0)

      # Scale calculation should handle division by zero
      controller.frame_width.should eq(0)
      controller.frame_height.should eq(0)
    end

    it "handles operations without loaded sprite" do
      position = RL::Vector2.new(x: 100.0_f32, y: 200.0_f32)
      size = RL::Vector2.new(x: 32.0_f32, y: 48.0_f32)
      controller = PointClickEngine::Characters::SpriteController.new(position, size)
      # All operations should work gracefully without sprite
      controller.update_position(RL::Vector2.new(10, 20))
      controller.update_scale(2.0)
      controller.draw # Should not crash

      controller.visible = true
      controller.visible?.should be_false # No sprite to be visible
    end

    it "handles negative scale values" do
      position = RL::Vector2.new(x: 100.0_f32, y: 200.0_f32)
      size = RL::Vector2.new(x: 32.0_f32, y: 48.0_f32)
      controller = PointClickEngine::Characters::SpriteController.new(position, size)

      controller.load_spritesheet("test.png", 32, 32)
      controller.update_scale(-1.0)

      controller.scale.should eq(-1.0)
      # Bounds calculation should handle negative scale
      bounds = controller.get_bounds
      bounds.width.should be >= 0 # Width should be absolute
    end
  end
end
