# Hotspot implementation for interactive areas

require "yaml"
require "../utils/yaml_converters"
require "../ui/cursor_manager"

module PointClickEngine
  module Scenes
    # # Represents an interactive area or object within a scene.
    ##
    # # Hotspots are the primary way players interact with the game world. They define
    # # clickable regions that respond to different verbs (look, use, talk, etc.) and
    # # can represent doors, items, furniture, characters, or any interactive element.
    ##
    # # ## Architecture
    ##
    # # Hotspots inherit from `GameObject` and add:
    # # - Cursor feedback system for hover states
    # # - Verb-based interaction routing
    # # - Optional movement blocking for obstacles
    # # - Script integration for complex behaviors
    # # - Debug visualization in development mode
    ##
    # # ## Basic Usage
    ##
    # # ```crystal
    # # # Create a simple door hotspot
    # # door = Hotspot.new("door", Vector2.new(400, 200), Vector2.new(80, 150))
    # # door.description = "A sturdy wooden door"
    # # door.cursor_type = Hotspot::CursorType::Use
    ##
    # # # Add click handler
    # # door.on_click = -> do
    # #   if player.has_item?("key")
    # #     engine.change_scene("hallway")
    # #   else
    # #     player.say("It's locked. I need a key.")
    # #   end
    # # end
    ##
    # # scene.add_hotspot(door)
    # # ```
    ##
    # # ## Advanced Usage with Verbs
    ##
    # # ```crystal
    # # # Create a multi-verb NPC hotspot
    # # guard = Hotspot.new("guard", Vector2.new(600, 300), Vector2.new(64, 96))
    # # guard.object_type = UI::ObjectType::Character
    # # guard.default_verb = UI::VerbType::Talk
    ##
    # # # Different responses for different verbs
    # # scene.on_hotspot_interact("guard") do |verb, player|
    # #   case verb
    # #   when .look?
    # #     player.say("A tired-looking guard.")
    # #   when .talk?
    # #     start_dialog("guard_conversation")
    # #   when .use?
    # #     player.say("I'd rather not touch him.")
    # #   end
    # # end
    # # ```
    ##
    # # ## Movement Blocking
    ##
    # # ```crystal
    # # # Create an obstacle that blocks pathfinding
    # # table = Hotspot.new("table", Vector2.new(300, 400), Vector2.new(120, 80))
    # # table.blocks_movement = true
    # # table.description = "A heavy oak table"
    ##
    # # # Characters will path around this hotspot
    # # ```
    ##
    # # ## Script Integration
    ##
    # # ```crystal
    # # # Use Lua scripts for complex interactions
    # # terminal = Hotspot.new("terminal", Vector2.new(200, 300), Vector2.new(100, 100))
    # # terminal.script_path = "scripts/terminal.lua"
    ##
    # # # In terminal.lua:
    # # # hotspot.on_interact("terminal", function(player)
    # # #   if game.get_var("power_on") then
    # # #     show_terminal_interface()
    # # #   else
    # # #     player.say("The terminal is powered off")
    # # #   end
    # # # end)
    # # ```
    ##
    # # ## Common Gotchas
    ##
    # # 1. **Z-order matters**: Hotspots are checked front-to-back
    # #    ```crystal
    # #    # If hotspots overlap, only the front one receives clicks
    # #    scene.add_hotspot(background_hotspot)  # Added first = behind
    # #    scene.add_hotspot(foreground_hotspot)  # Added last = in front
    # #    ```
    ##
    # # 2. **Callbacks aren't serialized**: Re-register after loading
    # #    ```crystal
    # #    # ❌ This won't survive save/load:
    # #    door.on_click = -> { do_something }
    ##
    # #    # ✅ Use scripts or scene event handlers instead:
    # #    scene.on_hotspot_interact("door") { do_something }
    # #    ```
    ##
    # # 3. **Debug visualization performance**: Many hotspots can slow down debug mode
    # #    ```crystal
    # #    # Consider disabling debug for background hotspots
    # #    decorative_hotspot.visible = false  # Hides debug overlay
    # #    ```
    ##
    # # 4. **Cursor changes require mouse movement**: Static cursor won't update
    # #    ```crystal
    # #    # After changing cursor_type dynamically:
    # #    hotspot.cursor_type = CursorType::Talk
    # #    # User must move mouse to see new cursor
    # #    ```
    ##
    # # ## Performance Tips
    ##
    # # - Use `blocks_movement` sparingly - each blocking hotspot adds to pathfinding cost
    # # - Consider combining multiple decorative hotspots into one larger area
    # # - Disable `visible` for purely functional hotspots to skip debug rendering
    # # - Use polygon hotspots only when rectangles won't suffice
    ##
    # # ## See Also
    ##
    # # - `PolygonHotspot` - For non-rectangular interaction areas
    # # - `Scene#add_hotspot` - Adding hotspots to scenes
    # # - `UI::VerbCoin` - Verb selection interface
    # # - `CursorManager` - Cursor appearance system
    class Hotspot < Core::GameObject
      # Unique identifier for this hotspot
      property name : String

      # Descriptive text shown when examining the hotspot
      property description : String = ""

      # Cursor appearance when hovering over this hotspot
      property cursor_type : CursorType = CursorType::Hand

      # Whether this hotspot blocks character movement
      property blocks_movement : Bool = false

      # Default verb action for this hotspot (optional)
      property default_verb : UI::VerbType?

      # Classification of this object for interaction purposes
      property object_type : UI::ObjectType = UI::ObjectType::Background

      # Optional script file path for this hotspot's behavior
      # If nil, the hotspot will use the scene's default script
      property script_path : String?
      
      # Z-order for depth sorting (higher values are drawn on top)
      property z_order : Int32 = 0

      # Action commands mapped by verb type
      # e.g. {"use" => "transition:garden:swirl:4.5:300,400"}
      property action_commands : Hash(String, String) = {} of String => String

      # Callback executed when the hotspot is clicked (runtime only)
      @[YAML::Field(ignore: true)]
      property on_click : Proc(Nil)?

      # Callback executed when the hotspot is hovered (runtime only)
      @[YAML::Field(ignore: true)]
      property on_hover : Proc(Nil)?

      # Color used for debug visualization (runtime only)
      @[YAML::Field(ignore: true)]
      property debug_color : RL::Color = RL::Color.new(r: 255, g: 0, b: 0, a: 100)

      # # Defines cursor appearances for different interaction modes.
      ##
      # # The cursor automatically changes when hovering over hotspots to indicate
      # # the primary action available. This provides immediate visual feedback
      # # about what clicking will do.
      ##
      # # ## Usage
      ##
      # # ```crystal
      # # # Set cursor for different hotspot types
      # # door.cursor_type = CursorType::Use      # Shows tool/hand cursor
      # # npc.cursor_type = CursorType::Talk      # Shows speech bubble
      # # painting.cursor_type = CursorType::Look  # Shows magnifying glass
      # # ```
      ##
      # # ## Custom Cursor Mapping
      ##
      # # ```crystal
      # # # Map cursors to verb actions
      # # case hotspot.cursor_type
      # # when .talk?
      # #   default_verb = VerbType::Talk
      # # when .use?
      # #   default_verb = VerbType::Use
      # # when .look?
      # #   default_verb = VerbType::Look
      # # end
      # # ```
      enum CursorType
        # # Standard arrow cursor - no special interaction indicated
        Default

        # # Pointing hand cursor - general interaction available
        ##
        # # Used for clickable objects without specific verb association
        Hand

        # # Magnifying glass cursor - examination available
        ##
        # # Indicates the object has detailed description or close-up view
        Look

        # # Speech bubble cursor - conversation available
        ##
        # # Used for NPCs and talkable objects
        Talk

        # # Tool/gear cursor - item can be used or operated
        ##
        # # Indicates mechanical interaction or item usage
        Use
      end

      # Creates a hotspot with empty properties
      #
      # Name and description must be set separately.
      def initialize
        super()
        @name = ""
        @description = ""
      end

      # Creates a hotspot with specified properties
      #
      # - *name* : Unique identifier for the hotspot
      # - *position* : Top-left corner of the hotspot area
      # - *size* : Width and height of the interaction area
      def initialize(@name : String, position : RL::Vector2, size : RL::Vector2)
        super(position, size)
        @description = ""
      end

      # # Updates the hotspot's interaction state.
      ##
      # # Called every frame to check for mouse interactions. Handles hover
      # # detection and click events, triggering registered callbacks when
      # # the mouse interacts with the hotspot area.
      ##
      # # - *dt* : Delta time in seconds since last update
      ##
      # # ## Callback Execution
      ##
      # # - `on_hover` - Called every frame while mouse is over hotspot
      # # - `on_click` - Called once when mouse button is pressed
      ##
      # # ## Example Override
      ##
      # # ```crystal
      # # class AnimatedHotspot < Hotspot
      # #   def update(dt)
      # #     super  # Handle interaction
      ##
      # #     # Add custom animation
      # #     if @hovered
      # #       @glow_intensity = Math.min(1.0, @glow_intensity + dt * 2)
      # #     else
      # #       @glow_intensity = Math.max(0.0, @glow_intensity - dt * 2)
      # #     end
      # #   end
      # # end
      # # ```
      ##
      # # NOTE: Inactive hotspots (`active = false`) skip all interaction checks
      ##
      # # WARNING: Avoid heavy computation in hover callbacks as they run every frame
      def update(dt : Float32)
        return unless @active

        mouse_pos = RL.get_mouse_position
        if contains_point?(mouse_pos)
          @on_hover.try &.call
          if RL::MouseButton::Left.pressed?
            @on_click.try &.call
          end
        end
      end

      # Renders the hotspot (debug visualization only)
      #
      # Hotspots are typically invisible during gameplay, but show
      # their interaction areas when debug mode is enabled.
      def draw
        if Core::Engine.debug_mode && @visible
          draw_debug
        end
      end

      # Draws debug visualization of the hotspot area
      #
      # Override this method in subclasses for custom debug rendering
      # such as polygon outlines or special shapes.
      def draw_debug
        RL.draw_rectangle_rec(bounds, @debug_color)
      end

      # Gets the outline points for rendering or collision detection
      #
      # Returns the corner points of the hotspot area. Override in
      # subclasses that use non-rectangular shapes.
      #
      # Returns: Array of Vector2 points defining the hotspot boundary
      def get_outline_points : Array(RL::Vector2)
        # Return rectangle corners for rectangular hotspot
        [
          RL::Vector2.new(x: @position.x, y: @position.y),
          RL::Vector2.new(x: @position.x + @size.x, y: @position.y),
          RL::Vector2.new(x: @position.x + @size.x, y: @position.y + @size.y),
          RL::Vector2.new(x: @position.x, y: @position.y + @size.y),
        ]
      end

      # Gets the effective script path for this hotspot
      #
      # Returns the hotspot's specific script path if set, otherwise
      # falls back to the scene's default script path.
      #
      # - *scene* : The scene containing this hotspot
      #
      # Returns: The script path to use, or nil if no script is available
      def get_effective_script_path(scene) : String?
        @script_path || scene.try(&.script_path)
      end
    end
  end
end
