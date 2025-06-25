# YAML Format Specifications

This document contains the YAML format specifications extracted from the Game Format Specification.

## Game Configuration (lines 103-182)

The `game_config.yaml` file defines all game-wide settings.

```yaml
# Game metadata
game:
  title: String           # Game title shown in window
  version: String         # Version string (e.g., "1.0.0")
  author: String?         # Optional author name

# Window settings
window:
  width: Int32            # Window width in pixels (default: 1024)
  height: Int32           # Window height in pixels (default: 768)
  fullscreen: Bool        # Start in fullscreen (default: false)
  target_fps: Int32       # Target frame rate (default: 60)

# Display settings
display:
  scaling_mode: String    # "FitWithBars" | "Stretch" | "PixelPerfect"
  target_width: Int32     # Internal render width
  target_height: Int32    # Internal render height

# Player character configuration
player:
  name: String            # Player character name
  sprite_path: String     # Path to sprite sheet
  sprite:
    frame_width: Int32    # Width of each frame
    frame_height: Int32   # Height of each frame
    columns: Int32        # Number of columns in sprite sheet
    rows: Int32           # Number of rows in sprite sheet
  start_position:         # Optional starting position
    x: Float32
    y: Float32

# Engine features to enable
features: Array(String)   # Available features:
  # - "verbs"              # Verb-based input (Walk, Look, etc.)
  # - "floating_dialogs"   # Dialog bubbles above characters
  # - "portraits"          # Character portraits in dialogs
  # - "shaders"           # Visual effects
  # - "auto_save"         # Automatic saving
  # - "debug"             # Debug mode

# Asset loading paths (supports glob patterns)
assets:
  scenes: Array(String)   # Scene file patterns
  dialogs: Array(String)  # Dialog file patterns
  quests: Array(String)   # Quest file patterns
  audio:
    music: Hash(String, String)   # name => path mappings
    sounds: Hash(String, String)  # name => path mappings

# Game settings
settings:
  debug_mode: Bool        # Enable debug on start
  show_fps: Bool          # Show FPS counter
  master_volume: Float32  # 0.0 to 1.0
  music_volume: Float32   # 0.0 to 1.0
  sfx_volume: Float32     # 0.0 to 1.0

# Initial game state
initial_state:
  flags: Hash(String, Bool)                    # Boolean flags
  variables: Hash(String, Float32|Int32|String) # Game variables

# Starting configuration
start_scene: String?      # Scene to load on new game
start_music: String?      # Music to play on start

# UI configuration
ui:
  hints: Array(UIHint)    # Tutorial hints
    - text: String        # Hint text
      duration: Float32   # Display duration in seconds
  opening_message: String? # Message shown on game start
```

## Scene Format (lines 183-299)

Scene files define game locations with backgrounds, hotspots, and navigation.

```yaml
# Basic scene information
name: String              # Unique scene identifier
background_path: String   # Path to background image
script_path: String?      # Associated Lua script

# Logical dimensions (texture-independent coordinate system)
logical_width: Int32?     # Logical scene width (default: 1024)
logical_height: Int32?    # Logical scene height (default: 768)

# Pathfinding configuration
enable_pathfinding: Bool  # Enable A* pathfinding
navigation_cell_size: Int32 # Grid cell size for pathfinding

# Camera scrolling configuration
enable_camera_scrolling: Bool # Enable camera scrolling for larger scenes (default: true)

# Default transition duration for this scene
default_transition_duration: Float32? # Duration in seconds (default: 1.0)

# Walkable area definition
walkable_areas:
  regions: Array(Region)  # Walkable polygons
    - name: String
      walkable: Bool      # true for walkable, false for obstacles
      vertices: Array(Point)
        - {x: Float32, y: Float32}
  
  walk_behind: Array(WalkBehindRegion)  # Areas where character appears behind
    - name: String
      y_threshold: Float32  # Y position where character goes behind
      vertices: Array(Point)
  
  scale_zones: Array(ScaleZone)  # Character scaling by Y position
    - min_y: Float32
      max_y: Float32
      min_scale: Float32    # Scale at min_y
      max_scale: Float32    # Scale at max_y

# Interactive hotspots
hotspots: Array(Hotspot)
  # Rectangle hotspot
  - name: String            # Unique identifier
    type: String?           # "rectangle" (default) | "polygon" | "dynamic"
    x: Float32              # X position
    y: Float32              # Y position
    width: Float32          # Width
    height: Float32         # Height
    description: String     # Shown on hover/examine
    
    # Optional properties
    active: Bool?           # Is hotspot active (default: true)
    visible: Bool?          # Is hotspot visible (default: true)
    default_verb: String?   # Default verb when hovering (e.g., "open", "look", "use")
    object_type: String?    # Object classification ("door", "item", "character", etc.)
    
    # Action handlers - can be simple text responses or special commands
    actions:                # Actions for different verbs
      look: String?         # Text shown when looking at the hotspot
      use: String?          # Response or command when using
      talk: String?         # Response when talking to
      take: String?         # Response when trying to take
      open: String?         # Can trigger scene transitions (see below)
      close: String?        # Response when closing
      push: String?         # Response when pushing
      pull: String?         # Response when pulling
      give: String?         # Response when giving items
      walk: String?         # Response or command when walking to
    
    # Scene Transitions via Actions
    # Any action can trigger a transition using this format:
    # "transition:scene_name:effect:duration:x,y"
    # Examples:
    #   open: "transition:garden:swirl:4.5:300,400"      # Explicit duration
    #   use: "transition:dungeon:fade::100,200"          # Use scene's default_transition_duration
    #   talk: "transition:wizard_tower:star_wipe:default" # Explicitly use default duration
    #   close: "transition:library:curtain"              # Minimal format (uses all defaults)
    #
    # Parameters:
    # - scene_name: Required. Target scene to transition to
    # - effect: Optional. Transition effect (default: fade)
    #   Available effects: fade, dissolve, slide_left, slide_right, slide_up, slide_down,
    #   iris, swirl, star_wipe, heart_wipe, curtain, ripple, checkerboard, pixelate,
    #   warp, wave, glitch, film_burn, static, matrix_rain, zoom_blur, clock_wipe,
    #   barn_door, page_turn, shatter, vortex, fire
    # - duration: Optional. Transition duration in seconds
    #   - Explicit number: Use that duration (e.g., "2.5")
    #   - Empty or "default": Use the current scene's default_transition_duration
    #   - If omitted entirely: Use the current scene's default_transition_duration
    #   - Fallback: 1.0 seconds if no default is specified
    # - x,y: Optional. Target position for player in new scene
    
    # For dynamic hotspots
    states: Array(HotspotState)?
      - name: String
        description: String
        sprite_path: String?
        active: Bool?
        visible: Bool?
    
    # Visibility conditions
    conditions: Condition?  # See Condition format below
    
  # Polygon hotspot
  - name: String
    type: "polygon"
    vertices: Array(Point)
    description: String
    # ... other properties same as rectangle
    
  # Dynamic hotspot (changes based on game state)
  - name: String
    type: "dynamic"
    x: Float32
    y: Float32
    width: Float32
    height: Float32
    description: String
    
    # Dynamic-specific properties
    states: Hash(String, HotspotState)  # Named states
    visibility_conditions: Array(Condition)?  # When to show
    state_conditions: Hash(String, Array(Condition))?  # State triggers

# Characters in the scene
characters: Array(Character)
  - name: String            # Unique identifier
    position:
      x: Float32
      y: Float32
    sprite_path: String     # Path to sprite sheet
    sprite_info:
      frame_width: Int32
      frame_height: Int32
    dialog_tree: String?    # Associated dialog file
    
# Condition format (used for visibility, requirements, etc.)
Condition:
  # Simple conditions
  flag: String?             # Check game flag
  has_item: String?         # Check inventory for item
  variable: String?         # Variable to check
  value: Any?               # Value to compare
  operator: String?         # "==" | "!=" | ">" | "<" | ">=" | "<="
  
  # Complex conditions
  all_of: Array(Condition)? # All conditions must be true
  any_of: Array(Condition)? # Any condition must be true
  none_of: Array(Condition)? # No conditions must be true
```

## Dialog Format (lines 453-493)

Dialog files define conversation trees with branching paths.

```yaml
# Dialog tree identifier
id: String

# Dialog nodes
nodes: Array(DialogNode)
  - id: String              # Unique node ID
    speaker: String         # Character name
    text: String            # Dialog text
    portrait: String?       # Portrait image name
    
    # Responses/choices
    choices: Array(Choice)?
      - text: String        # Choice text
        next: String?       # Next node ID
        conditions: Condition? # Show choice only if
        effects: Array(Effect)? # Effects when chosen
          - type: String    # "set_flag" | "set_variable" | "add_item" | etc.
            name: String
            value: Any
    
    # Auto-continue to next node
    next: String?           # Next node ID if no choices
    
    # Node conditions
    conditions: Condition?  # Show node only if
    
    # Node effects
    effects: Array(Effect)? # Effects when node is shown

# Starting node
start_node: String          # ID of first node

# Dialog end handlers
on_end: Array(Effect)?      # Effects when dialog ends
```

## Quest Format (lines 494-546)

Quest files define objectives, rewards, and progression.

```yaml
quests: Array(Quest)
  - id: String              # Unique quest ID
    name: String            # Display name
    description: String     # Quest description
    category: String        # "main" | "side" | "hidden"
    
    # Quest icon/image
    icon: String?           # Path to icon image
    
    # Auto-start conditions
    auto_start: Bool?       # Start automatically
    start_conditions: Condition? # When to auto-start
    
    # Quest availability
    prerequisites: Array(String)? # Required completed quests
    requirements: Condition? # Other requirements
    
    # Objectives
    objectives: Array(Objective)
      - id: String          # Unique objective ID
        description: String # Objective text
        optional: Bool?     # Is objective optional
        hidden: Bool?       # Hidden until discovered
        
        # Completion conditions
        completion_conditions: Condition
        
        # Objective rewards
        rewards: Array(Reward)?
    
    # Quest rewards
    rewards: Array(Reward)?
      - type: String        # "item" | "flag" | "variable" | "achievement"
        name: String        # Item/flag/variable name
        value: Any?         # Value for variables
        quantity: Int32?    # For items
    
    # Quest states
    can_fail: Bool?         # Can quest be failed
    fail_conditions: Condition? # When quest fails
    
    # Journal entries
    journal_entries: Array(JournalEntry)?
      - id: String
        text: String
        conditions: Condition? # When to show entry
```

## Item Format (lines 547-581)

Item definitions for inventory system.

```yaml
items: Hash(String, Item)
  item_id:                  # Unique item identifier
    name: String            # Internal name
    display_name: String    # Shown to player
    description: String     # Item description
    icon_path: String       # Path to icon image
    
    # Item properties
    usable_on: Array(String)? # Hotspot/item names
    combinable_with: Array(String)? # Other items
    consumable: Bool?       # Destroyed on use
    stackable: Bool?        # Can have multiple
    max_stack: Int32?       # Maximum stack size
    
    # Special properties
    quest_item: Bool?       # Can't be dropped
    readable: Bool?         # Can be read
    equippable: Bool?       # Can be equipped
    
    # Item states
    states: Array(ItemState)?
      - name: String
        description: String
        icon_path: String?
    
    # Use effects
    use_effects: Array(Effect)?
    combine_effects: Hash(String, Array(Effect))? # Per target item
```

## Cutscene Format (lines 582-652)

Cutscene files define scripted sequences.

```yaml
id: String                  # Unique cutscene ID
name: String                # Display name
skippable: Bool?            # Can player skip

# Cutscene actions in sequence
actions: Array(Action)
  - type: String            # Action type
    duration: Float32?      # Action duration
    
    # Action types:
    
    # "wait"
    duration: Float32       # Wait duration
    
    # "fade_in" / "fade_out"
    duration: Float32       # Fade duration
    color: String?          # Fade color (default: black)
    
    # "show_text"
    text: String            # Text to display
    position: Point?        # Text position
    duration: Float32       # Display duration
    style: TextStyle?       # Text styling
    
    # "move_character"
    character: String       # Character name
    target: Point           # Target position
    duration: Float32       # Move duration
    
    # "play_animation"
    character: String       # Character name
    animation: String       # Animation name
    
    # "play_sound"
    sound: String           # Sound name
    volume: Float32?        # Volume (0-1)
    
    # "play_music"
    music: String           # Music name
    loop: Bool?             # Loop music
    
    # "change_scene"
    scene: String           # Target scene
    transition: String?     # Transition type
    
    # "show_dialog"
    speaker: String         # Character name
    text: String            # Dialog text
    
    # "set_flag" / "set_variable"
    name: String            # Flag/variable name
    value: Any              # Value to set
    
    # "conditional"
    conditions: Condition   # Conditions to check
    if_true: Array(Action)  # Actions if true
    if_false: Array(Action)? # Actions if false
    
    # "parallel"
    actions: Array(Action)  # Actions to run simultaneously

# Cutscene end effects
on_complete: Array(Effect)? # Effects when cutscene ends
on_skip: Array(Effect)?     # Effects when cutscene is skipped
```