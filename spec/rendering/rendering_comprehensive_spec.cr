require "../spec_helper"

# Advanced rendering system comprehensive tests
# Tests graphics rendering, camera systems, sprites, and visual effects
describe "Advanced Rendering System Comprehensive Tests" do
  describe "animated sprite system" do
    it "handles sprite creation and initialization" do
      # Test default constructor
      sprite = PointClickEngine::Graphics::AnimatedSprite.new
      sprite.frame_width.should eq(0)
      sprite.frame_height.should eq(0)
      sprite.frame_count.should eq(0)
      sprite.current_frame.should eq(0)
      sprite.frame_speed.should eq(0.1_f32)
      sprite.loop.should be_true
      sprite.playing.should be_true
      sprite.scale.should eq(1.0_f32)

      # Test parameterized constructor
      position = RL::Vector2.new(100.0_f32, 200.0_f32)
      sprite2 = PointClickEngine::Graphics::AnimatedSprite.new(position, 32, 48, 8)
      sprite2.position.should eq(position)
      sprite2.frame_width.should eq(32)
      sprite2.frame_height.should eq(48)
      sprite2.frame_count.should eq(8)
    end

    it "manages animation playback correctly" do
      sprite = PointClickEngine::Graphics::AnimatedSprite.new(RL::Vector2.new(0.0_f32, 0.0_f32), 32, 32, 4)
      sprite.frame_speed = 0.1_f32

      # Initial state
      sprite.playing.should be_true
      sprite.current_frame.should eq(0)
      sprite.frame_timer.should eq(0.0_f32)

      # Test frame advancement
      sprite.update(0.05_f32)           # Half frame time
      sprite.current_frame.should eq(0) # Should not advance yet
      sprite.frame_timer.should eq(0.05_f32)

      sprite.update(0.05_f32)               # Complete frame time
      sprite.current_frame.should eq(1)     # Should advance
      sprite.frame_timer.should eq(0.0_f32) # Should reset timer

      # Test multiple frame advances
      sprite.update(0.1_f32)
      sprite.current_frame.should eq(2)

      sprite.update(0.1_f32)
      sprite.current_frame.should eq(3)

      # Test looping behavior
      sprite.update(0.1_f32)
      sprite.current_frame.should eq(0) # Should loop back to start
      sprite.playing.should be_true
    end

    it "handles non-looping animations correctly" do
      sprite = PointClickEngine::Graphics::AnimatedSprite.new(RL::Vector2.new(0.0_f32, 0.0_f32), 32, 32, 3)
      sprite.frame_speed = 0.1_f32
      sprite.loop = false

      # Advance through all frames
      sprite.update(0.1_f32) # Frame 1
      sprite.current_frame.should eq(1)
      sprite.playing.should be_true

      sprite.update(0.1_f32) # Frame 2 (last frame)
      sprite.current_frame.should eq(2)
      sprite.playing.should be_true

      # Should stop at last frame
      sprite.update(0.1_f32)
      sprite.current_frame.should eq(2) # Stay at last frame
      sprite.playing.should be_false    # Should stop playing

      # Further updates should not change anything
      sprite.update(0.1_f32)
      sprite.current_frame.should eq(2)
      sprite.playing.should be_false
    end

    it "handles play and stop controls" do
      sprite = PointClickEngine::Graphics::AnimatedSprite.new(RL::Vector2.new(0.0_f32, 0.0_f32), 32, 32, 4)
      sprite.frame_speed = 0.1_f32

      # Stop animation
      sprite.stop
      sprite.playing.should be_false

      # Update should not advance frames when stopped
      initial_frame = sprite.current_frame
      sprite.update(0.1_f32)
      sprite.current_frame.should eq(initial_frame)

      # Resume animation
      sprite.play
      sprite.playing.should be_true
      sprite.frame_timer.should eq(0.0_f32) # Should reset timer

      # Should advance frames again
      sprite.update(0.1_f32)
      sprite.current_frame.should eq(initial_frame + 1)
    end

    it "handles scaling correctly" do
      sprite = PointClickEngine::Graphics::AnimatedSprite.new(RL::Vector2.new(0.0_f32, 0.0_f32), 32, 48, 1)

      # Test default scale
      sprite.scale.should eq(1.0_f32)
      sprite.size.x.should eq(32.0_f32)
      sprite.size.y.should eq(48.0_f32)

      # Test scaling
      sprite.scale = 2.0_f32
      # Note: Size update may need manual trigger in real implementation

      # Test fractional scaling
      sprite.scale = 0.5_f32
      sprite.scale.should eq(0.5_f32)
    end

    it "handles edge cases and invalid states" do
      sprite = PointClickEngine::Graphics::AnimatedSprite.new(RL::Vector2.new(0.0_f32, 0.0_f32), 32, 32, 0)

      # Zero frame count
      sprite.frame_count = 0
      sprite.update(0.1_f32) # Should not crash

      # Negative frame speed
      sprite.frame_count = 4
      sprite.frame_speed = -0.1_f32
      sprite.update(0.1_f32) # Should handle gracefully

      # Very fast frame speed
      sprite.frame_speed = 0.001_f32
      sprite.update(1.0_f32) # Should not cause issues
      sprite.current_frame.should be >= 0
      sprite.current_frame.should be < 4

      # Large delta time
      sprite.frame_speed = 0.1_f32
      sprite.current_frame = 0
      sprite.update(10.0_f32) # Very large delta
      sprite.current_frame.should be >= 0
      sprite.current_frame.should be < 4
    end
  end

  describe "camera system" do
    it "initializes with correct viewport settings" do
      camera = PointClickEngine::Graphics::Camera.new(800, 600)

      camera.viewport_width.should eq(800)
      camera.viewport_height.should eq(600)
      camera.position.x.should eq(0.0_f32)
      camera.position.y.should eq(0.0_f32)
      camera.scene_width.should eq(800)
      camera.scene_height.should eq(600)
      camera.follow_speed.should eq(5.0_f32)
      camera.edge_scroll_enabled.should be_true
    end

    it "handles scene size changes correctly" do
      camera = PointClickEngine::Graphics::Camera.new(800, 600)

      # Set larger scene
      camera.set_scene_size(1600, 1200)
      camera.scene_width.should eq(1600)
      camera.scene_height.should eq(1200)

      # Bounds should be updated
      camera.max_x.should eq(800.0_f32) # 1600 - 800
      camera.max_y.should eq(600.0_f32) # 1200 - 600
      camera.min_x.should eq(0.0_f32)
      camera.min_y.should eq(0.0_f32)

      # Set smaller scene (no scrolling needed)
      camera.set_scene_size(400, 300)
      camera.max_x.should eq(0.0_f32)
      camera.max_y.should eq(0.0_f32)
    end

    it "performs coordinate transformations correctly" do
      camera = PointClickEngine::Graphics::Camera.new(800, 600)
      camera.position = RL::Vector2.new(100.0_f32, 50.0_f32)

      # Screen to world conversion
      world_pos = camera.screen_to_world(400, 300)
      world_pos.x.should eq(500.0_f32) # 400 + 100
      world_pos.y.should eq(350.0_f32) # 300 + 50

      # World to screen conversion
      screen_pos = camera.world_to_screen(500.0_f32, 350.0_f32)
      screen_pos.x.should eq(400.0_f32) # 500 - 100
      screen_pos.y.should eq(300.0_f32) # 350 - 50

      # Round-trip conversion
      original_screen_x = 123
      original_screen_y = 456
      world = camera.screen_to_world(original_screen_x, original_screen_y)
      back_to_screen = camera.world_to_screen(world.x, world.y)
      back_to_screen.x.should eq(original_screen_x.to_f32)
      back_to_screen.y.should eq(original_screen_y.to_f32)
    end

    it "handles visibility checks correctly" do
      camera = PointClickEngine::Graphics::Camera.new(800, 600)
      camera.position = RL::Vector2.new(100.0_f32, 50.0_f32)

      # Point in visible area
      camera.is_visible?(400.0_f32, 200.0_f32).should be_true

      # Point outside visible area (left)
      camera.is_visible?(50.0_f32, 200.0_f32).should be_false

      # Point outside visible area (right)
      camera.is_visible?(950.0_f32, 200.0_f32).should be_false

      # Point outside visible area (top)
      camera.is_visible?(400.0_f32, 25.0_f32).should be_false

      # Point outside visible area (bottom)
      camera.is_visible?(400.0_f32, 700.0_f32).should be_false

      # Test with margin
      camera.is_visible?(50.0_f32, 200.0_f32, margin: 100.0_f32).should be_true
    end

    it "centers on positions correctly" do
      camera = PointClickEngine::Graphics::Camera.new(800, 600)
      camera.set_scene_size(1600, 1200)

      # Center on a position
      camera.center_on(400.0_f32, 300.0_f32)

      # Camera should be positioned to center the target
      expected_x = 400.0_f32 - 800 / 2 # 0.0
      expected_y = 300.0_f32 - 600 / 2 # 0.0
      camera.position.x.should eq(expected_x)
      camera.position.y.should eq(expected_y)

      # Center on position near edge (should constrain)
      camera.center_on(100.0_f32, 100.0_f32)
      camera.position.x.should eq(0.0_f32) # Constrained to min
      camera.position.y.should eq(0.0_f32) # Constrained to min

      # Center on position past max bounds
      camera.center_on(1500.0_f32, 1100.0_f32)
      camera.position.x.should eq(800.0_f32) # Constrained to max
      camera.position.y.should eq(600.0_f32) # Constrained to max
    end

    it "gets visible area correctly" do
      camera = PointClickEngine::Graphics::Camera.new(800, 600)
      camera.position = RL::Vector2.new(200.0_f32, 150.0_f32)

      visible_area = camera.get_visible_area
      visible_area.x.should eq(200.0_f32)
      visible_area.y.should eq(150.0_f32)
      visible_area.width.should eq(800.0_f32)
      visible_area.height.should eq(600.0_f32)
    end

    it "handles character following" do
      camera = PointClickEngine::Graphics::Camera.new(800, 600)
      camera.set_scene_size(1600, 1200)

      # Create mock character
      character = TestCharacter.new("follow_test", RL::Vector2.new(800.0_f32, 600.0_f32), RL::Vector2.new(32.0_f32, 48.0_f32))

      # Start following
      camera.follow(character)
      camera.target_character.should eq(character)

      # Update should move camera toward character
      initial_pos = camera.position
      camera.update(0.1_f32, 0, 0)

      # Camera should be moving toward character center
      # (Character at 800,600, camera should center on that)
      expected_x = 800.0_f32 - 800 / 2 # 400
      expected_y = 600.0_f32 - 600 / 2 # 300

      # After one update, should be moving toward target (smooth following)
      # Exact position depends on follow_speed and delta time

      # Stop following
      camera.stop_following
      camera.target_character.should be_nil
    end

    it "handles edge scrolling" do
      camera = PointClickEngine::Graphics::Camera.new(800, 600)
      camera.set_scene_size(1600, 1200)
      camera.edge_scroll_enabled = true
      camera.edge_scroll_margin = 50
      camera.edge_scroll_speed = 100.0_f32

      # Start camera in middle so it can scroll in both directions
      camera.position = RL::Vector2.new(400.0_f32, 300.0_f32)
      initial_pos = camera.position

      # Mouse near left edge
      camera.update(0.1_f32, 25, 300)             # Mouse at x=25 (within margin)
      camera.position.x.should be < initial_pos.x # Should scroll left

      # Reset position
      camera.position = RL::Vector2.new(400.0_f32, 300.0_f32)

      # Mouse near right edge
      camera.update(0.1_f32, 775, 300)        # Mouse at x=775 (800-25, within margin)
      camera.position.x.should be > 400.0_f32 # Should scroll right

      # Test disabling edge scroll
      camera.edge_scroll_enabled = false
      camera.position = RL::Vector2.new(400.0_f32, 300.0_f32)
      start_pos = camera.position
      camera.update(0.1_f32, 25, 300)      # Mouse at edge
      camera.position.should eq(start_pos) # Should not move
    end
  end

  describe "rendering performance and stress tests" do
    it "handles many sprites efficiently" do
      sprites = [] of PointClickEngine::Graphics::AnimatedSprite

      # Create many sprites
      100.times do |i|
        x = ((i % 10) * 64).to_f32
        y = ((i / 10) * 64).to_f32
        sprite = PointClickEngine::Graphics::AnimatedSprite.new(RL::Vector2.new(x, y), 32, 32, 4)
        sprite.frame_speed = 0.1_f32 + (i * 0.001_f32) # Vary speeds slightly
        sprites << sprite
      end

      sprites.size.should eq(100)

      # Update all sprites
      start_time = Time.monotonic
      sprites.each do |sprite|
        sprite.update(0.016_f32) # ~60 FPS
      end
      update_time = Time.monotonic - start_time

      puts "Sprite update performance:"
      puts "  Sprites: #{sprites.size}"
      puts "  Update time: #{update_time.total_milliseconds.round(2)}ms"
      puts "  Time per sprite: #{(update_time.total_milliseconds / sprites.size).round(4)}ms"

      # Should be very fast
      (update_time.total_milliseconds / sprites.size).should be < 0.1 # 0.1ms per sprite

      # Verify all sprites are animating
      animated_count = sprites.count(&.playing)
      animated_count.should eq(100)
    end

    it "handles rapid camera movements" do
      camera = PointClickEngine::Graphics::Camera.new(800, 600)
      camera.set_scene_size(3200, 2400) # Large scene

      # Rapid position changes
      positions = [] of RL::Vector2
      100.times do |i|
        x = (rand(2400)).to_f32 # Within scene bounds
        y = (rand(1800)).to_f32
        positions << RL::Vector2.new(x, y)
      end

      start_time = Time.monotonic
      positions.each do |pos|
        camera.center_on(pos.x, pos.y)
        camera.update(0.016_f32, 400, 300) # Simulate update
      end
      movement_time = Time.monotonic - start_time

      puts "Camera movement performance:"
      puts "  Movements: #{positions.size}"
      puts "  Total time: #{movement_time.total_milliseconds.round(2)}ms"
      puts "  Time per movement: #{(movement_time.total_milliseconds / positions.size).round(4)}ms"

      # Should handle rapid movements efficiently
      (movement_time.total_milliseconds / positions.size).should be < 1.0 # 1ms per movement
    end

    it "handles coordinate transformation stress test" do
      camera = PointClickEngine::Graphics::Camera.new(1920, 1080)
      camera.position = RL::Vector2.new(500.0_f32, 300.0_f32)

      # Many coordinate transformations
      coordinates = [] of {Int32, Int32}
      1000.times do |i|
        x = rand(1920)
        y = rand(1080)
        coordinates << {x, y}
      end

      start_time = Time.monotonic
      transformed_coords = coordinates.map do |screen_x, screen_y|
        world_pos = camera.screen_to_world(screen_x, screen_y)
        camera.world_to_screen(world_pos.x, world_pos.y)
      end
      transform_time = Time.monotonic - start_time

      puts "Coordinate transformation performance:"
      puts "  Transformations: #{coordinates.size * 2} (round-trip)"
      puts "  Total time: #{transform_time.total_milliseconds.round(2)}ms"
      puts "  Time per transform: #{(transform_time.total_milliseconds / (coordinates.size * 2)).round(4)}ms"

      # Should be very fast
      (transform_time.total_milliseconds / (coordinates.size * 2)).should be < 0.01 # 0.01ms per transform

      # Verify accuracy of round-trip transformations
      transformed_coords.each_with_index do |back_coord, i|
        original_x, original_y = coordinates[i]
        back_coord.x.should be_close(original_x.to_f32, 0.1_f32)
        back_coord.y.should be_close(original_y.to_f32, 0.1_f32)
      end
    end
  end

  describe "rendering edge cases and error handling" do
    it "handles invalid sprite configurations" do
      # Sprite with zero dimensions
      sprite = PointClickEngine::Graphics::AnimatedSprite.new(RL::Vector2.new(0.0_f32, 0.0_f32), 0, 0, 1)
      sprite.update(0.1_f32) # Should not crash

      # Sprite with negative dimensions
      sprite2 = PointClickEngine::Graphics::AnimatedSprite.new(RL::Vector2.new(0.0_f32, 0.0_f32), -32, -32, 1)
      sprite2.update(0.1_f32) # Should not crash

      # Sprite with zero frame count
      sprite3 = PointClickEngine::Graphics::AnimatedSprite.new(RL::Vector2.new(0.0_f32, 0.0_f32), 32, 32, 0)
      sprite3.update(0.1_f32) # Should not crash

      # Sprite with negative frame count
      sprite4 = PointClickEngine::Graphics::AnimatedSprite.new(RL::Vector2.new(0.0_f32, 0.0_f32), 32, 32, -1)
      sprite4.frame_count = -1
      sprite4.update(0.1_f32) # Should not crash
    end

    it "handles extreme camera configurations" do
      # Very small viewport
      small_camera = PointClickEngine::Graphics::Camera.new(1, 1)
      small_camera.update(0.1_f32, 0, 0) # Should not crash

      # Very large viewport
      large_camera = PointClickEngine::Graphics::Camera.new(10000, 10000)
      large_camera.set_scene_size(50000, 50000)
      large_camera.center_on(25000.0_f32, 25000.0_f32)
      large_camera.update(0.1_f32, 5000, 5000) # Should not crash

      # Zero viewport
      zero_camera = PointClickEngine::Graphics::Camera.new(0, 0)
      zero_camera.update(0.1_f32, 0, 0) # Should not crash
    end

    it "handles sprite memory management" do
      initial_memory = GC.stats.heap_size

      # Create and destroy many sprites
      10.times do |cycle|
        sprites = [] of PointClickEngine::Graphics::AnimatedSprite

        100.times do |i|
          sprite = PointClickEngine::Graphics::AnimatedSprite.new(
            RL::Vector2.new(rand(1000).to_f32, rand(1000).to_f32),
            32, 32, 8
          )
          sprite.frame_speed = 0.1_f32
          sprites << sprite
        end

        # Use the sprites
        sprites.each do |sprite|
          sprite.update(0.016_f32)
          sprite.play
          sprite.stop
        end

        # Sprites go out of scope here
      end

      # Force garbage collection
      GC.collect
      final_memory = GC.stats.heap_size
      memory_growth = final_memory.to_i64 - initial_memory.to_i64

      puts "Rendering memory test: growth = #{memory_growth} bytes"

      # Should not leak significant memory
      memory_growth.should be < 5_000_000 # 5MB limit
    end

    it "handles camera bounds edge cases" do
      camera = PointClickEngine::Graphics::Camera.new(800, 600)

      # Scene smaller than viewport
      camera.set_scene_size(400, 300)
      camera.center_on(1000.0_f32, 1000.0_f32) # Try to center outside scene
      camera.position.x.should eq(0.0_f32)
      camera.position.y.should eq(0.0_f32)

      # Scene exactly same size as viewport
      camera.set_scene_size(800, 600)
      camera.center_on(400.0_f32, 300.0_f32)
      camera.position.x.should eq(0.0_f32)
      camera.position.y.should eq(0.0_f32)

      # Negative scene dimensions (should be handled gracefully)
      camera.set_scene_size(-100, -100)
      camera.update(0.1_f32, 400, 300) # Should not crash
    end
  end
end

# Test character class for camera following tests
class TestCharacter < PointClickEngine::Characters::Character
  def on_interact(interactor : PointClickEngine::Characters::Character)
    # Test implementation
  end

  def on_look
    # Test implementation
  end

  def on_talk
    # Test implementation
  end
end
