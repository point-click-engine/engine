# Hotspot implementation for interactive areas

require "yaml"
require "../utils/yaml_converters"
require "../ui/cursor_manager"

module PointClickEngine
  module Scenes
    # Represents an interactive area or object within a scene
    #
    # Hotspots define clickable regions that players can interact with using
    # different verbs (look, use, talk, etc.). They can represent doors, items,
    # furniture, or any other interactive element in the game world.
    #
    # ## Key Features
    # - Rectangular or custom-shaped interaction areas
    # - Cursor type changes on hover
    # - Verb-based interaction system
    # - Movement blocking for obstacles
    # - Debug visualization support
    #
    # ## Usage Example
    # ```
    # door = Hotspot.new("door", Vector2.new(100, 50), Vector2.new(80, 120))
    # door.description = "A wooden door"
    # door.cursor_type = CursorType::Use
    # door.on_click = -> { open_door }
    # scene.add_hotspot(door)
    # ```
    #
    # NOTE: Hotspots support both rectangular and polygon-based collision areas
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

      # Callback executed when the hotspot is clicked (runtime only)
      @[YAML::Field(ignore: true)]
      property on_click : Proc(Nil)?

      # Callback executed when the hotspot is hovered (runtime only)
      @[YAML::Field(ignore: true)]
      property on_hover : Proc(Nil)?

      # Color used for debug visualization (runtime only)
      @[YAML::Field(ignore: true)]
      property debug_color : RL::Color = RL::Color.new(r: 255, g: 0, b: 0, a: 100)

      # Defines the visual cursor types for different interaction modes
      #
      # Used to provide visual feedback about available actions when
      # hovering over hotspots.
      enum CursorType
        Default # Standard arrow cursor
        Hand    # Pointing hand for general interaction
        Look    # Magnifying glass for examination
        Talk    # Speech bubble for conversation
        Use     # Tool cursor for item usage
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

      # Updates the hotspot's interaction state
      #
      # Checks for mouse hover and click events, executing appropriate
      # callbacks when the mouse interacts with the hotspot area.
      #
      # - *dt* : Delta time in seconds since last update
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
