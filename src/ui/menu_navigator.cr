module PointClickEngine
  module UI
    # Manages navigation logic for menu systems
    #
    # The MenuNavigator handles all navigation-related functionality including:
    # - Menu item selection and movement
    # - Wrapping navigation behavior
    # - Enabled item filtering
    # - Navigation state validation
    class MenuNavigator
      # Navigation configuration
      property wrap_navigation : Bool = true
      property skip_disabled_items : Bool = true
      property allow_empty_selection : Bool = false

      # Current navigation state
      property current_index : Int32 = 0
      property previous_index : Int32 = -1
      property total_items : Int32 = 0

      # Item state tracking
      private property enabled_items : Array(Bool) = [] of Bool

      # Callbacks for navigation events
      property on_selection_changed : Proc(Int32, Int32, Nil)?
      property on_wrap_around : Proc(Int32, Nil)?
      property on_invalid_navigation : Proc(Nil)?

      def initialize(@total_items : Int32 = 0)
        @enabled_items = Array.new(@total_items, true)
        validate_current_index
      end

      # Sets the total number of menu items
      def set_total_items(count : Int32)
        @total_items = count
        @enabled_items = Array.new(count, true)
        validate_current_index
      end

      # Sets which items are enabled for navigation
      def set_enabled_items(enabled : Array(Bool))
        @enabled_items = enabled.dup
        @total_items = enabled.size
        validate_current_index
      end

      # Sets enabled state for a specific item
      def set_item_enabled(index : Int32, enabled : Bool)
        return unless valid_index?(index)
        @enabled_items[index] = enabled

        # If current item becomes disabled, move to next enabled item
        if index == @current_index && !enabled
          move_to_next_enabled_item
        end
      end

      # Checks if an item is enabled
      def item_enabled?(index : Int32) : Bool
        return false unless valid_index?(index)
        @enabled_items[index]
      end

      # Navigates to the next item
      def navigate_next : Bool
        return false if @total_items == 0

        old_index = @current_index
        new_index = find_next_enabled_index(@current_index)

        if new_index != @current_index
          set_current_index(new_index)
          return true
        end

        false
      end

      # Navigates to the previous item
      def navigate_previous : Bool
        return false if @total_items == 0

        old_index = @current_index
        new_index = find_previous_enabled_index(@current_index)

        if new_index != @current_index
          set_current_index(new_index)
          return true
        end

        false
      end

      # Navigates to a specific index
      def navigate_to(index : Int32) : Bool
        return false unless valid_index?(index)
        return false if @skip_disabled_items && !item_enabled?(index)

        set_current_index(index)
        true
      end

      # Navigates to the first enabled item
      def navigate_to_first : Bool
        first_enabled = find_first_enabled_index
        return false if first_enabled == -1

        set_current_index(first_enabled)
        true
      end

      # Navigates to the last enabled item
      def navigate_to_last : Bool
        last_enabled = find_last_enabled_index
        return false if last_enabled == -1

        set_current_index(last_enabled)
        true
      end

      # Gets the currently selected index
      def get_selected_index : Int32
        @current_index
      end

      # Gets the previously selected index
      def get_previous_index : Int32
        @previous_index
      end

      # Checks if current selection is valid
      def has_valid_selection? : Bool
        valid_index?(@current_index) && item_enabled?(@current_index)
      end

      # Checks if any items are enabled
      def has_enabled_items? : Bool
        @enabled_items.any? { |enabled| enabled }
      end

      # Gets count of enabled items
      def enabled_item_count : Int32
        @enabled_items.count { |enabled| enabled }
      end

      # Gets list of enabled item indices
      def get_enabled_indices : Array(Int32)
        indices = [] of Int32
        @enabled_items.each_with_index do |enabled, index|
          indices << index if enabled
        end
        indices
      end

      # Finds next enabled item index from given position
      private def find_next_enabled_index(start_index : Int32) : Int32
        return start_index if @total_items == 0

        # Try searching forward from current position
        next_index = start_index
        attempts = 0

        loop do
          next_index = (next_index + 1) % @total_items
          attempts += 1

          # Found enabled item
          if item_enabled?(next_index)
            @on_wrap_around.try(&.call(next_index)) if next_index < start_index && @wrap_navigation
            return next_index
          end

          # Prevent infinite loop
          break if attempts >= @total_items

          # If wrapping is disabled and we've reached the end
          if !@wrap_navigation && next_index == 0
            @on_invalid_navigation.try(&.call)
            return start_index
          end
        end

        # No enabled items found
        @on_invalid_navigation.try(&.call)
        start_index
      end

      # Finds previous enabled item index from given position
      private def find_previous_enabled_index(start_index : Int32) : Int32
        return start_index if @total_items == 0

        # Try searching backward from current position
        prev_index = start_index
        attempts = 0

        loop do
          prev_index = (prev_index - 1 + @total_items) % @total_items
          attempts += 1

          # Found enabled item
          if item_enabled?(prev_index)
            @on_wrap_around.try(&.call(prev_index)) if prev_index > start_index && @wrap_navigation
            return prev_index
          end

          # Prevent infinite loop
          break if attempts >= @total_items

          # If wrapping is disabled and we've reached the beginning
          if !@wrap_navigation && prev_index == @total_items - 1
            @on_invalid_navigation.try(&.call)
            return start_index
          end
        end

        # No enabled items found
        @on_invalid_navigation.try(&.call)
        start_index
      end

      # Finds first enabled item index
      private def find_first_enabled_index : Int32
        @enabled_items.each_with_index do |enabled, index|
          return index if enabled
        end
        -1
      end

      # Finds last enabled item index
      private def find_last_enabled_index : Int32
        @enabled_items.reverse_each.with_index do |enabled, reverse_index|
          return @total_items - 1 - reverse_index if enabled
        end
        -1
      end

      # Moves to next enabled item (used when current becomes disabled)
      private def move_to_next_enabled_item
        next_enabled = find_next_enabled_index(@current_index)
        if next_enabled != @current_index
          set_current_index(next_enabled)
        elsif @allow_empty_selection
          @current_index = -1
        end
      end

      # Sets current index with validation and callbacks
      private def set_current_index(index : Int32)
        return if index == @current_index

        @previous_index = @current_index
        @current_index = index

        @on_selection_changed.try(&.call(@previous_index, @current_index))
      end

      # Validates that an index is within bounds
      private def valid_index?(index : Int32) : Bool
        index >= 0 && index < @total_items
      end

      # Validates current index and fixes if necessary
      private def validate_current_index
        if @total_items == 0
          @current_index = @allow_empty_selection ? -1 : 0
          return
        end

        # If current index is out of bounds, move to first enabled
        unless valid_index?(@current_index)
          first_enabled = find_first_enabled_index
          @current_index = first_enabled != -1 ? first_enabled : 0
          return
        end

        # If current item is disabled, move to next enabled
        if @skip_disabled_items && !item_enabled?(@current_index)
          move_to_next_enabled_item
        end
      end

      # Resets navigation state
      def reset
        @current_index = 0
        @previous_index = -1
        validate_current_index
      end

      # Creates a snapshot of current navigation state
      def create_snapshot : Hash(String, Int32 | Bool | Array(Bool))
        {
          "current_index"         => @current_index,
          "previous_index"        => @previous_index,
          "total_items"           => @total_items,
          "wrap_navigation"       => @wrap_navigation,
          "skip_disabled_items"   => @skip_disabled_items,
          "allow_empty_selection" => @allow_empty_selection,
          "enabled_items"         => @enabled_items.dup,
        }
      end

      # Restores navigation state from snapshot
      def restore_from_snapshot(snapshot : Hash(String, Int32 | Bool | Array(Bool)))
        if current = snapshot["current_index"]?.as?(Int32)
          @current_index = current
        end

        if previous = snapshot["previous_index"]?.as?(Int32)
          @previous_index = previous
        end

        if total = snapshot["total_items"]?.as?(Int32)
          @total_items = total
        end

        if wrap = snapshot["wrap_navigation"]?.as?(Bool)
          @wrap_navigation = wrap
        end

        if skip = snapshot["skip_disabled_items"]?.as?(Bool)
          @skip_disabled_items = skip
        end

        if allow_empty = snapshot["allow_empty_selection"]?.as?(Bool)
          @allow_empty_selection = allow_empty
        end

        if enabled = snapshot["enabled_items"]?.as?(Array(Bool))
          @enabled_items = enabled.dup
        end

        validate_current_index
      end

      # Gets navigation statistics for debugging
      def get_navigation_stats : Hash(String, Int32 | Bool)
        {
          "current_index"       => @current_index,
          "previous_index"      => @previous_index,
          "total_items"         => @total_items,
          "enabled_items"       => enabled_item_count,
          "has_valid_selection" => has_valid_selection?,
          "wrap_navigation"     => @wrap_navigation,
          "skip_disabled"       => @skip_disabled_items,
        }
      end

      # Validates navigation configuration
      def validate_configuration : Array(String)
        issues = [] of String

        if @total_items < 0
          issues << "Total items cannot be negative"
        end

        if @enabled_items.size != @total_items
          issues << "Enabled items array size doesn't match total items"
        end

        if !@allow_empty_selection && !has_enabled_items?
          issues << "No enabled items available and empty selection not allowed"
        end

        if @current_index < -1 || @current_index >= @total_items
          issues << "Current index is out of bounds"
        end

        issues
      end
    end
  end
end
