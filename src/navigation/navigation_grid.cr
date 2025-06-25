require "../core/game_constants"

module PointClickEngine
  module Navigation
    # Grid-based navigation mesh for pathfinding
    #
    # The NavigationGrid provides a grid-based representation of walkable areas
    # in the game world. It handles coordinate conversion between world space
    # and grid space, and manages walkable/non-walkable cell states.
    class NavigationGrid
      # Grid dimensions
      property width : Int32
      property height : Int32
      property cell_size : Int32

      # Grid data
      property walkable : Array(Array(Bool))

      def initialize(@width : Int32, @height : Int32, @cell_size : Int32 = PointClickEngine::Core::GameConstants::DEFAULT_NAVIGATION_CELL_SIZE)
        @walkable = Array.new(@height) { Array.new(@width, true) }
      end

      # Sets walkable state for a specific grid cell
      def set_walkable(x : Int32, y : Int32, walkable : Bool)
        return if x < 0 || y < 0 || x >= @width || y >= @height
        @walkable[y][x] = walkable
      end

      # Checks if a grid cell is walkable
      def is_walkable?(x : Int32, y : Int32) : Bool
        return false if x < 0 || y < 0 || x >= @width || y >= @height
        @walkable[y][x]
      end

      # Converts world coordinates to grid coordinates
      def world_to_grid(world_x : Float32, world_y : Float32) : {Int32, Int32}
        grid_x = (world_x / @cell_size).to_i
        grid_y = (world_y / @cell_size).to_i
        {grid_x, grid_y}
      end

      # Converts grid coordinates to world coordinates (center of cell)
      def grid_to_world(grid_x : Int32, grid_y : Int32) : {Float32, Float32}
        world_x = (grid_x * @cell_size + @cell_size / 2).to_f32
        world_y = (grid_y * @cell_size + @cell_size / 2).to_f32
        {world_x, world_y}
      end

      # Marks a rectangular area as walkable or not walkable
      def set_rect_walkable(x : Int32, y : Int32, width : Int32, height : Int32, walkable : Bool)
        grid_x1, grid_y1 = world_to_grid(x.to_f32, y.to_f32)
        grid_x2, grid_y2 = world_to_grid((x + width).to_f32, (y + height).to_f32)

        (grid_y1..grid_y2).each do |gy|
          (grid_x1..grid_x2).each do |gx|
            set_walkable(gx, gy, walkable)
          end
        end
      end

      # Marks a circular area as walkable or not walkable
      def set_circle_walkable(center_x : Float32, center_y : Float32, radius : Float32, walkable : Bool)
        grid_center_x, grid_center_y = world_to_grid(center_x, center_y)
        grid_radius = (radius / @cell_size).ceil.to_i

        ((grid_center_y - grid_radius)..(grid_center_y + grid_radius)).each do |gy|
          ((grid_center_x - grid_radius)..(grid_center_x + grid_radius)).each do |gx|
            # Check if grid cell is within the circle
            world_x, world_y = grid_to_world(gx, gy)
            distance = Math.sqrt((world_x - center_x) ** 2 + (world_y - center_y) ** 2)

            if distance <= radius
              set_walkable(gx, gy, walkable)
            end
          end
        end
      end

      # Gets the bounds of the grid in world coordinates
      def world_bounds : {width: Float32, height: Float32}
        {
          width:  (@width * @cell_size).to_f32,
          height: (@height * @cell_size).to_f32,
        }
      end

      # Checks if world coordinates are within grid bounds
      def in_bounds?(world_x : Float32, world_y : Float32) : Bool
        grid_x, grid_y = world_to_grid(world_x, world_y)
        grid_x >= 0 && grid_y >= 0 && grid_x < @width && grid_y < @height
      end

      # Checks if grid coordinates are valid
      def valid_grid_coords?(grid_x : Int32, grid_y : Int32) : Bool
        grid_x >= 0 && grid_y >= 0 && grid_x < @width && grid_y < @height
      end

      # Gets all walkable cells adjacent to a given position
      def get_walkable_neighbors(grid_x : Int32, grid_y : Int32, allow_diagonal : Bool = true) : Array({Int32, Int32})
        neighbors = [] of {Int32, Int32}

        # Orthogonal neighbors
        [{0, 1}, {0, -1}, {1, 0}, {-1, 0}].each do |dx, dy|
          nx, ny = grid_x + dx, grid_y + dy
          if is_walkable?(nx, ny)
            neighbors << {nx, ny}
          end
        end

        # Diagonal neighbors
        if allow_diagonal
          [{1, 1}, {1, -1}, {-1, 1}, {-1, -1}].each do |dx, dy|
            nx, ny = grid_x + dx, grid_y + dy
            if is_walkable?(nx, ny)
              # Check that we can move diagonally (both adjacent orthogonal cells are walkable)
              if is_walkable?(grid_x + dx, grid_y) && is_walkable?(grid_x, grid_y + dy)
                neighbors << {nx, ny}
              end
            end
          end
        end

        neighbors
      end

      # Counts total walkable cells
      def walkable_cell_count : Int32
        count = 0
        @walkable.each do |row|
          count += row.count(&.itself)
        end
        count
      end

      # Gets walkable percentage
      def walkable_percentage : Float32
        total_cells = @width * @height
        return 0.0f32 if total_cells == 0
        (walkable_cell_count.to_f32 / total_cells) * 100.0f32
      end

      # Clears all walkable data (makes everything walkable)
      def clear
        @walkable.each do |row|
          row.fill(true)
        end
      end

      # Fills all walkable data (makes everything non-walkable)
      def fill_non_walkable
        @walkable.each do |row|
          row.fill(false)
        end
      end

      # Creates a grid from scene data
      def self.from_scene(scene : Scenes::Scene, width : Int32, height : Int32, cell_size : Int32 = PointClickEngine::Core::GameConstants::DEFAULT_NAVIGATION_CELL_SIZE, character_radius : Float32 = PointClickEngine::Core::GameConstants::DEFAULT_CHARACTER_RADIUS) : NavigationGrid
        grid_width = (width / cell_size).to_i + 1
        grid_height = (height / cell_size).to_i + 1
        grid = new(grid_width, grid_height, cell_size)

        # Apply walkable area restrictions if defined
        if walkable_area = scene.walkable_area
          # Mark all cells based on walkable area
          # We need to ensure a character can fit, so we check a radius around each cell
          total_walkable_cells = 0
          (0...grid.height).each do |y|
            (0...grid.width).each do |x|
              world_x, world_y = grid.grid_to_world(x, y)
              world_pos = RL::Vector2.new(x: world_x, y: world_y)

              # Check if a character-sized area can fit here
              # We use a more lenient approach: check center and a smaller radius
              # This prevents overly restrictive navigation grids
              reduced_radius = character_radius * PointClickEngine::Core::GameConstants::NAVIGATION_RADIUS_REDUCTION # Use reduced radius for more flexibility

              check_points = [
                world_pos, # Center must always be walkable
                RL::Vector2.new(x: world_x - reduced_radius, y: world_y - reduced_radius),
                RL::Vector2.new(x: world_x + reduced_radius, y: world_y - reduced_radius),
                RL::Vector2.new(x: world_x - reduced_radius, y: world_y + reduced_radius),
                RL::Vector2.new(x: world_x + reduced_radius, y: world_y + reduced_radius),
              ]

              # Center must be walkable, and at least 3 out of 5 points should be walkable
              center_walkable = walkable_area.is_point_walkable?(world_pos)
              points_walkable_count = check_points.count { |point| walkable_area.is_point_walkable?(point) }
              is_walkable = center_walkable && points_walkable_count >= 3

              # Count walkable cells
              total_walkable_cells += 1 if is_walkable
              grid.set_walkable(x, y, is_walkable)
            end
          end
        end

        # Mark non-walkable areas from hotspots
        scene.hotspots.each do |hotspot|
          if hotspot.blocks_movement
            grid.set_rect_walkable(
              hotspot.bounds.x.to_i,
              hotspot.bounds.y.to_i,
              hotspot.bounds.width.to_i,
              hotspot.bounds.height.to_i,
              false
            )
          end
        end

        # Mark non-walkable areas from characters
        scene.characters.each do |character|
          next if character.is_a?(Characters::Player) # Don't block player's own path
          grid.set_rect_walkable(
            (character.position.x - character.size.x / 2).to_i,
            (character.position.y - character.size.y / 2).to_i,
            character.size.x.to_i,
            character.size.y.to_i,
            false
          )
        end

        grid
      end

      # Creates a copy of this grid
      def clone : NavigationGrid
        new_grid = NavigationGrid.new(@width, @height, @cell_size)
        @walkable.each_with_index do |row, y|
          row.each_with_index do |walkable, x|
            new_grid.set_walkable(x, y, walkable)
          end
        end
        new_grid
      end

      # String representation for debugging
      def to_s(io : IO) : Nil
        io << "NavigationGrid(#{@width}x#{@height}, cell_size: #{@cell_size}, walkable: #{walkable_percentage.round(1)}%)"
      end
    end
  end
end
