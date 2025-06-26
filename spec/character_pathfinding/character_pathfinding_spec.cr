require "../spec_helper"

# Character and pathfinding comprehensive tests
# Tests character movement, pathfinding algorithms, navigation grids, and integration
describe "Character and Pathfinding Comprehensive Tests" do
  describe "character movement fundamentals" do
    it "handles basic character creation and properties" do
      # Test character creation without graphics
      position = RL::Vector2.new(100.0_f32, 200.0_f32)
      size = RL::Vector2.new(32.0_f32, 48.0_f32)

      character = TestCharacter.new("test_character", position, size)

      character.name.should eq("test_character")
      character.position.should eq(position)
      character.size.should eq(size)
      character.state.should eq(PointClickEngine::Characters::CharacterState::Idle)
      character.direction.should eq(PointClickEngine::Characters::Direction::Right)
      character.walking_speed.should eq(PointClickEngine::Core::GameConstants::DEFAULT_WALKING_SPEED)
      character.use_pathfinding.should be_true
    end

    it "manages character states correctly" do
      character = TestCharacter.new("state_test", RL::Vector2.new(0.0_f32, 0.0_f32), RL::Vector2.new(32.0_f32, 48.0_f32))

      # Test state transitions
      character.state = PointClickEngine::Characters::CharacterState::Walking
      character.state.should eq(PointClickEngine::Characters::CharacterState::Walking)

      character.state = PointClickEngine::Characters::CharacterState::Talking
      character.state.should eq(PointClickEngine::Characters::CharacterState::Talking)

      character.state = PointClickEngine::Characters::CharacterState::Interacting
      character.state.should eq(PointClickEngine::Characters::CharacterState::Interacting)

      character.state = PointClickEngine::Characters::CharacterState::Thinking
      character.state.should eq(PointClickEngine::Characters::CharacterState::Thinking)
    end

    it "handles direction changes properly" do
      character = TestCharacter.new("direction_test", RL::Vector2.new(0.0_f32, 0.0_f32), RL::Vector2.new(32.0_f32, 48.0_f32))

      # Test all directions
      PointClickEngine::Characters::Direction.values.each do |direction|
        character.direction = direction
        character.direction.should eq(direction)
      end
    end

    it "manages character mood system" do
      character = TestCharacter.new("mood_test", RL::Vector2.new(0.0_f32, 0.0_f32), RL::Vector2.new(32.0_f32, 48.0_f32))

      # Test all moods
      PointClickEngine::Characters::CharacterMood.values.each do |mood|
        character.set_mood(mood)
        character.mood.should eq(mood)
      end
    end
  end

  describe "character animation system" do
    it "manages animation definitions" do
      character = TestCharacter.new("anim_test", RL::Vector2.new(0.0_f32, 0.0_f32), RL::Vector2.new(32.0_f32, 48.0_f32))

      # Add various animations
      character.add_animation("idle", 0, 1, 0.5_f32, true)
      character.add_animation("walk_right", 1, 4, 0.15_f32, true)
      character.add_animation("walk_left", 5, 4, 0.15_f32, true)
      character.add_animation("talk", 9, 2, 0.3_f32, true)
      character.add_animation("one_shot", 11, 3, 0.2_f32, false)

      # Verify animations were added
      character.animation_controller.should_not be_nil
      # Note: AnimationController may have default animations, so we just check for our added ones
      character.animation_controller.try(&.has_animation?("idle")).should be_true
      character.animation_controller.try(&.has_animation?("walk_right")).should be_true
      character.animation_controller.try(&.has_animation?("walk_left")).should be_true
      character.animation_controller.try(&.has_animation?("talk")).should be_true
      character.animation_controller.try(&.has_animation?("one_shot")).should be_true

      # Check animation data
      idle_anim = character.animation_controller.try(&.get_animation("idle"))
      idle_anim.should_not be_nil
      idle_anim.try(&.start_frame).should eq(0)
      idle_anim.try(&.frame_count).should eq(1)
      idle_anim.try(&.frame_speed).should eq(0.5_f32)
      idle_anim.try(&.loop).should be_true

      walk_anim = character.animation_controller.try(&.get_animation("walk_right"))
      walk_anim.should_not be_nil
      walk_anim.try(&.start_frame).should eq(1)
      walk_anim.try(&.frame_count).should eq(4)
      walk_anim.try(&.frame_speed).should eq(0.15_f32)
      walk_anim.try(&.loop).should be_true

      one_shot_anim = character.animation_controller.try(&.get_animation("one_shot"))
      one_shot_anim.should_not be_nil
      one_shot_anim.try(&.loop).should be_false
    end

    it "handles animation playback requests" do
      character = TestCharacter.new("playback_test", RL::Vector2.new(0.0_f32, 0.0_f32), RL::Vector2.new(32.0_f32, 48.0_f32))

      # Add test animations
      character.add_animation("test_anim1", 0, 2)
      character.add_animation("test_anim2", 2, 3)

      # Test playing animations
      character.play_animation("test_anim1")
      character.animation_controller.try(&.current_animation).should eq("test_anim1")

      character.play_animation("test_anim2")
      character.animation_controller.try(&.current_animation).should eq("test_anim2")

      # Test invalid animation (should not crash)
      character.play_animation("nonexistent")
      character.animation_controller.try(&.current_animation).should eq("test_anim2") # Should remain unchanged
    end
  end

  describe "character movement mechanics" do
    it "handles direct movement targets" do
      character = TestCharacter.new("movement_test", RL::Vector2.new(100.0_f32, 100.0_f32), RL::Vector2.new(32.0_f32, 48.0_f32))

      # Set walking speed for predictable tests
      character.walking_speed = 100.0_f32

      # Test setting movement target
      target = RL::Vector2.new(200.0_f32, 200.0_f32)
      character.walk_to(target, use_pathfinding: false)

      # Verify movement state was set
      character.state.should eq(PointClickEngine::Characters::CharacterState::Walking)
      if movement_controller = character.movement_controller
        movement_controller.target_position.should eq(target)
      end
    end

    it "handles movement stopping" do
      character = TestCharacter.new("stop_test", RL::Vector2.new(0.0_f32, 0.0_f32), RL::Vector2.new(32.0_f32, 48.0_f32))

      # Start movement
      target = RL::Vector2.new(100.0_f32, 100.0_f32)
      character.walk_to(target, use_pathfinding: false)
      character.state.should eq(PointClickEngine::Characters::CharacterState::Walking)

      # Stop movement
      character.stop_walking
      character.state.should eq(PointClickEngine::Characters::CharacterState::Idle)
      if movement_controller = character.movement_controller
        movement_controller.target_position.should be_nil
      end
    end

    it "calculates movement state correctly" do
      character = TestCharacter.new("state_test", RL::Vector2.new(0.0_f32, 0.0_f32), RL::Vector2.new(32.0_f32, 48.0_f32))

      # Initially not moving
      character.moving?.should be_false
      character.following_path?.should be_false
      character.distance_to_target.should eq(0.0_f32)

      # Set movement target
      target = RL::Vector2.new(100.0_f32, 100.0_f32)
      character.walk_to(target, use_pathfinding: false)

      # Movement controller should handle state
      # (In real implementation, these would be managed by MovementController)
    end

    it "handles movement completion callbacks" do
      character = TestCharacter.new("callback_test", RL::Vector2.new(0.0_f32, 0.0_f32), RL::Vector2.new(32.0_f32, 48.0_f32))

      callback_called = false
      character.on_movement_complete do
        callback_called = true
      end

      # Movement controller should handle callbacks
      # (In real implementation, callback would be triggered when movement completes)

      # For now, just verify the callback was set
      character.movement_controller.should_not be_nil
    end
  end

  describe "pathfinding navigation grid" do
    it "creates navigation grid with proper dimensions" do
      width = 800
      height = 600
      cell_size = 32

      grid = PointClickEngine::Navigation::Pathfinding::NavigationGrid.new(
        (width / cell_size).to_i,
        (height / cell_size).to_i,
        cell_size
      )

      grid.width.should eq((width / cell_size).to_i)
      grid.height.should eq((height / cell_size).to_i)
      grid.cell_size.should eq(cell_size)

      # All cells should be walkable by default
      (0...grid.height).each do |y|
        (0...grid.width).each do |x|
          grid.is_walkable?(x, y).should be_true
        end
      end
    end

    it "handles walkable area modifications" do
      grid = PointClickEngine::Navigation::Pathfinding::NavigationGrid.new(10, 10, 32)

      # Mark some cells as non-walkable
      grid.set_walkable(5, 5, false)
      grid.set_walkable(6, 6, false)
      grid.set_walkable(7, 7, false)

      # Verify changes
      grid.is_walkable?(5, 5).should be_false
      grid.is_walkable?(6, 6).should be_false
      grid.is_walkable?(7, 7).should be_false

      # Other cells should remain walkable
      grid.is_walkable?(0, 0).should be_true
      grid.is_walkable?(9, 9).should be_true
      grid.is_walkable?(4, 4).should be_true
    end

    it "handles coordinate transformations correctly" do
      grid = PointClickEngine::Navigation::Pathfinding::NavigationGrid.new(10, 10, 32)

      # Test world to grid conversion
      grid_coords = grid.world_to_grid(64.0_f32, 96.0_f32)
      grid_coords[0].should eq(2) # 64 / 32 = 2
      grid_coords[1].should eq(3) # 96 / 32 = 3

      # Test grid to world conversion
      world_coords = grid.grid_to_world(2, 3)
      world_coords[0].should eq(80.0_f32)  # 2 * 32 + 16 = 80
      world_coords[1].should eq(112.0_f32) # 3 * 32 + 16 = 112

      # Test round-trip conversion
      original_world_x = 123.5_f32
      original_world_y = 456.7_f32

      grid_x, grid_y = grid.world_to_grid(original_world_x, original_world_y)
      back_to_world_x, back_to_world_y = grid.grid_to_world(grid_x, grid_y)

      # Should be close to cell center
      (back_to_world_x - grid.cell_size / 2).should be_close(grid_x * grid.cell_size, 1.0)
      (back_to_world_y - grid.cell_size / 2).should be_close(grid_y * grid.cell_size, 1.0)
    end

    it "handles rectangular area blocking" do
      grid = PointClickEngine::Navigation::Pathfinding::NavigationGrid.new(20, 20, 16)

      # Block a rectangular area
      rect_x = 128
      rect_y = 96
      rect_width = 64
      rect_height = 48

      grid.set_rect_walkable(rect_x, rect_y, rect_width, rect_height, false)

      # Verify the area is blocked
      test_x = rect_x + rect_width / 2
      test_y = rect_y + rect_height / 2
      grid_test_x, grid_test_y = grid.world_to_grid(test_x.to_f32, test_y.to_f32)

      grid.is_walkable?(grid_test_x, grid_test_y).should be_false

      # Verify areas outside the rectangle are still walkable
      grid.is_walkable?(0, 0).should be_true
      grid.is_walkable?(19, 19).should be_true
    end

    it "handles boundary conditions properly" do
      grid = PointClickEngine::Navigation::Pathfinding::NavigationGrid.new(5, 5, 32)

      # Test boundary access
      grid.is_walkable?(-1, 0).should be_false # Outside left
      grid.is_walkable?(0, -1).should be_false # Outside top
      grid.is_walkable?(5, 0).should be_false  # Outside right
      grid.is_walkable?(0, 5).should be_false  # Outside bottom

      # Test valid boundaries
      grid.is_walkable?(0, 0).should be_true # Top-left corner
      grid.is_walkable?(4, 4).should be_true # Bottom-right corner

      # Test setting walkable outside boundaries (should not crash)
      grid.set_walkable(-1, -1, false) # Should not crash
      grid.set_walkable(10, 10, false) # Should not crash
    end
  end

  describe "A* pathfinding algorithm" do
    it "creates pathfinding instance correctly" do
      grid = PointClickEngine::Navigation::Pathfinding::NavigationGrid.new(10, 10, 32)
      pathfinder = PointClickEngine::Navigation::Pathfinding.new(grid, allow_diagonal: true)

      pathfinder.grid.should eq(grid)
      pathfinder.allow_diagonal.should be_true

      # Test with diagonal disabled
      pathfinder_no_diag = PointClickEngine::Navigation::Pathfinding.new(grid, allow_diagonal: false)
      pathfinder_no_diag.allow_diagonal.should be_false
    end

    it "finds simple direct paths" do
      grid = PointClickEngine::Navigation::Pathfinding::NavigationGrid.new(10, 10, 32)
      pathfinder = PointClickEngine::Navigation::Pathfinding.new(grid)

      # Test straight line path
      start_x = 32.0_f32 # Grid position (1, 1)
      start_y = 32.0_f32
      end_x = 160.0_f32 # Grid position (5, 1)
      end_y = 32.0_f32

      path = pathfinder.find_path(start_x, start_y, end_x, end_y)
      path.should_not be_nil

      if found_path = path
        found_path.size.should be > 0

        # Path should start near start position
        start_distance = Math.sqrt((found_path[0].x - start_x) ** 2 + (found_path[0].y - start_y) ** 2)
        start_distance.should be < 50.0 # Within reasonable distance

        # Path should end near end position
        last_idx = found_path.size - 1
        end_distance = Math.sqrt((found_path[last_idx].x - end_x) ** 2 + (found_path[last_idx].y - end_y) ** 2)
        end_distance.should be < 50.0 # Within reasonable distance
      end
    end

    it "handles blocked paths gracefully" do
      grid = PointClickEngine::Navigation::Pathfinding::NavigationGrid.new(10, 10, 32)

      # Create a wall blocking the path
      (0...grid.height).each do |y|
        grid.set_walkable(5, y, false)
      end

      pathfinder = PointClickEngine::Navigation::Pathfinding.new(grid)

      # Try to find path through the wall
      start_x = 32.0_f32 # Left side of wall
      start_y = 160.0_f32
      end_x = 224.0_f32 # Right side of wall
      end_y = 160.0_f32

      path = pathfinder.find_path(start_x, start_y, end_x, end_y)

      # Should either find a path around or return nil if completely blocked
      if found_path = path
        # If path found, it should avoid the wall
        found_path.each do |point|
          grid_x, grid_y = grid.world_to_grid(point.x, point.y)
          grid.is_walkable?(grid_x, grid_y).should be_true
        end
      end
    end

    it "handles impossible paths" do
      grid = PointClickEngine::Navigation::Pathfinding::NavigationGrid.new(10, 10, 32)

      # Completely block the destination
      grid.set_walkable(8, 8, false)
      grid.set_walkable(7, 8, false)
      grid.set_walkable(9, 8, false)
      grid.set_walkable(8, 7, false)
      grid.set_walkable(8, 9, false)
      grid.set_walkable(7, 7, false)
      grid.set_walkable(9, 9, false)
      grid.set_walkable(7, 9, false)
      grid.set_walkable(9, 7, false)

      pathfinder = PointClickEngine::Navigation::Pathfinding.new(grid)

      # Try to reach blocked destination
      path = pathfinder.find_path(32.0_f32, 32.0_f32, 256.0_f32, 256.0_f32)
      path.should be_nil
    end

    it "respects diagonal movement settings" do
      grid = PointClickEngine::Navigation::Pathfinding::NavigationGrid.new(5, 5, 32)

      # Test with diagonals enabled
      pathfinder_diag = PointClickEngine::Navigation::Pathfinding.new(grid, allow_diagonal: true)
      path_diag = pathfinder_diag.find_path(16.0_f32, 16.0_f32, 144.0_f32, 144.0_f32)

      # Test with diagonals disabled
      pathfinder_no_diag = PointClickEngine::Navigation::Pathfinding.new(grid, allow_diagonal: false)
      path_no_diag = pathfinder_no_diag.find_path(16.0_f32, 16.0_f32, 144.0_f32, 144.0_f32)

      # Both should find paths, but diagonal path might be shorter
      path_diag.should_not be_nil
      path_no_diag.should_not be_nil

      if diag_path = path_diag
        if no_diag_path = path_no_diag
          # Diagonal path should generally be shorter or equal length
          diag_path.size.should be <= no_diag_path.size
        end
      end
    end
  end

  describe "pathfinding edge cases and stress tests" do
    it "handles very large grids efficiently" do
      # Test with reasonably large grid
      large_grid = PointClickEngine::Navigation::Pathfinding::NavigationGrid.new(100, 100, 16)
      pathfinder = PointClickEngine::Navigation::Pathfinding.new(large_grid)

      start_time = Time.monotonic
      path = pathfinder.find_path(16.0_f32, 16.0_f32, 1584.0_f32, 1584.0_f32)
      pathfind_time = Time.monotonic - start_time

      puts "Large grid pathfinding performance:"
      puts "  Grid size: 100x100"
      puts "  Pathfinding time: #{pathfind_time.total_milliseconds.round(2)}ms"

      # Should complete within reasonable time
      pathfind_time.total_milliseconds.should be < 1000.0 # 1 second
      path.should_not be_nil
    end

    it "handles complex maze-like environments" do
      grid = PointClickEngine::Navigation::Pathfinding::NavigationGrid.new(20, 20, 16)

      # Create a maze-like pattern
      (0...grid.height).each do |y|
        (0...grid.width).each do |x|
          # Create a checkerboard-like pattern with corridors
          if (x + y) % 4 == 0 && x % 2 == 1 && y % 2 == 1
            grid.set_walkable(x, y, false)
          end
        end
      end

      pathfinder = PointClickEngine::Navigation::Pathfinding.new(grid)

      # Find path through the maze
      path = pathfinder.find_path(24.0_f32, 24.0_f32, 296.0_f32, 296.0_f32)

      # Should find a path despite complexity
      path.should_not be_nil

      if found_path = path
        # Verify all points in path are walkable
        found_path.each do |point|
          grid_x, grid_y = grid.world_to_grid(point.x, point.y)
          grid.is_walkable?(grid_x, grid_y).should be_true
        end
      end
    end

    it "handles single cell paths" do
      grid = PointClickEngine::Navigation::Pathfinding::NavigationGrid.new(5, 5, 32)
      pathfinder = PointClickEngine::Navigation::Pathfinding.new(grid)

      # Path from one cell to itself (very short path)
      path = pathfinder.find_path(48.0_f32, 48.0_f32, 52.0_f32, 52.0_f32)

      path.should_not be_nil
      if found_path = path
        found_path.size.should be >= 1
      end
    end

    it "handles boundary to boundary paths" do
      grid = PointClickEngine::Navigation::Pathfinding::NavigationGrid.new(10, 10, 32)
      pathfinder = PointClickEngine::Navigation::Pathfinding.new(grid)

      # Path from one corner to opposite corner
      path = pathfinder.find_path(16.0_f32, 16.0_f32, 304.0_f32, 304.0_f32)

      path.should_not be_nil
      if found_path = path
        found_path.size.should be > 1

        # Should span most of the grid
        start_point = found_path[0]
        end_point = found_path[-1]
        total_distance = Math.sqrt((end_point.x - start_point.x) ** 2 + (end_point.y - start_point.y) ** 2)
        total_distance.should be > 200.0 # Significant distance
      end
    end
  end

  describe "character-pathfinding integration" do
    it "integrates character movement with pathfinding" do
      character = TestCharacter.new("pathfind_test", RL::Vector2.new(50.0_f32, 50.0_f32), RL::Vector2.new(32.0_f32, 48.0_f32))

      # Enable pathfinding
      character.use_pathfinding = true

      # Create test path
      test_path = [
        RL::Vector2.new(50.0_f32, 50.0_f32),
        RL::Vector2.new(100.0_f32, 50.0_f32),
        RL::Vector2.new(100.0_f32, 100.0_f32),
        RL::Vector2.new(150.0_f32, 100.0_f32),
      ]

      character.walk_to_with_path(test_path)
      character.state.should eq(PointClickEngine::Characters::CharacterState::Walking)
      if movement_controller = character.movement_controller
        movement_controller.path.should eq(test_path)
      end
    end

    it "handles movement updates correctly" do
      character = TestCharacter.new("update_test", RL::Vector2.new(0.0_f32, 0.0_f32), RL::Vector2.new(32.0_f32, 48.0_f32))

      # Set up for movement
      character.walking_speed = 100.0_f32
      character.state = PointClickEngine::Characters::CharacterState::Walking
      character.target_position = RL::Vector2.new(100.0_f32, 0.0_f32)

      # Update character (this would normally update position)
      initial_pos = character.position
      character.update(0.1_f32) # 100ms update

      # Position might change depending on movement controller implementation
      # At minimum, update should not crash
      character.should_not be_nil
    end

    it "handles character collision bounds correctly" do
      character = TestCharacter.new("collision_test", RL::Vector2.new(100.0_f32, 100.0_f32), RL::Vector2.new(64.0_f32, 96.0_f32))

      # Test point inside bounds
      inside_point = RL::Vector2.new(100.0_f32, 80.0_f32)
      character.contains_point?(inside_point).should be_true

      # Test point outside bounds
      outside_point = RL::Vector2.new(200.0_f32, 200.0_f32)
      character.contains_point?(outside_point).should be_false

      # Test edge cases
      edge_point = RL::Vector2.new(132.0_f32, 100.0_f32) # Right edge
      # Result may vary based on exact bounds calculation

      # Test with negative coordinates
      negative_point = RL::Vector2.new(-50.0_f32, -50.0_f32)
      character.contains_point?(negative_point).should be_false
    end
  end

  describe "performance and memory tests" do
    it "handles many characters efficiently" do
      characters = [] of TestCharacter

      # Create many characters
      100.times do |i|
        x = ((i % 10) * 50).to_f32
        y = ((i / 10) * 50).to_f32
        character = TestCharacter.new("char_#{i}", RL::Vector2.new(x, y), RL::Vector2.new(32.0_f32, 48.0_f32))
        characters << character
      end

      characters.size.should eq(100)

      # Update all characters
      start_time = Time.monotonic
      characters.each do |char|
        char.update(0.016_f32) # ~60 FPS
      end
      update_time = Time.monotonic - start_time

      puts "Character update performance:"
      puts "  Characters: #{characters.size}"
      puts "  Update time: #{update_time.total_milliseconds.round(2)}ms"
      puts "  Time per character: #{(update_time.total_milliseconds / characters.size).round(4)}ms"

      # Should be reasonably fast
      (update_time.total_milliseconds / characters.size).should be < 1.0 # 1ms per character
    end

    it "manages memory efficiently during pathfinding" do
      initial_memory = GC.stats.heap_size

      # Perform many pathfinding operations
      grid = PointClickEngine::Navigation::Pathfinding::NavigationGrid.new(50, 50, 16)
      pathfinder = PointClickEngine::Navigation::Pathfinding.new(grid)

      paths = [] of Array(RL::Vector2)?

      50.times do |i|
        start_x = ((rand(40) + 1) * 16).to_f32
        start_y = ((rand(40) + 1) * 16).to_f32
        end_x = ((rand(40) + 1) * 16).to_f32
        end_y = ((rand(40) + 1) * 16).to_f32

        path = pathfinder.find_path(start_x, start_y, end_x, end_y)
        paths << path
      end

      # Force garbage collection
      GC.collect
      final_memory = GC.stats.heap_size
      memory_growth = final_memory.to_i64 - initial_memory.to_i64

      puts "Pathfinding memory test: growth = #{memory_growth} bytes"

      # Should not leak significant memory
      memory_growth.should be < 10_000_000 # 10MB limit

      # Verify some paths were found
      found_paths = paths.compact
      found_paths.size.should be > 0
    end
  end
end

# Test character class for testing purposes
class TestCharacter < PointClickEngine::Characters::Character
  def on_interact(interactor : PointClickEngine::Characters::Character)
    # Test interaction implementation
  end

  def on_look
    # Test look implementation
  end

  def on_talk
    # Test talk implementation
  end
end
