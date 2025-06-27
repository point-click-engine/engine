require "./hotspot"

module PointClickEngine
  module Scenes
    # Manages hotspots and their interactions within a scene
    #
    # The HotspotManager handles all hotspot-related functionality including:
    # - Hotspot collection management
    # - Position-based hotspot detection
    # - Hotspot-object relationship management
    # - Interaction coordination
    class HotspotManager
      # Collection of hotspots in the scene
      property hotspots : Array(Hotspot) = [] of Hotspot

      # Cache for fast position-based lookups
      @position_cache : Hash(String, Hotspot) = {} of String => Hotspot

      # Whether to use spatial optimization for large numbers of hotspots
      property use_spatial_optimization : Bool = false

      # Grid size for spatial partitioning (when enabled)
      property spatial_grid_size : Int32 = 100

      # Spatial grid for optimized position queries
      @spatial_grid : Hash(String, Array(Hotspot)) = {} of String => Array(Hotspot)

      def initialize
      end

      # Adds a hotspot to the collection
      #
      # - *hotspot* : The hotspot to add
      def add_hotspot(hotspot : Hotspot)
        return if @hotspots.includes?(hotspot)

        @hotspots << hotspot
        update_spatial_cache(hotspot) if @use_spatial_optimization
        invalidate_position_cache
      end

      # Removes a hotspot from the collection
      #
      # - *hotspot* : The hotspot to remove
      def remove_hotspot(hotspot : Hotspot)
        @hotspots.delete(hotspot)
        remove_from_spatial_cache(hotspot) if @use_spatial_optimization
        invalidate_position_cache
      end

      # Removes a hotspot by name
      #
      # - *name* : Name of the hotspot to remove
      def remove_hotspot_by_name(name : String)
        hotspot = get_hotspot_by_name(name)
        remove_hotspot(hotspot) if hotspot
      end

      # Gets a hotspot by name
      #
      # - *name* : Name of the hotspot to find
      #
      # Returns: The hotspot with the given name, or nil if not found
      def get_hotspot_by_name(name : String) : Hotspot?
        @hotspots.find { |h| h.name == name }
      end

      # Finds the topmost hotspot at a specific position
      #
      # Searches through all hotspots to find the one with the highest
      # z-order (drawn last) that contains the given point.
      #
      # - *position* : The position to check
      #
      # Returns: The topmost hotspot at the position, or nil if none found
      def get_hotspot_at(position : RL::Vector2) : Hotspot?
        if @use_spatial_optimization
          get_hotspot_at_optimized(position)
        else
          get_hotspot_at_linear(position)
        end
      end

      # Gets all hotspots at a specific position
      #
      # Returns all hotspots that contain the given point, ordered by z-order.
      #
      # - *position* : The position to check
      #
      # Returns: Array of hotspots at the position
      def get_hotspots_at(position : RL::Vector2) : Array(Hotspot)
        if @use_spatial_optimization
          get_hotspots_at_optimized(position)
        else
          get_hotspots_at_linear(position)
        end
      end

      # Checks if any hotspot exists at the given position
      #
      # - *position* : The position to check
      #
      # Returns: true if any hotspot contains the position
      def has_hotspot_at?(position : RL::Vector2) : Bool
        get_hotspot_at(position) != nil
      end

      # Gets all hotspots in the collection
      def all_hotspots : Array(Hotspot)
        @hotspots.dup
      end

      # Gets count of hotspots
      def hotspot_count : Int32
        @hotspots.size
      end

      # Clears all hotspots
      def clear_hotspots
        @hotspots.clear
        @position_cache.clear
        @spatial_grid.clear
      end

      # Finds hotspots within a rectangular area
      #
      # - *area* : The rectangular area to search within
      #
      # Returns: Array of hotspots that intersect with the area
      def get_hotspots_in_area(area : RL::Rectangle) : Array(Hotspot)
        @hotspots.select { |hotspot| hotspot.intersects_rectangle?(area) }
      end

      # Finds hotspots within a circular area
      #
      # - *center* : Center point of the circle
      # - *radius* : Radius of the circle
      #
      # Returns: Array of hotspots within the circular area
      def get_hotspots_in_radius(center : RL::Vector2, radius : Float32) : Array(Hotspot)
        @hotspots.select { |hotspot| hotspot.distance_to_point(center) <= radius }
      end

      # Sorts hotspots by their z-order (drawing order)
      def sort_hotspots_by_depth
        @hotspots.sort! { |a, b| a.z_order <=> b.z_order }
      end

      # Validates all hotspots for consistency
      #
      # Checks for overlapping hotspots, invalid dimensions, etc.
      #
      # Returns: Array of validation issues found
      def validate_hotspots : Array(String)
        issues = [] of String

        @hotspots.each do |hotspot|
          # Check for invalid dimensions
          if hotspot.width <= 0 || hotspot.height <= 0
            issues << "Hotspot '#{hotspot.name}' has invalid dimensions: #{hotspot.width}x#{hotspot.height}"
          end

          # Check for negative positions (might be valid in some cases)
          if hotspot.x < 0 || hotspot.y < 0
            issues << "Hotspot '#{hotspot.name}' has negative position: (#{hotspot.x}, #{hotspot.y})"
          end

          # Check for duplicate names
          duplicates = @hotspots.select { |h| h.name == hotspot.name }
          if duplicates.size > 1
            issues << "Duplicate hotspot name found: '#{hotspot.name}'"
          end
        end

        issues
      end

      # Enables spatial optimization for better performance with many hotspots
      def enable_spatial_optimization(grid_size : Int32 = 100)
        @use_spatial_optimization = true
        @spatial_grid_size = grid_size
        rebuild_spatial_cache
      end

      # Disables spatial optimization
      def disable_spatial_optimization
        @use_spatial_optimization = false
        @spatial_grid.clear
      end

      # Updates hotspot positions and refreshes spatial cache
      def update_hotspot_positions
        if @use_spatial_optimization
          rebuild_spatial_cache
        end
        invalidate_position_cache
      end

      # Gets hotspot statistics for debugging
      def get_statistics : Hash(String, Int32 | Float32)
        return {} of String => Int32 | Float32 if @hotspots.empty?

        total_area = @hotspots.sum { |h| h.width * h.height }
        avg_area = total_area.to_f32 / @hotspots.size

        overlapping_count = 0
        @hotspots.each_with_index do |hotspot, i|
          @hotspots[i + 1..-1].each do |other|
            if hotspot.overlaps_with?(other)
              overlapping_count += 1
            end
          end
        end

        {
          "total_hotspots"       => @hotspots.size,
          "total_area"           => total_area,
          "average_area"         => avg_area,
          "overlapping_pairs"    => overlapping_count,
          "spatial_optimization" => @use_spatial_optimization ? 1 : 0,
        }
      end

      # Exports hotspot data for external tools
      def export_hotspots : Array(Hash(String, String | Int32 | Float32))
        @hotspots.map do |hotspot|
          {
            "name"        => hotspot.name,
            "x"           => hotspot.x,
            "y"           => hotspot.y,
            "width"       => hotspot.width,
            "height"      => hotspot.height,
            "z_order"     => hotspot.z_order,
            "description" => hotspot.description,
          }
        end
      end

      # Imports hotspot data from external source
      def import_hotspots(data : Array(Hash(String, String | Int32 | Float32)))
        data.each do |hotspot_data|
          hotspot = Hotspot.new(
            name: hotspot_data["name"].as(String),
            x: hotspot_data["x"].as(Int32),
            y: hotspot_data["y"].as(Int32),
            width: hotspot_data["width"].as(Int32),
            height: hotspot_data["height"].as(Int32)
          )

          if z_order = hotspot_data["z_order"]?
            hotspot.z_order = z_order.as(Int32)
          end

          if description = hotspot_data["description"]?
            hotspot.description = description.as(String)
          end

          add_hotspot(hotspot)
        end
      end

      # Linear search implementation (fallback for small numbers of hotspots)
      private def get_hotspot_at_linear(position : RL::Vector2) : Hotspot?
        # Search in reverse order to get topmost hotspot
        @hotspots.reverse_each do |hotspot|
          return hotspot if hotspot.visible && hotspot.contains_point?(position)
        end
        nil
      end

      # Linear search for all hotspots at position
      private def get_hotspots_at_linear(position : RL::Vector2) : Array(Hotspot)
        @hotspots.select { |hotspot| hotspot.visible && hotspot.contains_point?(position) }
      end

      # Optimized search using spatial partitioning
      private def get_hotspot_at_optimized(position : RL::Vector2) : Hotspot?
        # Check all grid cells that might contain hotspots overlapping this position
        # We need to check neighboring cells too, as hotspots can span multiple cells
        grid_x = (position.x / @spatial_grid_size).to_i
        grid_y = (position.y / @spatial_grid_size).to_i

        checked_hotspots = Set(Hotspot).new
        result : Hotspot? = nil

        # Debug output
        # puts "Looking for hotspot at position #{position}, grid cell (#{grid_x}, #{grid_y})"
        # puts "Spatial grid has #{@spatial_grid.size} cells"

        # Check a 3x3 grid around the position to catch hotspots that span cells
        (-1..1).each do |dx|
          (-1..1).each do |dy|
            check_x = grid_x + dx
            check_y = grid_y + dy
            grid_key = get_grid_key((check_x * @spatial_grid_size).to_i, (check_y * @spatial_grid_size).to_i)

            candidates = @spatial_grid[grid_key]?
            # puts "  Checking grid cell #{grid_key}: #{candidates.try(&.size) || 0} candidates"
            next unless candidates

            candidates.each do |hotspot|
              next if checked_hotspots.includes?(hotspot)
              checked_hotspots << hotspot

              if hotspot.visible && hotspot.contains_point?(position)
                # Keep the topmost (highest z-order or last added if same z-order)
                if result.nil? || hotspot.z_order > result.z_order
                  result = hotspot
                elsif hotspot.z_order == result.z_order
                  # If same z-order, prefer the one added later (higher in array)
                  result = hotspot if @hotspots.index(hotspot).try { |i| i > (@hotspots.index(result) || -1) }
                end
              end
            end
          end
        end

        result
      end

      # Optimized search for all hotspots at position
      private def get_hotspots_at_optimized(position : RL::Vector2) : Array(Hotspot)
        # Check all grid cells that might contain hotspots overlapping this position
        grid_x = (position.x / @spatial_grid_size).to_i
        grid_y = (position.y / @spatial_grid_size).to_i

        checked_hotspots = Set(Hotspot).new
        results = [] of Hotspot

        # Check a 3x3 grid around the position to catch hotspots that span cells
        (-1..1).each do |dx|
          (-1..1).each do |dy|
            check_x = grid_x + dx
            check_y = grid_y + dy
            grid_key = get_grid_key((check_x * @spatial_grid_size).to_i, (check_y * @spatial_grid_size).to_i)

            candidates = @spatial_grid[grid_key]?
            next unless candidates

            candidates.each do |hotspot|
              next if checked_hotspots.includes?(hotspot)
              checked_hotspots << hotspot

              if hotspot.visible && hotspot.contains_point?(position)
                results << hotspot
              end
            end
          end
        end

        results
      end

      # Updates spatial cache for a specific hotspot
      private def update_spatial_cache(hotspot : Hotspot)
        # Remove from old grid cells first
        remove_from_spatial_cache(hotspot)

        # Add to grid cells that this hotspot overlaps
        grid_cells = get_overlapping_grid_cells(hotspot)
        grid_cells.each do |cell_key|
          @spatial_grid[cell_key] ||= [] of Hotspot
          @spatial_grid[cell_key] << hotspot
        end
      end

      # Removes hotspot from spatial cache
      private def remove_from_spatial_cache(hotspot : Hotspot)
        @spatial_grid.each do |key, hotspots|
          hotspots.delete(hotspot)
        end
      end

      # Rebuilds the entire spatial cache
      private def rebuild_spatial_cache
        @spatial_grid.clear
        @hotspots.each { |hotspot| update_spatial_cache(hotspot) }
      end

      # Gets grid cells that a hotspot overlaps
      private def get_overlapping_grid_cells(hotspot : Hotspot) : Array(String)
        cells = [] of String

        # Get the actual bounds of the hotspot (GameObject uses center-based positioning)
        bounds = hotspot.bounds

        start_x = (bounds.x.to_i / @spatial_grid_size).to_i
        end_x = ((bounds.x + bounds.width).to_i / @spatial_grid_size).to_i
        start_y = (bounds.y.to_i / @spatial_grid_size).to_i
        end_y = ((bounds.y + bounds.height).to_i / @spatial_grid_size).to_i

        (start_x..end_x).each do |x|
          (start_y..end_y).each do |y|
            cells << get_grid_key((x * @spatial_grid_size).to_i, (y * @spatial_grid_size).to_i)
          end
        end

        cells
      end

      # Generates grid key for spatial partitioning
      private def get_grid_key(x : Int32, y : Int32) : String
        grid_x = x / @spatial_grid_size
        grid_y = y / @spatial_grid_size
        "#{grid_x},#{grid_y}"
      end

      # Invalidates position cache
      private def invalidate_position_cache
        @position_cache.clear
      end
    end
  end
end
