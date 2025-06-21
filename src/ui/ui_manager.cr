# UI Manager for coordinating verb coin, status bar, and other UI elements
# Provides unified interface management for Simon the Sorcerer 1 style interactions

require "raylib-cr"
require "./verb_coin"
require "./status_bar"
require "./cursor_manager"
require "../scenes/scene"
require "../inventory/inventory_system"

module PointClickEngine
  module UI
    # Manages all UI components and their interactions
    class UIManager
      property verb_coin : VerbCoin
      property status_bar : StatusBar
      property cursor_manager : CursorManager
      property current_verb : VerbType = VerbType::Walk
      property verb_coin_enabled : Bool = true
      property status_bar_enabled : Bool = true

      # Input state
      property right_click_time : Float32 = 0.0f32
      property right_click_threshold : Float32 = 0.1f32
      property last_hotspot : Scenes::Hotspot?

      def initialize(screen_width : Int32, screen_height : Int32)
        @verb_coin = VerbCoin.new
        @status_bar = StatusBar.new(screen_width, screen_height)
        @cursor_manager = CursorManager.new
      end

      # Update all UI components
      def update(dt : Float32, scene : Scenes::Scene, inventory : Inventory::InventorySystem? = nil)
        # Get mouse position and convert to game coordinates if needed
        mouse_pos = Raylib.get_mouse_position

        # Update cursor manager first
        @cursor_manager.update(mouse_pos, scene, inventory)

        # Handle right-click for verb coin
        handle_verb_coin_input(mouse_pos, scene)

        # Update verb coin if active
        @verb_coin.update(dt)

        # Update status bar with current state
        if @status_bar_enabled
          @status_bar.update(@cursor_manager, inventory)
        end

        # Update current verb from verb coin selection or cursor manager
        if @verb_coin.is_active?
          if selected = @verb_coin.get_selected_verb
            @current_verb = selected
          end
        else
          @current_verb = @cursor_manager.get_current_action
        end
      end

      # Handle verb coin input logic
      private def handle_verb_coin_input(mouse_pos : RL::Vector2, scene : Scenes::Scene)
        return unless @verb_coin_enabled

        # Check for right mouse button press
        if Raylib.mouse_button_pressed?(Raylib::MouseButton::Right.to_i)
          @right_click_time = 0.0f32
          show_verb_coin_for_position(mouse_pos, scene)
        end

        # Track right-click duration
        if Raylib.mouse_button_down?(Raylib::MouseButton::Right.to_i)
          @right_click_time += Raylib.get_frame_time
        end

        # Hide verb coin on right-click release if it was a quick click
        if Raylib.mouse_button_released?(Raylib::MouseButton::Right.to_i)
          if @right_click_time < @right_click_threshold && @verb_coin.is_active?
            @verb_coin.hide
          end
        end
      end

      # Show verb coin with appropriate verbs for the position
      private def show_verb_coin_for_position(pos : RL::Vector2, scene : Scenes::Scene)
        # Get hotspot at position
        hotspot = scene.get_hotspot_at(pos)

        # Determine applicable verbs
        applicable_verbs = get_applicable_verbs(hotspot)

        # Show verb coin
        @verb_coin.show(pos, applicable_verbs)
      end

      # Get verbs applicable to a hotspot
      private def get_applicable_verbs(hotspot : Scenes::Hotspot?) : Array(VerbType)
        if hotspot.nil?
          # Background - only walk and look
          return [VerbType::Walk, VerbType::Look]
        end

        verbs = [] of VerbType

        # Always available
        verbs << VerbType::Look
        verbs << VerbType::Walk

        # Check object type or properties for specific verbs
        if hotspot.responds_to?(:object_type)
          case hotspot.object_type
          when .item?
            verbs << VerbType::Take
            verbs << VerbType::Use
          when .character?
            verbs << VerbType::Talk
            verbs << VerbType::Give
          when .door?
            verbs << VerbType::Open
            verbs << VerbType::Close
            verbs << VerbType::Use
          when .container?
            verbs << VerbType::Open
            verbs << VerbType::Close
          when .device?
            verbs << VerbType::Use
            verbs << VerbType::Push
            verbs << VerbType::Pull
          when .exit?
            # Already has walk and look
          end
        else
          # Smart detection based on name/description
          verbs.concat(detect_verbs_from_hotspot(hotspot))
        end

        # Remove duplicates and return
        verbs.uniq
      end

      # Detect applicable verbs from hotspot properties
      private def detect_verbs_from_hotspot(hotspot : Scenes::Hotspot) : Array(VerbType)
        verbs = [] of VerbType
        name = hotspot.name.downcase
        desc = hotspot.description.downcase

        # Character-like objects
        if name.includes?("butler") || name.includes?("guard") ||
           desc.includes?("person") || desc.includes?("character")
          verbs << VerbType::Talk
          verbs << VerbType::Give
        end

        # Doors and openable objects
        if name.includes?("door") || name.includes?("chest") ||
           name.includes?("cabinet") || desc.includes?("open")
          verbs << VerbType::Open
          verbs << VerbType::Close
        end

        # Takeable items
        if name.includes?("key") || name.includes?("book") ||
           name.includes?("crystal") || desc.includes?("pick up")
          verbs << VerbType::Take
        end

        # Useable objects
        if name.includes?("lever") || name.includes?("button") ||
           name.includes?("switch") || desc.includes?("use")
          verbs << VerbType::Use
        end

        # Pushable/pullable objects
        if name.includes?("statue") || name.includes?("block") ||
           desc.includes?("push") || desc.includes?("pull")
          verbs << VerbType::Push
          verbs << VerbType::Pull
        end

        verbs
      end

      # Draw all UI components
      def draw
        # Draw status bar (behind other UI elements)
        if @status_bar_enabled
          @status_bar.draw
        end

        # Draw verb coin (on top of everything else)
        if @verb_coin_enabled
          @verb_coin.draw
        end

        # Draw cursor (always on top)
        mouse_pos = Raylib.get_mouse_position
        @cursor_manager.draw(mouse_pos)
      end

      # Handle left-click interactions
      def handle_left_click(pos : RL::Vector2, scene : Scenes::Scene) : Bool
        # If verb coin is active, use selected verb and hide coin
        if @verb_coin.is_active?
          if selected_verb = @verb_coin.get_selected_verb
            @current_verb = selected_verb
            @verb_coin.hide
            return perform_action(pos, scene, selected_verb)
          end
        end

        # Otherwise use current cursor verb
        perform_action(pos, scene, @current_verb)
      end

      # Perform action with selected verb
      private def perform_action(pos : RL::Vector2, scene : Scenes::Scene, verb : VerbType) : Bool
        hotspot = scene.get_hotspot_at(pos)

        if hotspot
          # Trigger hotspot action if it has one
          hotspot.on_click.try(&.call)
          return true
        else
          # Handle background click (usually walk)
          if verb == VerbType::Walk
            # This would trigger character movement to position
            # Implementation depends on character system
            return true
          end
        end

        false
      end

      # Get current action text for display
      def get_current_action_text : String
        if hotspot = @cursor_manager.current_hotspot
          verb_desc = @verb_coin.get_verb_description(@current_verb)
          "#{verb_desc} #{hotspot.name}"
        else
          @verb_coin.get_verb_description(@current_verb)
        end
      end

      # Enable/disable verb coin
      def enable_verb_coin(enabled : Bool)
        @verb_coin_enabled = enabled
        if !enabled
          @verb_coin.hide
        end
      end

      # Enable/disable status bar
      def enable_status_bar(enabled : Bool)
        @status_bar_enabled = enabled
      end

      # Set current verb manually
      def set_current_verb(verb : VerbType)
        @current_verb = verb
      end

      # Get current verb
      def get_current_verb : VerbType
        @current_verb
      end

      # Check if verb coin is currently active
      def is_verb_coin_active? : Bool
        @verb_coin.is_active?
      end

      # Force hide verb coin
      def hide_verb_coin
        @verb_coin.hide
      end

      # Update status bar score
      def set_score(score : Int32)
        @status_bar.set_score(score)
      end

      # Enable score display
      def enable_score_display(enabled : Bool)
        @status_bar.enable_score(enabled)
      end

      # Cleanup resources
      def cleanup
        @cursor_manager.cleanup
      end
    end
  end
end
