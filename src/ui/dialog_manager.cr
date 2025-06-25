require "./dialog"
require "./dialog_portrait"
require "./floating_dialog"
require "./floating_text"
require "../characters/dialogue/dialog_tree"

module PointClickEngine
  module UI
    class DialogManager
      property current_dialog : Dialog?
      property dialog_queue : Array(Dialog) = [] of Dialog
      property message_display_time : Float32 = 3.0f32
      property portrait_manager : PortraitManager
      property floating_manager : FloatingDialogManager
      property enable_portraits : Bool = false
      property enable_floating : Bool = true
      property dialog_trees : Hash(String, Characters::Dialogue::DialogTree) = {} of String => Characters::Dialogue::DialogTree

      def initialize
        @current_dialog = nil
        @message_timer = 0.0f32
        @showing_message = false
        @portrait_manager = PortraitManager.new
        @floating_manager = FloatingDialogManager.new
        @consumed_input_this_frame = false
      end

      def show_dialog(character_name : String, text : String, choices : Array(DialogChoice)? = nil, expression : PortraitExpression = PortraitExpression::Neutral)
        pos = Raylib::Vector2.new(x: 100f32, y: 400f32)
        size = Raylib::Vector2.new(x: 824f32, y: 200f32)

        dialog = Dialog.new(text, pos, size)
        dialog.character_name = character_name
        dialog.choices = choices if choices
        dialog.visible = true

        @current_dialog = dialog

        # Show portrait if enabled and character name is provided
        if @enable_portraits && !character_name.empty?
          @portrait_manager.show_portrait(character_name, expression)
          @portrait_manager.start_talking
        end
      end

      # Show floating dialog above character position
      def show_floating_dialog(character_name : String, text : String, character_pos : RL::Vector2,
                               duration : Float32? = nil, style : DialogStyle = DialogStyle::Bubble, color : RL::Color? = nil)
        return unless @enable_floating
        @floating_manager.show_dialog(character_name, text, character_pos, duration, style, color)
      end

      # Show floating dialog for character (convenience method)
      def show_character_dialog(character_name : String, text : String, character_pos : RL::Vector2,
                                style : DialogStyle = DialogStyle::Bubble)
        if @enable_floating
          @floating_manager.show_dialog(character_name, text, character_pos, nil, style)
        elsif @enable_portraits
          show_dialog(character_name, text)
        end
      end

      def show_message(text : String, duration : Float32 = 3.0f32)
        if @enable_floating
          # Try to show message as floating text near player
          begin
            if engine = Core::Engine.instance
              if player = engine.player
                @floating_manager.show_dialog("", text, player.position, duration, DialogStyle::Rectangle)
                return
              end
            end
          rescue
            # Engine not initialized, fall through to regular dialog
          end
        end

        # Fallback to regular dialog
        show_dialog("", text)
        @showing_message = true
        @message_timer = duration
      end

      def show_choice(prompt : String, options : Array(String), callback : Proc(Int32, Nil))
        choices = options.map_with_index do |option, index|
          DialogChoice.new(option, -> {
            callback.call(index + 1)
            close_current_dialog
          })
        end

        show_dialog("", prompt, choices)
      end

      # Show dialog choices at bottom of screen
      #
      # Displays a dialog box with multiple choices at the bottom of the screen.
      # This is useful for branching conversations and interactive dialogs.
      #
      # *prompt* - The question or prompt to display
      # *choices* - Array of choice texts
      # *callback* - Proc called with the index of the selected choice
      # *position* - Optional position override (defaults to bottom of screen)
      # *size* - Optional size override (defaults to wide dialog box)
      #
      # ```
      # dialog_manager.show_dialog_choices(
      #   "What would you like to ask?",
      #   ["Tell me about the crystal", "Who else is here?", "Goodbye"],
      #   ->(choice : Int32) {
      #     case choice
      #     when 0 then show_crystal_info
      #     when 1 then show_character_list
      #     when 2 then end_conversation
      #     end
      #   }
      # )
      # ```
      def show_dialog_choices(prompt : String, choices : Array(String), &callback : Int32 ->)
        # Use game reference dimensions, not screen dimensions
        # Dialogs are rendered in game space which uses reference resolution
        window_width = 1024f32 # Reference width
        window_height = 768f32 # Reference height

        # Create dialog at bottom of screen
        dialog_height = 150f32 + (choices.size * 30f32)
        dialog_y = window_height - dialog_height - 20

        dialog = Dialog.new(
          prompt,
          Raylib::Vector2.new(x: 20f32, y: dialog_y),
          Raylib::Vector2.new(x: window_width - 40f32, y: dialog_height)
        )

        # Set black background for dialog choices
        dialog.background_color = Raylib::Color.new(r: 0, g: 0, b: 0, a: 240)
        dialog.text_color = Raylib::WHITE

        # Add choices
        choices.each_with_index do |choice_text, index|
          dialog.add_choice(choice_text) do
            callback.call(index)
            # Don't close dialog here - let the callback handle it or replace it
          end
        end

        dialog.show
        @current_dialog = dialog
      end

      # Show dialog choices with custom positioning
      def show_dialog_choices_at(prompt : String, choices : Array(String), position : RL::Vector2, size : RL::Vector2, &callback : Int32 ->)
        dialog = Dialog.new(prompt, position, size)

        # Add choices
        choices.each_with_index do |choice_text, index|
          dialog.add_choice(choice_text) do
            callback.call(index)
            # Don't close dialog here - let the callback handle it or replace it
          end
        end

        dialog.show
        @current_dialog = dialog
      end

      def update(dt : Float32)
        # Reset consumed input flag at start of frame
        @consumed_input_this_frame = false

        if @showing_message && @message_timer > 0
          @message_timer -= dt
          if @message_timer <= 0
            close_current_dialog
            @showing_message = false
          end
        end

        # Check if dialog will consume input before updating
        if dialog = @current_dialog
          if dialog.visible && dialog.ready_to_process_input && RL.mouse_button_pressed?(RL::MouseButton::Left)
            @consumed_input_this_frame = true
          end
        end

        @current_dialog.try &.update(dt)
        @portrait_manager.update(dt)
        @floating_manager.update(dt)
      end

      def draw
        @current_dialog.try &.draw
        @portrait_manager.draw if @enable_portraits
        @floating_manager.draw if @enable_floating
      end

      def close_current_dialog
        @current_dialog = nil
        @portrait_manager.stop_talking
        @portrait_manager.hide_portrait
      end

      # Show floating text at a specific position
      def show_floating_text(text : String, position : RL::Vector2,
                             color : RL::Color = RL::WHITE,
                             duration : Float32 = 3.0)
        # Show as floating dialog with no character name
        @floating_manager.show_dialog("", text, position, duration, DialogStyle::Rectangle, color)
      end

      # Add a character portrait
      def add_character_portrait(character_name : String, texture_path : String) : DialogPortrait
        @portrait_manager.add_portrait(character_name, texture_path)
      end

      # Set expression for current speaker
      def set_speaker_expression(expression : PortraitExpression)
        @portrait_manager.set_expression(expression)
      end

      # Configure portrait positioning
      def set_portrait_position(position : PortraitPosition)
        @portrait_manager.default_position = position
      end

      # Toggle portrait system
      def toggle_portraits(enabled : Bool)
        @enable_portraits = enabled
        if !enabled
          @portrait_manager.hide_portrait
        end
      end

      # Cleanup resources
      def cleanup
        @portrait_manager.cleanup
      end

      def is_dialog_active? : Bool
        if dialog = @current_dialog
          return dialog.visible
        end
        false
      end

      def dialog_consumed_input? : Bool
        # Only consider input consumed if we have an actual interactive dialog
        # Floating dialogs should not block input since they're just visual
        if current_dialog = @current_dialog
          # This is an interactive dialog that should consume input
          current_dialog.consumed_input
        else
          # No interactive dialog active, don't consume input
          false
        end
      end

      # Add a dialog tree
      def add_dialog_tree(dialog_tree : Characters::Dialogue::DialogTree)
        @dialog_trees[dialog_tree.name] = dialog_tree
      end

      # Get a dialog tree by name
      def get_dialog_tree(name : String) : Characters::Dialogue::DialogTree?
        @dialog_trees[name]?
      end

      # Start a conversation with a dialog tree
      def start_dialog_tree(tree_name : String, starting_node : String = "greeting")
        if tree = get_dialog_tree(tree_name)
          tree.start_conversation(starting_node)
        end
      end
    end
  end
end
