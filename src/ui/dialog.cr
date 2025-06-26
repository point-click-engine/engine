# Dialog system for character conversations

require "yaml"
require "../core/game_object"
require "../core/input_state"

module PointClickEngine
  # # User interface components and systems.
  ##
  # # The `UI` module provides all user interface elements for adventure games,
  # # including dialogs, inventory display, verb interfaces, and HUD elements.
  # # All UI components are designed to work together and respect the game's
  # # visual style and resolution scaling.
  ##
  # # ## Core Components
  ##
  # # - `Dialog` - Conversation boxes with choices
  # # - `FloatingDialog` - Speech bubbles above characters
  # # - `VerbCoin` - Radial verb selection interface
  # # - `StatusBar` - Game state and description display
  # # - `UIManager` - Coordinates all UI elements
  # # - `CursorManager` - Mouse cursor appearances
  ##
  # # ## UI Layering
  ##
  # # UI elements are rendered in this order (back to front):
  # # 1. Game world (scenes, characters)
  # # 2. Status bar
  # # 3. Inventory
  # # 4. Dialogs
  # # 5. Verb coin
  # # 6. Cursor
  ##
  # # ## Resolution Independence
  ##
  # # ```crystal
  # # # UI automatically scales with DisplayManager
  # # dialog = Dialog.new("Hello!", Vector2.new(400, 300), Vector2.new(300, 100))
  # # # Position and size are in game coordinates, not screen pixels
  # # ```
  ##
  # # ## Common Patterns
  ##
  # # ### Modal Dialogs
  # # ```crystal
  # # dialog = Dialog.new("Important message!", pos, size)
  # # dialog.on_complete = -> { engine.resume_game }
  # # engine.pause_game
  # # dialog.show
  # # ```
  ##
  # # ### Choice Dialogs
  # # ```crystal
  # # dialog = Dialog.new("What will you do?", pos, size)
  # # dialog.add_choice("Fight") { start_combat }
  # # dialog.add_choice("Flee") { escape_scene }
  # # dialog.add_choice("Talk") { start_conversation }
  # # dialog.show
  # # ```
  ##
  # # ## See Also
  ##
  # # - `Engine#show_dialog` - High-level dialog API
  # # - `Characters::Character#say` - Character speech
  # # - `DisplayManager` - Resolution scaling
  module UI
    # # Represents a selectable choice in a dialog.
    ##
    # # Dialog choices allow players to make decisions during conversations,
    # # triggering different outcomes based on their selection.
    ##
    # # ## Usage
    ##
    # # ```crystal
    # # choice = DialogChoice.new("I'll help you!", -> {
    # #   player.add_quest("help_villager")
    # #   npc.mood = CharacterMood::Grateful
    # # })
    # # ```
    ##
    # # NOTE: Actions are not serialized - re-register after loading
    struct DialogChoice
      include YAML::Serializable

      # # Display text for this choice
      property text : String

      # # Callback executed when this choice is selected (runtime only)
      @[YAML::Field(ignore: true)]
      property action : Proc(Nil) = -> { }

      # # Creates an empty choice (used for deserialization)
      def initialize
        @text = ""
        @action = -> { }
      end

      # # Creates a choice with text and action.
      ##
      # # - *text* : Text displayed to the player
      # # - *action* : Callback to execute when selected
      def initialize(@text : String, @action : Proc(Nil))
      end
    end

    # # Displays conversation text and player choices.
    ##
    # # The `Dialog` class provides the primary interface for character
    # # conversations, narrative text, and player decision-making. It supports
    # # both simple click-to-continue text and multiple-choice selections.
    ##
    # # ## Features
    ##
    # # - Auto-sizing based on text content
    # # - Multiple choice support with callbacks
    # # - Character name display
    # # - Customizable appearance
    # # - Input handling with click/space to continue
    # # - Resolution-independent positioning
    ##
    # # ## Basic Text Dialog
    ##
    # # ```crystal
    # # # Simple narrative text
    # # dialog = Dialog.new(
    # #   "You enter a dark room. The air is thick with dust.",
    # #   Vector2.new(400, 500),  # Bottom center
    # #   Vector2.new(600, 120)   # Width x Height
    # # )
    # # dialog.show
    ##
    # # # With character name
    # # dialog.character_name = "Guard"
    # # dialog.text = "Halt! Who goes there?"
    # # dialog.show
    # # ```
    ##
    # # ## Choice Dialog
    ##
    # # ```crystal
    # # dialog = Dialog.new("How do you respond?", pos, size)
    ##
    # # dialog.add_choice("Tell the truth") do
    # #   player.add_variable("told_truth", true)
    # #   show_next_dialog("truth_response")
    # # end
    ##
    # # dialog.add_choice("Lie") do
    # #   player.add_variable("told_truth", false)
    # #   show_next_dialog("lie_response")
    # # end
    ##
    # # dialog.add_choice("Say nothing") do
    # #   guard.mood = CharacterMood::Suspicious
    # #   dialog.hide
    # # end
    ##
    # # dialog.show
    # # ```
    ##
    # # ## Chaining Dialogs
    ##
    # # ```crystal
    # # dialog1 = Dialog.new("First message", pos, size)
    # # dialog1.on_complete = -> {
    # #   dialog2 = Dialog.new("Second message", pos, size)
    # #   dialog2.on_complete = -> {
    # #     engine.resume_game
    # #   }
    # #   dialog2.show
    # # }
    # # dialog1.show
    # # ```
    ##
    # # ## Styling
    ##
    # # ```crystal
    # # dialog.background_color = RL::Color.new(r: 20, g: 20, b: 40, a: 240)
    # # dialog.text_color = RL::Color.new(r: 200, g: 200, b: 255, a: 255)
    # # dialog.font_size = 24
    # # dialog.padding = 30.0
    # # ```
    ##
    # # ## Common Gotchas
    ##
    # # 1. **Input delay**: Dialog waits one frame before accepting input
    # #    ```crystal
    # #    dialog.show
    # #    # First frame: dialog appears but ignores input
    # #    # Second frame: input accepted
    # #    ```
    ##
    # # 2. **Choice callbacks aren't saved**: Re-register after loading
    # #    ```crystal
    # #    # After loading a save with dialogs:
    # #    dialog.choices.each_with_index do |choice, i|
    # #      choice.action = get_action_for_choice(i)
    # #    end
    # #    ```
    ##
    # # 3. **Modal behavior**: Dialogs don't pause the game automatically
    # #    ```crystal
    # #    engine.pause_game  # Stop game updates
    # #    dialog.show
    # #    dialog.on_complete = -> { engine.resume_game }
    # #    ```
    ##
    # # ## Input Handling
    ##
    # # - **No choices**: Click or Space to close
    # # - **With choices**: Click on choice or use number keys (1-9)
    # # - Input is consumed to prevent click-through
    ##
    # # ## See Also
    ##
    # # - `FloatingDialog` - Speech bubbles for characters
    # # - `DialogTree` - Complex branching conversations
    # # - `Character#say` - Simplified character speech
    class Dialog
      include YAML::Serializable
      include Core::Drawable

      # # Main dialog text content
      property text : String

      # # Optional character name to display above the text
      property character_name : String?

      # # Available choices for player selection
      property choices : Array(DialogChoice) = [] of DialogChoice

      # # Callback executed when dialog is closed (runtime only)
      @[YAML::Field(ignore: true)]
      property on_complete : Proc(Nil)?

      # # Inner padding between border and text in pixels
      property padding : Float32 = 20.0

      # # Font size for dialog text
      property font_size : Int32 = 20

      # # Background color with alpha for transparency
      @[YAML::Field(converter: PointClickEngine::Utils::YAMLConverters::ColorConverter)]
      property background_color : RL::Color = RL::Color.new(r: 0, g: 0, b: 0, a: 220)

      # # Text color (applies to both dialog text and choices)
      @[YAML::Field(converter: PointClickEngine::Utils::YAMLConverters::ColorConverter)]
      property text_color : RL::Color = RL::WHITE

      # # Whether dialog is ready to accept input (internal flag)
      property ready_to_process_input : Bool = false

      # # Whether this dialog consumed input this frame (prevents click-through)
      @[YAML::Field(ignore: true)]
      property consumed_input : Bool = false

      def initialize
        @text = ""
        @position = RL::Vector2.new
        @size = RL::Vector2.new(x: 300, y: 100)
        @visible = false
        @choices = [] of DialogChoice
      end

      def initialize(@text : String, @position : RL::Vector2, @size : RL::Vector2)
        @visible = false
        @choices = [] of DialogChoice
      end

      # # Adds a choice option to the dialog.
      ##
      # # Choices are displayed in the order they are added. When selected,
      # # the associated action block is executed.
      ##
      # # - *text* : The choice text shown to the player
      # # - *&action* : Block to execute when this choice is selected
      ##
      # # ```crystal
      # # dialog.add_choice("Accept the quest") do
      # #   player.add_quest("main_quest")
      # #   dialog.hide
      # # end
      # # ```
      ##
      # # NOTE: Maximum of 9 choices supported (keyboard shortcuts 1-9)
      def add_choice(text : String, &action : -> Nil)
        @choices << DialogChoice.new(text, action)
      end

      # # Makes the dialog visible and ready for interaction.
      ##
      # # The dialog will wait one frame before accepting input to prevent
      # # accidental dismissal from the click that opened it.
      ##
      # # ```crystal
      # # dialog.show
      # # # Dialog appears but ignores input for one frame
      # # ```
      def show
        @visible = true
        @ready_to_process_input = false
      end

      # # Hides the dialog and triggers the completion callback.
      ##
      # # ```crystal
      # # dialog.on_complete = -> { engine.resume_game }
      # # dialog.hide  # Calls on_complete after hiding
      # # ```
      def hide
        @visible = false
        @on_complete.try &.call
      end

      def update(dt : Float32)
        # Reset consumed input flag each frame
        @consumed_input = false

        return unless @visible
        unless @ready_to_process_input
          @ready_to_process_input = true
          return
        end

        if @choices.empty?
          if Core::InputState.consume_mouse_click || RL::KeyboardKey::Space.pressed?
            @consumed_input = true
            hide
          end
        else
          raw_mouse = RL.get_mouse_position

          # Convert screen coordinates to game coordinates if display manager exists
          mouse_pos = if engine = Core::Engine.instance
                        if dm = engine.display_manager
                          dm.screen_to_game(raw_mouse)
                        else
                          raw_mouse
                        end
                      else
                        raw_mouse
                      end

          if Core::InputState.consume_mouse_click
            @choices.each_with_index do |choice, index|
              choice_rect = get_choice_rect(index)
              if RL.check_collision_point_rec?(mouse_pos, choice_rect)
                @consumed_input = true
                choice.action.call
                hide
                break
              end
            end
          end
        end
      end

      def draw
        return unless @visible
        bg_rect = RL::Rectangle.new(x: @position.x, y: @position.y, width: @size.x, height: @size.y)
        RL.draw_rectangle_rec(bg_rect, @background_color)
        RL.draw_rectangle_lines_ex(bg_rect, 2, RL::WHITE)

        y_offset = @padding
        if char_name = @character_name
          RL.draw_text(char_name, @position.x.to_i + @padding.to_i,
            @position.y.to_i + y_offset.to_i, @font_size + 4, RL::YELLOW)
          y_offset += @font_size + 10
        end

        RL.draw_text(@text, @position.x.to_i + @padding.to_i,
          @position.y.to_i + y_offset.to_i, @font_size, @text_color)

        if !@choices.empty?
          base_choice_y = @position.y + @size.y - (@choices.size * 30) - @padding
          @choices.each_with_index do |choice, index|
            choice_rect = get_choice_rect(index, base_choice_y)
            mouse_pos = RL.get_mouse_position
            color = RL.check_collision_point_rec?(mouse_pos, choice_rect) ? RL::YELLOW : RL::WHITE
            RL.draw_text("> #{choice.text}", choice_rect.x.to_i, choice_rect.y.to_i, @font_size, color)
          end
        end
      end

      private def get_choice_rect(index : Int32, base_y_offset : Float32? = nil) : RL::Rectangle
        y = base_y_offset.nil? ? (@position.y + @size.y - ((@choices.size - index) * 30) - @padding) : (base_y_offset + index * 30)
        RL::Rectangle.new(x: @position.x + @padding, y: y, width: @size.x - @padding * 2, height: 25)
      end
    end
  end
end
