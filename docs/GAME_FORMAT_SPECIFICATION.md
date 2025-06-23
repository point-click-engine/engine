# Point & Click Engine Game Format Specification v1.0

## Table of Contents
1. [Overview](#overview)
2. [Directory Structure](#directory-structure)
3. [File Formats](#file-formats)
4. [Game Configuration](#game-configuration)
5. [Scene Format](#scene-format)
6. [Script Format](#script-format)
7. [Dialog Format](#dialog-format)
8. [Quest Format](#quest-format)
9. [Item Format](#item-format)
10. [Cutscene Format](#cutscene-format)
11. [Asset Requirements](#asset-requirements)
12. [Engine API Reference](#engine-api-reference)

## Overview

A Point & Click Engine game consists of a collection of YAML configuration files, Lua scripts, and assets organized in a specific directory structure. The engine loads these files to create an interactive adventure game.

### Core Components
- **Game Configuration** (`game_config.yaml`) - Main game settings and metadata
- **Scenes** (`.yaml`) - Room/location definitions with hotspots and navigation
- **Scripts** (`.lua`) - Game logic and interaction handlers
- **Dialogs** (`.yaml`) - Conversation trees and character interactions
- **Quests** (`.yaml`) - Quest definitions with objectives and rewards
- **Items** (`.yaml`) - Inventory item definitions
- **Assets** - Images, sounds, and other media files

## Directory Structure

```
game_name/
├── game_config.yaml              # Main game configuration
├── main.cr                       # Entry point (minimal)
├── scenes/                       # Scene definitions
│   ├── intro.yaml
│   ├── room1.yaml
│   └── ...
├── scripts/                      # Lua scripts for game logic
│   ├── intro.lua
│   ├── room1.lua
│   └── ...
├── dialogs/                      # Dialog trees
│   ├── npc1_dialog.yaml
│   └── ...
├── quests/                       # Quest definitions
│   ├── main_quests.yaml
│   └── side_quests.yaml
├── items/                        # Item definitions
│   └── items.yaml
├── cutscenes/                    # Cutscene definitions
│   ├── intro_sequence.yaml
│   └── ending_sequence.yaml
├── assets/                       # Game assets
│   ├── backgrounds/              # Scene backgrounds
│   │   ├── room1.png
│   │   └── ...
│   ├── sprites/                  # Character sprites
│   │   ├── player.png
│   │   ├── npc1.png
│   │   └── ...
│   ├── items/                    # Item icons
│   │   ├── key.png
│   │   └── ...
│   ├── portraits/                # Character portraits
│   │   ├── player_happy.png
│   │   └── ...
│   ├── music/                    # Background music
│   │   ├── main_theme.ogg
│   │   └── ...
│   └── sounds/                   # Sound effects
│       ├── effects/
│       │   ├── door_open.ogg
│       │   └── ...
│       └── ambience/
│           ├── rain.ogg
│           └── ...
└── saves/                        # Save game files (auto-created)
    └── autosave.yml
```

## File Formats

### 3.1 YAML Files
All configuration files use YAML format with UTF-8 encoding. 

**Common YAML Data Types:**
- **String**: `"text"` or `text`
- **Number**: `123` (integer) or `123.45` (float)
- **Boolean**: `true` or `false`
- **Array**: `[item1, item2]` or multi-line with `-`
- **Object**: `{key: value}` or multi-line with indentation

### 3.2 Lua Scripts
Lua 5.4 scripts with access to engine API functions.

### 3.3 Asset Files
- **Images**: PNG format (recommended), JPG supported
- **Audio**: OGG Vorbis (recommended), WAV supported
- **Fonts**: TTF format

## Game Configuration

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

## Scene Format

Scene files define game locations with backgrounds, hotspots, and navigation.

```yaml
# Basic scene information
name: String              # Unique scene identifier
background_path: String   # Path to background image
script_path: String?      # Associated Lua script

# Pathfinding configuration
enable_pathfinding: Bool  # Enable A* pathfinding
navigation_cell_size: Int32 # Grid cell size for pathfinding

# Camera scrolling configuration
enable_camera_scrolling: Bool # Enable camera scrolling for larger scenes (default: true)

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
    type: String?           # "rectangle" (default) | "polygon" | "exit"
    x: Float32              # X position
    y: Float32              # Y position
    width: Float32          # Width
    height: Float32         # Height
    description: String     # Shown on hover/examine
    
    # Optional properties
    active: Bool?           # Is hotspot active (default: true)
    visible: Bool?          # Is hotspot visible (default: true)
    cursor: String?         # Custom cursor on hover
    
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
    
  # Exit hotspot (scene transition)
  - name: String
    type: "exit"
    x: Float32
    y: Float32
    width: Float32
    height: Float32
    target_scene: String    # Scene to transition to
    target_position:        # Player position in target scene
      x: Float32
      y: Float32
    transition_type: String? # "fade" | "iris" | "slide_left" | etc.
    auto_walk: Bool?        # Auto-walk to exit before transition
    description: String
    
    # Edge exit (transition at screen edge)
    edge: String?           # "left" | "right" | "top" | "bottom"
    
    # Exit requirements
    requirements: Condition? # Conditions to allow exit

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

## Script Format

Lua scripts handle scene logic and interactions. Each scene can have an associated script.

### Scene Lifecycle Functions
```lua
-- Called when entering the scene
function on_enter()
end

-- Called when leaving the scene  
function on_exit()
end

-- Called every frame (dt = delta time)
function on_update(dt)
end
```

### Hotspot Handlers
```lua
-- Register click handler for hotspot
hotspot.on_click("hotspot_name", function()
    -- Handle click
end)

-- Register verb handler for specific action
hotspot.on_verb("hotspot_name", "look", function()
    -- Handle look action
end)

-- Available verbs: "walk", "look", "talk", "use", "take", "open"
```

### Character Handlers
```lua
-- Register character interaction
character.on_interact("character_name", function()
    -- Handle character interaction
end)

-- Register character verb handler
character.on_verb("character_name", "talk", function()
    -- Handle talk action
end)
```

### Engine API Functions

#### Scene Management
```lua
change_scene(scene_name)              -- Change to another scene
get_current_scene()                   -- Get current scene name
add_hotspot(hotspot_data)            -- Add dynamic hotspot
remove_hotspot(name)                 -- Remove hotspot
set_hotspot_visible(name, visible)   -- Show/hide hotspot
set_hotspot_active(name, active)     -- Enable/disable hotspot
get_hotspot_state(name)              -- Get current hotspot state
set_hotspot_state(name, state_name)  -- Change hotspot state
```

#### Character Control
```lua
move_character(name, x, y)           -- Move character to position
play_character_animation(name, anim) -- Play character animation
get_character_position(name)         -- Get character position
set_character_visible(name, visible) -- Show/hide character
has_character(name)                  -- Check if character exists
```

#### Player Control
```lua
get_player_position()                -- Get player position
move_player(x, y)                    -- Move player to position
player_walk_to(x, y)                 -- Pathfind player to position
set_player_controllable(enabled)     -- Enable/disable player control
```

#### Dialog System
```lua
show_message(text)                   -- Show simple message
show_dialog(character, text)         -- Show character dialog
show_dialog_choices(prompt, choices, callback) -- Show choice dialog
show_floating_dialog(character, text, position, duration, style)
start_dialog(dialog_file)            -- Start dialog tree
show_character_dialog(name, text, position) -- Show dialog at position
```

#### Inventory Management
```lua
add_to_inventory(item_name)          -- Add item by name
remove_from_inventory(item_name)     -- Remove item
has_item(item_name)                  -- Check if has item
get_selected_item()                  -- Get currently selected item
has_selected_item(item_name)         -- Check if item is selected
get_inventory_items()                -- Get all items array
```

#### Game State Management
```lua
set_flag(name, value)                -- Set boolean flag
get_flag(name)                       -- Get boolean flag
set_variable(name, value)            -- Set variable (number/string)
get_variable(name, default)          -- Get variable with default
increase_variable(name, amount)      -- Increment numeric variable
```

#### Quest Management
```lua
start_quest(quest_id)                -- Start a quest
complete_quest(quest_id)             -- Complete entire quest
fail_quest(quest_id)                 -- Fail a quest
complete_quest_objective(quest_id, objective_id) -- Complete objective
is_quest_active(quest_id)            -- Check if quest is active
is_quest_completed(quest_id)         -- Check if quest is done
get_quest_status(quest_id)           -- Get quest status string
```

#### Audio Control
```lua
play_sound(sound_name)               -- Play sound effect
play_music(music_name, loop)         -- Play background music
stop_music()                         -- Stop current music
play_ambient(sound_name, volume)     -- Play ambient sound
stop_ambient(sound_name)             -- Stop ambient sound
set_music_volume(volume)             -- Set music volume (0-1)
set_sound_volume(volume)             -- Set SFX volume (0-1)
```

#### Visual Effects
```lua
fade_in(duration)                    -- Fade from black
fade_out(duration)                   -- Fade to black
shake_screen(intensity, duration)    -- Screen shake effect
flash_screen(color, duration)        -- Screen flash
show_particle_effect(name, x, y)     -- Spawn particles
```

#### Timer Management
```lua
add_timer(duration, callback)        -- One-shot timer
add_repeating_timer(interval, callback) -- Repeating timer
cancel_timer(timer_id)               -- Cancel a timer
```

#### Utility Functions
```lua
print(message)                       -- Debug print
random(min, max)                     -- Random number
distance(x1, y1, x2, y2)            -- Calculate distance
lerp(start, end, t)                 -- Linear interpolation
```

## Dialog Format

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

## Quest Format

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

## Item Format

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

## Cutscene Format

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

## Asset Requirements

### Images
- **Format**: PNG (recommended for transparency), JPG
- **Color**: 32-bit RGBA
- **Size limits**: No hard limit, but consider memory usage

#### Background Images
- **Recommended size**: Match game resolution (e.g., 1024x768)
- **Format**: PNG or JPG
- **Naming**: `scene_name.png`

#### Sprite Sheets
- **Format**: PNG with transparency
- **Layout**: Grid of equal-sized frames
- **Frame order**: Left-to-right, top-to-bottom
- **Naming**: `character_name.png`

#### Item Icons
- **Recommended size**: 64x64 or 128x128 pixels
- **Format**: PNG with transparency
- **Naming**: `item_name.png`

#### Character Portraits
- **Recommended size**: 256x256 or 512x512 pixels
- **Format**: PNG with transparency
- **Naming**: `character_emotion.png` (e.g., `player_happy.png`)

### Audio
- **Format**: OGG Vorbis (recommended), WAV
- **Sample rate**: 44.1 kHz or 48 kHz
- **Channels**: Mono or Stereo

#### Music
- **Format**: OGG Vorbis
- **Bitrate**: 128-192 kbps
- **Looping**: Seamless loop points

#### Sound Effects
- **Format**: OGG or WAV
- **Duration**: Keep short (< 5 seconds)
- **Volume**: Normalized

## Engine API Reference

### Global Objects Available in Lua

```lua
-- Core objects
engine          -- Engine instance
scene           -- Current scene
player          -- Player character
inventory       -- Inventory system
dialog_manager  -- Dialog system
quest_manager   -- Quest system
audio_manager   -- Audio system

-- Helper objects
hotspot         -- Hotspot registration
character       -- Character management
game_state      -- State management
```

### Event System

The engine uses an event-driven architecture. Events can be triggered from Lua:

```lua
trigger_event(event_name, data)      -- Trigger custom event
on_event(event_name, callback)       -- Listen for event
```

### Standard Events
- `scene:entered` - Scene was entered
- `scene:exited` - Scene was exited
- `quest:started` - Quest started
- `quest:completed` - Quest completed
- `quest:failed` - Quest failed
- `objective:completed` - Quest objective completed
- `item:added` - Item added to inventory
- `item:removed` - Item removed from inventory
- `item:used` - Item was used
- `dialog:started` - Dialog tree started
- `dialog:ended` - Dialog tree ended
- `cutscene:started` - Cutscene started
- `cutscene:ended` - Cutscene ended
- `game:saved` - Game was saved
- `game:loaded` - Game was loaded

### Save Game Format

Save files are YAML-serialized engine state:

```yaml
# Engine state
window_width: Int32
window_height: Int32
title: String
current_scene_name: String
state_variables: Hash(String, StateValue)
fullscreen: Bool

# Inventory state
inventory:
  items: Array(Item)
  selected_item_index: Int32?

# Active quests
quests: Array(QuestState)
  - quest_id: String
    status: String
    completed_objectives: Array(String)

# Game state manager
game_state:
  flags: Hash(String, Bool)
  variables: Hash(String, Any)
  timers: Array(Timer)
```

## Editor Implementation Notes

When implementing a game editor, consider these aspects:

### 1. Scene Editor
- Visual hotspot placement and editing
- Walkable area polygon editor
- Character placement
- Preview with actual background
- Grid snapping options
- Hotspot state preview

### 2. Dialog Editor
- Visual node graph editor
- Choice branching visualization
- Condition builder UI
- Portrait preview
- Text formatting preview

### 3. Quest Editor
- Objective dependency graph
- Condition builder
- Reward configuration
- Journal entry preview

### 4. Asset Manager
- Asset import with validation
- Sprite sheet preview and frame selection
- Audio preview and waveform display
- Asset usage tracking

### 5. Script Editor
- Syntax highlighting for Lua
- API autocompletion
- Function documentation tooltips
- Error checking
- Breakpoint support

### 6. Testing Tools
- Scene preview mode
- State variable inspector
- Event log viewer
- Save state editor
- Performance profiler

### 7. Validation
- Asset path verification
- Script syntax checking
- Circular dependency detection
- Missing reference warnings
- Format version compatibility

### 8. Export/Build
- Asset optimization (compression, atlasing)
- Script compilation/obfuscation
- Platform-specific packaging
- Distribution file generation

This specification provides a complete technical foundation for implementing a comprehensive game editor for the Point & Click Engine.