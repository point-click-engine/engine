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
      MOVEMENT_ARRIVAL_THRESHOLD = 5.0_f32      # Distance to consider "arrived" at target
      PATHFINDING_WAYPOINT_THRESHOLD = 10.0_f32 # Distance to consider waypoint reached
      
      # Character movement speeds
      DEFAULT_WALKING_SPEED = 100.0_f32         # Default character speed (pixels/second)
      SCALED_WALKING_SPEED = 200.0_f32          # Speed for scaled characters
      FAST_WALKING_SPEED = 300.0_f32            # Fast movement speed
      SLOW_WALKING_SPEED = 50.0_f32             # Slow movement speed
      
      # Animation constants
      DEFAULT_ANIMATION_SPEED = 0.1_f32         # Default time between frames
      FAST_ANIMATION_SPEED = 0.05_f32           # Fast animation playback
      SLOW_ANIMATION_SPEED = 0.2_f32            # Slow animation playback
      
      # Scaling constants
      DEFAULT_CHARACTER_SCALE = 1.0_f32         # Default character scale
      MAX_CHARACTER_SCALE = 5.0_f32             # Maximum allowed scale
      MIN_CHARACTER_SCALE = 0.1_f32             # Minimum allowed scale
      
      # Scene and camera constants
      DEFAULT_SCENE_WIDTH = 1024                # Default scene width
      DEFAULT_SCENE_HEIGHT = 768               # Default scene height
      CAMERA_EDGE_SCROLL_MARGIN = 50           # Pixels from edge to start scrolling
      CAMERA_SCROLL_SPEED = 200.0_f32          # Camera scroll speed
      
      # UI constants
      DIALOG_FADE_SPEED = 5.0_f32              # Dialog fade in/out speed
      TOOLTIP_DELAY = 0.5_f32                  # Delay before showing tooltips
      FLOATING_TEXT_DURATION = 3.0_f32         # Default floating text duration
      EXTENDED_FLOATING_TEXT_DURATION = 30.0_f32 # Extended duration for important text
      
      # Debug visualization constants
      DEBUG_LINE_THICKNESS = 2.0_f32          # Thickness of debug lines
      DEBUG_CIRCLE_RADIUS = 5.0_f32           # Radius of debug circles
      DEBUG_WAYPOINT_RADIUS = 3.0_f32         # Radius of pathfinding waypoints
      
      # Performance constants
      MAX_VECTOR_POOL_SIZE = 100               # Maximum cached vectors
      MAX_CACHED_ANIMATIONS = 50               # Maximum cached animation data
      AUTO_SAVE_INTERVAL = 300.0_f32          # Auto-save every 5 minutes
      
      # Input constants
      DOUBLE_CLICK_TIME = 0.3_f32              # Maximum time for double-click
      LONG_PRESS_TIME = 0.8_f32                # Time for long press detection
      DRAG_THRESHOLD = 5.0_f32                 # Minimum distance to start drag
      
      # Audio constants
      DEFAULT_MASTER_VOLUME = 0.8_f32          # Default master volume
      DEFAULT_MUSIC_VOLUME = 0.7_f32           # Default music volume
      DEFAULT_SFX_VOLUME = 0.9_f32             # Default sound effects volume
      AUDIO_FADE_SPEED = 2.0_f32               # Audio fade in/out speed
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