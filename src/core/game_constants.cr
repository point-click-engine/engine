# Game constants and configuration values
#
# Centralizes all magic numbers and configuration constants used throughout
# the Point & Click Engine. This improves maintainability and reduces bugs
# caused by inconsistent values.

module PointClickEngine
  module Core
    # Core game constants and thresholds
    module GameConstants
      # Movement and pathfinding thresholds
      MOVEMENT_ARRIVAL_THRESHOLD     =  5.0_f32 # Distance to consider "arrived" at target
      PATHFINDING_WAYPOINT_THRESHOLD = 10.0_f32 # Distance to consider waypoint reached
      DIRECTION_UPDATE_THRESHOLD     =  5.0_f32 # Minimum horizontal distance for direction changes
      MINIMUM_CLICK_DISTANCE         =  2.0_f32 # Minimum distance for mouse click movement
      WALKABLE_POINT_TOLERANCE       =  1.0_f32 # Tolerance for nearest walkable point search

      # Character movement speeds
      DEFAULT_WALKING_SPEED = 100.0_f32 # Default character speed (pixels/second)
      SCALED_WALKING_SPEED  = 200.0_f32 # Speed for scaled characters
      FAST_WALKING_SPEED    = 300.0_f32 # Fast movement speed
      SLOW_WALKING_SPEED    =  50.0_f32 # Slow movement speed

      # Animation constants
      DEFAULT_ANIMATION_SPEED =  0.1_f32 # Default time between frames
      FAST_ANIMATION_SPEED    = 0.05_f32 # Fast animation playback
      SLOW_ANIMATION_SPEED    =  0.2_f32 # Slow animation playback

      # Character size constants
      DEFAULT_PLAYER_WIDTH  = 32.0_f32 # Default player character width
      DEFAULT_PLAYER_HEIGHT = 64.0_f32 # Default player character height

      # Scaling constants
      DEFAULT_CHARACTER_SCALE = 1.0_f32 # Default character scale
      MAX_CHARACTER_SCALE     = 5.0_f32 # Maximum allowed scale
      MIN_CHARACTER_SCALE     = 0.1_f32 # Minimum allowed scale
      DEFAULT_MIN_SCALE       = 0.5_f32 # Default minimum scale for scale zones
      DEFAULT_MAX_SCALE       = 1.0_f32 # Default maximum scale for scale zones

      # Scene and camera constants
      DEFAULT_SCENE_WIDTH       =      1024 # Default scene width
      DEFAULT_SCENE_HEIGHT      =       768 # Default scene height
      CAMERA_EDGE_SCROLL_MARGIN =        50 # Pixels from edge to start scrolling
      CAMERA_SCROLL_SPEED       = 200.0_f32 # Camera scroll speed

      # UI constants
      DIALOG_FADE_SPEED               =  5.0_f32 # Dialog fade in/out speed
      TOOLTIP_DELAY                   =  0.5_f32 # Delay before showing tooltips
      FLOATING_TEXT_DURATION          =  3.0_f32 # Default floating text duration
      EXTENDED_FLOATING_TEXT_DURATION = 30.0_f32 # Extended duration for important text

      # Navigation and pathfinding constants
      DEFAULT_NAVIGATION_CELL_SIZE      =        32 # Default navigation grid cell size
      DEFAULT_CHARACTER_RADIUS          =  32.0_f32 # Default character radius for navigation
      NAVIGATION_RADIUS_REDUCTION       =   0.7_f32 # Radius reduction factor for navigation grid
      MAX_PATHFINDING_SEARCH_NODES      =      5000 # Maximum nodes to search in pathfinding
      SAME_CELL_DISTANCE_THRESHOLD      =   1.0_f32 # Minimum distance for same-cell pathfinding
      DIAGONAL_MOVEMENT_COST            = 1.414_f32 # Cost for diagonal movement (sqrt(2))
      CARDINAL_MOVEMENT_COST            =   1.0_f32 # Cost for cardinal movement
      HEURISTIC_DIAGONAL_MULTIPLIER     = 1.414_f32 # Diagonal multiplier for heuristic
      PATH_OPTIMIZATION_MAX_LOOKAHEAD   =         5 # Maximum lookahead for path optimization
      PATH_MIDPOINT_INSERTION_THRESHOLD =         5 # Path size threshold for midpoint insertion

      # Walkable area search constants
      MAX_WALKABLE_SEARCH_RADIUS       = 200.0_f32 # Maximum radius for walkable point search
      WALKABLE_SEARCH_RADIUS_STEP      =  10.0_f32 # Step size for expanding search radius
      WALKABLE_SEARCH_ANGLE_STEPS      =        16 # Number of angle steps for circular search
      WALKABLE_CONSTRAINT_SAMPLE_STEPS =        10 # Steps for line sampling in walkable constraints

      # Debug visualization constants
      DEBUG_LINE_THICKNESS         = 2.0_f32 # Thickness of debug lines
      DEBUG_CIRCLE_RADIUS          = 5.0_f32 # Radius of debug circles
      DEBUG_WAYPOINT_RADIUS        = 3.0_f32 # Radius of pathfinding waypoints
      DEBUG_PATH_LINE_THICKNESS    = 3.0_f32 # Thickness of debug path lines
      DEBUG_WAYPOINT_CIRCLE_RADIUS = 5.0_f32 # Radius of debug waypoint circles
      DEBUG_SCALE_ZONE_WIDTH       =      50 # Width for scale zone visualization
      DEBUG_GRADIENT_STEPS         =      20 # Steps for gradient visualization
      DEBUG_SCALE_RECT_WIDTH       =      40 # Rectangle width for scale visualization

      # Performance constants
      MAX_VECTOR_POOL_SIZE  =       100 # Maximum cached vectors
      MAX_CACHED_ANIMATIONS =        50 # Maximum cached animation data
      AUTO_SAVE_INTERVAL    = 300.0_f32 # Auto-save every 5 minutes

      # Input validation constants
      MAX_SCENE_COORDINATE      = 100000.0_f32 # Maximum reasonable scene coordinate
      MIN_SCENE_COORDINATE      = -10000.0_f32 # Minimum reasonable scene coordinate
      MAX_PATHFINDING_WAYPOINTS =         1000 # Maximum waypoints in a single path
      MIN_PATHFINDING_DISTANCE  =     0.01_f32 # Minimum distance for pathfinding
      MAX_CHARACTER_SIZE        =   1000.0_f32 # Maximum reasonable character size
      MIN_CHARACTER_SIZE        =      1.0_f32 # Minimum reasonable character size
      MAX_WALKING_SPEED         =  10000.0_f32 # Maximum reasonable walking speed
      MAX_DELTA_TIME            =      1.0_f32 # Maximum reasonable frame delta time

      # Input constants
      DOUBLE_CLICK_TIME = 0.3_f32 # Maximum time for double-click
      LONG_PRESS_TIME   = 0.8_f32 # Time for long press detection
      DRAG_THRESHOLD    = 5.0_f32 # Minimum distance to start drag

      # Audio constants
      DEFAULT_MASTER_VOLUME = 0.8_f32 # Default master volume
      DEFAULT_MUSIC_VOLUME  = 0.7_f32 # Default music volume
      DEFAULT_SFX_VOLUME    = 0.9_f32 # Default sound effects volume
      AUDIO_FADE_SPEED      = 2.0_f32 # Audio fade in/out speed
    end

    # Debug level configuration for controlling debug output
    enum DebugLevel
      # No debug output - production mode
      OFF
      # Basic debug information - errors and warnings only
      BASIC
      # Verbose debug information - detailed logging
      VERBOSE
      # Visual debugging - renders debug overlays
      VISUAL

      def to_s(io)
        io << case self
        when .off?     then "OFF"
        when .basic?   then "BASIC"
        when .verbose? then "VERBOSE"
        when .visual?  then "VISUAL"
        end
      end

      # Check if debug output should be shown
      def should_log?(message_level : DebugLevel) : Bool
        return false if self.off?
        return true if message_level.basic? && (self.basic? || self.verbose? || self.visual?)
        return true if message_level.verbose? && (self.verbose? || self.visual?)
        return true if message_level.visual? && self.visual?
        false
      end

      # Check if visual debugging should be enabled
      def show_visual? : Bool
        self.visual?
      end
    end

    # Debug configuration class for centralized debug control
    class DebugConfig
      class_property current_level : DebugLevel = DebugLevel::OFF
      class_property show_pathfinding : Bool = false
      class_property show_walkable_areas : Bool = false
      class_property show_collision_bounds : Bool = false
      class_property show_grid_overlay : Bool = false
      class_property show_waypoints : Bool = false
      class_property log_movement : Bool = false
      class_property log_pathfinding : Bool = false
      class_property log_player_input : Bool = false

      # Enable visual debugging features
      def self.enable_visual_debugging
        @@current_level = DebugLevel::VISUAL
        @@show_pathfinding = true
        @@show_walkable_areas = true
        @@show_collision_bounds = true
        @@show_grid_overlay = true
        @@show_waypoints = true
      end

      # Enable verbose logging
      def self.enable_verbose_logging
        @@current_level = DebugLevel::VERBOSE
        @@log_movement = true
        @@log_pathfinding = true
        @@log_player_input = true
      end

      # Disable all debugging
      def self.disable_all_debugging
        @@current_level = DebugLevel::OFF
        @@show_pathfinding = false
        @@show_walkable_areas = false
        @@show_collision_bounds = false
        @@show_grid_overlay = false
        @@show_waypoints = false
        @@log_movement = false
        @@log_pathfinding = false
        @@log_player_input = false
      end

      # Check if a specific debug category should be active
      def self.should_log?(category : Symbol) : Bool
        case category
        when :movement
          @@log_movement && @@current_level.should_log?(DebugLevel::VERBOSE)
        when :pathfinding
          @@log_pathfinding && @@current_level.should_log?(DebugLevel::VERBOSE)
        when :player_input
          @@log_player_input && @@current_level.should_log?(DebugLevel::VERBOSE)
        else
          @@current_level.should_log?(DebugLevel::BASIC)
        end
      end

      # Check if visual debugging should be shown for a category
      def self.should_show_visual?(category : Symbol) : Bool
        return false unless @@current_level.show_visual?
        case category
        when :pathfinding
          @@show_pathfinding
        when :walkable_areas
          @@show_walkable_areas
        when :collision_bounds
          @@show_collision_bounds
        when :grid_overlay
          @@show_grid_overlay
        when :waypoints
          @@show_waypoints
        else
          false
        end
      end
    end

    # Animation type enumeration for type-safe animation names
    enum AnimationType
      Idle
      WalkLeft
      WalkRight
      WalkUp
      WalkDown
      Talk
      Thinking
      Interacting
      PickingUp
      Using
      Looking

      # Convert enum to string for animation system compatibility
      def to_s(io)
        io << case self
        when .idle?        then "idle"
        when .walk_left?   then "walk_left"
        when .walk_right?  then "walk_right"
        when .walk_up?     then "walk_up"
        when .walk_down?   then "walk_down"
        when .talk?        then "talk"
        when .thinking?    then "thinking"
        when .interacting? then "interacting"
        when .picking_up?  then "picking_up"
        when .using?       then "using"
        when .looking?     then "looking"
        end
      end

      # Get directional variant based on direction
      def self.walk_for_direction(direction : Characters::Direction) : AnimationType
        case direction
        when .left?  then WalkLeft
        when .right? then WalkRight
        when .up?    then WalkUp
        when .down?  then WalkDown
        else              WalkRight # Default fallback
        end
      end

      # Get idle variant based on direction
      def self.idle_for_direction(direction : Characters::Direction) : AnimationType
        # For now, just return Idle - can be extended for directional idles
        Idle
      end
    end

    # Verb types for adventure game interactions
    enum VerbType
      Walk
      Look
      Talk
      Use
      Take
      Open
      Close
      Push
      Pull

      def to_s(io)
        io << case self
        when .walk?  then "Walk"
        when .look?  then "Look"
        when .talk?  then "Talk"
        when .use?   then "Use"
        when .take?  then "Take"
        when .open?  then "Open"
        when .close? then "Close"
        when .push?  then "Push"
        when .pull?  then "Pull"
        end
      end
    end
  end
end
