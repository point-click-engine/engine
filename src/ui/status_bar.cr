# Status bar for displaying current verb, object, and game information
# Provides visual feedback about player actions and game state

require "raylib-cr"
require "./cursor_manager"
require "../inventory/inventory_system"

module PointClickEngine
  module UI
    # Status bar displaying game information
    class StatusBar
      property visible : Bool = true
      property position : RL::Vector2
      property size : RL::Vector2
      property current_verb : VerbType = VerbType::Walk
      property current_object : String = ""
      property inventory_count : Int32 = 0
      property score : Int32 = 0
      property show_score : Bool = false
      
      # Visual settings
      property background_color : RL::Color = RL::Color.new(r: 20, g: 20, b: 40, a: 220)
      property border_color : RL::Color = RL::Color.new(r: 100, g: 100, b: 150, a: 255)
      property text_color : RL::Color = RL::Color.new(r: 255, g: 255, b: 255, a: 255)
      property highlight_color : RL::Color = RL::Color.new(r: 255, g: 215, b: 0, a: 255)
      
      # Layout settings
      property font_size : Int32 = 16
      property padding : Int32 = 8
      property section_width : Int32 = 150
      
      def initialize(screen_width : Int32, screen_height : Int32)
        @size = RL::Vector2.new(x: screen_width.to_f32, y: 30.to_f32)
        @position = RL::Vector2.new(x: 0.to_f32, y: (screen_height - @size.y).to_f32)
      end
      
      # Update status bar with current game state
      def update(cursor_manager : CursorManager, inventory : Inventory::InventorySystem? = nil)
        return unless @visible
        
        # Get current verb from cursor manager
        @current_verb = cursor_manager.get_current_action
        
        # Get current object from hotspot
        if hotspot = cursor_manager.current_hotspot
          @current_object = hotspot.name
        else
          @current_object = ""
        end
        
        # Update inventory count
        if inv = inventory
          @inventory_count = inv.items.size
        else
          @inventory_count = 0
        end
      end
      
      # Update with manual values (for custom states)
      def update_manual(verb : VerbType, object : String, inv_count : Int32 = 0, score : Int32 = 0)
        @current_verb = verb
        @current_object = object
        @inventory_count = inv_count
        @score = score
      end
      
      # Draw the status bar
      def draw
        return unless @visible
        
        # Draw background
        draw_background
        
        # Draw sections
        draw_verb_section
        draw_object_section  
        draw_inventory_section
        
        if @show_score
          draw_score_section
        end
      end
      
      # Draw status bar background
      private def draw_background
        # Main background
        RL.draw_rectangle(
          @position.x.to_i,
          @position.y.to_i,
          @size.x.to_i,
          @size.y.to_i,
          @background_color
        )
        
        # Top border
        RL.draw_line(
          @position.x.to_i,
          @position.y.to_i,
          (@position.x + @size.x).to_i,
          @position.y.to_i,
          @border_color
        )
      end
      
      # Draw current verb section
      private def draw_verb_section
        x = @position.x + @padding
        y = @position.y + (@size.y - @font_size) / 2
        
        verb_text = get_verb_text(@current_verb)
        RL.draw_text("Action: #{verb_text}", x.to_i, y.to_i, @font_size, @highlight_color)
      end
      
      # Draw current object section
      private def draw_object_section
        x = @position.x + @padding + @section_width
        y = @position.y + (@size.y - @font_size) / 2
        
        object_text = @current_object.empty? ? "Nothing" : @current_object
        # Truncate long object names
        if object_text.size > 15
          object_text = object_text[0, 12] + "..."
        end
        
        color = @current_object.empty? ? @text_color : @highlight_color
        RL.draw_text("Target: #{object_text}", x.to_i, y.to_i, @font_size, color)
      end
      
      # Draw inventory count section
      private def draw_inventory_section
        x = @position.x + @padding + @section_width * 2
        y = @position.y + (@size.y - @font_size) / 2
        
        inv_text = "Items: #{@inventory_count}"
        RL.draw_text(inv_text, x.to_i, y.to_i, @font_size, @text_color)
      end
      
      # Draw score section (if enabled)
      private def draw_score_section
        x = @position.x + @padding + @section_width * 3
        y = @position.y + (@size.y - @font_size) / 2
        
        score_text = "Score: #{@score}"
        RL.draw_text(score_text, x.to_i, y.to_i, @font_size, @text_color)
      end
      
      # Get display text for verb
      private def get_verb_text(verb : VerbType) : String
        case verb
        when .walk? then "Walk"
        when .look? then "Look"
        when .talk? then "Talk"
        when .use? then "Use"
        when .take? then "Take"
        when .open? then "Open"
        when .close? then "Close"
        when .push? then "Push"
        when .pull? then "Pull"
        when .give? then "Give"
        else "Unknown"
        end
      end
      
      # Set status bar position
      def set_position(x : Float32, y : Float32)
        @position = RL::Vector2.new(x: x, y: y)
      end
      
      # Set status bar size
      def set_size(width : Float32, height : Float32)
        @size = RL::Vector2.new(x: width, y: height)
      end
      
      # Toggle visibility
      def toggle_visibility
        @visible = !@visible
      end
      
      # Show status bar
      def show
        @visible = true
      end
      
      # Hide status bar
      def hide
        @visible = false
      end
      
      # Enable/disable score display
      def enable_score(enabled : Bool)
        @show_score = enabled
      end
      
      # Set current score
      def set_score(score : Int32)
        @score = score
      end
      
      # Get status bar height for layout calculations
      def get_height : Float32
        @size.y
      end
      
      # Check if position is within status bar bounds
      def contains_point(point : RL::Vector2) : Bool
        point.x >= @position.x &&
        point.x <= @position.x + @size.x &&
        point.y >= @position.y &&
        point.y <= @position.y + @size.y
      end
    end
  end
end