# Exit zones for scene transitions

require "yaml"
require "./hotspot"

module PointClickEngine
  module Scenes
    # Transition types for scene changes
    enum TransitionType
      Instant
      Fade
      Slide
      Iris
    end

    # Edge exit directions
    enum EdgeExit
      None
      North
      South
      East
      West
    end

    # Special hotspot that triggers scene transitions
    class ExitZone < Hotspot
      property target_scene : String = ""
      property target_position : RL::Vector2?
      property transition_type : TransitionType = TransitionType::Fade
      property auto_walk : Bool = true
      property edge_exit : EdgeExit = EdgeExit::None
      property requires_item : String?
      property locked_message : String?
      property walk_to_position : RL::Vector2?

      # Cursor changes to exit arrow when hovering
      def initialize
        super()
        @cursor_type = CursorType::Use
        @default_verb = UI::VerbType::Walk
        @object_type = UI::ObjectType::Exit
      end

      def initialize(@name : String, position : RL::Vector2, size : RL::Vector2, @target_scene : String)
        super(name, position, size)
        @cursor_type = CursorType::Use
        @description = "Exit to #{@target_scene}"
        @default_verb = UI::VerbType::Walk
        @object_type = UI::ObjectType::Exit
        
        # Set up default click handler for non-verb systems
        @on_click = -> {
          if engine = Core::Engine.instance
            on_click_exit(engine)
          end
        }
      end

      # Check if the exit is accessible
      def is_accessible?(inventory : Inventory::InventorySystem) : Bool
        return true unless item_name = @requires_item
        inventory.has_item?(item_name)
      end

      # Get the position character should walk to before transitioning
      def get_walk_target : RL::Vector2
        if pos = @walk_to_position
          return pos
        end

        # Default to center of exit zone
        RL::Vector2.new(
          x: @position.x + @size.x / 2,
          y: @position.y + @size.y / 2
        )
      end

      # Handle click on exit
      def on_click_exit(engine : Core::Engine)
        return unless engine.current_scene

        # Check if exit is locked
        if !is_accessible?(engine.inventory)
          if msg = @locked_message
            engine.dialog_manager.try &.show_message(msg)
          else
            engine.dialog_manager.try &.show_message("You can't go there yet.")
          end
          return
        end

        # Verb system should handle this
        # This is just a fallback for direct calls
        perform_transition(engine)
      end

      # Perform the actual scene transition
      private def perform_transition(engine : Core::Engine)
        # Map our transition types to graphics transition effects
        effect = case @transition_type
                 when TransitionType::Fade
                   Graphics::TransitionEffect::Fade
                 when TransitionType::Slide
                   # Choose slide direction based on exit position
                   if @position.x < 100
                     Graphics::TransitionEffect::SlideLeft
                   elsif @position.x > 900
                     Graphics::TransitionEffect::SlideRight
                   elsif @position.y < 100
                     Graphics::TransitionEffect::SlideUp
                   else
                     Graphics::TransitionEffect::SlideDown
                   end
                 when TransitionType::Iris
                   Graphics::TransitionEffect::Iris
                 else
                   Graphics::TransitionEffect::Fade
                 end

        # Start the transition
        if tm = engine.transition_manager
          tm.start_transition(effect, 0.5f32) do
            # This runs when transition reaches halfway
            engine.change_scene(@target_scene)

            # Set player position in new scene
            if (pos = @target_position) && (player = engine.player)
              player.position = pos
              player.stop_walking
            end
          end
        else
          # Fallback if no transition manager
          engine.change_scene(@target_scene)
          if (pos = @target_position) && (player = engine.player)
            player.position = pos
            player.stop_walking
          end
        end
      end

      # Draw exit zone with special highlighting
      def draw
        if Core::Engine.debug_mode && @visible
          # Different color for exits
          exit_color = RL::Color.new(r: 0, g: 0, b: 255, a: 100)
          RL.draw_rectangle_rec(bounds, exit_color)

          # Draw target info
          text = "→ #{@target_scene}"
          RL.draw_text(text, @position.x.to_i, @position.y.to_i - 20, 12, RL::WHITE)

          # Draw lock icon if locked
          if @requires_item
            RL.draw_text("🔒", @position.x.to_i, @position.y.to_i, 20, RL::YELLOW)
          end
        end
      end

      # Special handling for edge exits
      def setup_edge_exit(scene_width : Int32, scene_height : Int32)
        case @edge_exit
        when EdgeExit::North
          @position = RL::Vector2.new(x: 0, y: -10)
          @size = RL::Vector2.new(x: scene_width, y: 20)
        when EdgeExit::South
          @position = RL::Vector2.new(x: 0, y: scene_height - 10)
          @size = RL::Vector2.new(x: scene_width, y: 20)
        when EdgeExit::East
          @position = RL::Vector2.new(x: scene_width - 10, y: 0)
          @size = RL::Vector2.new(x: 20, y: scene_height)
        when EdgeExit::West
          @position = RL::Vector2.new(x: -10, y: 0)
          @size = RL::Vector2.new(x: 20, y: scene_height)
        end
      end
    end
  end
end
