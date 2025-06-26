# Point & Click Engine Component Reference

This document provides a comprehensive reference for all major components in the Point & Click Engine, organized by module.

## Table of Contents
1. [Core Components](#core-components)
2. [Scene Components](#scene-components)
3. [Character Components](#character-components)
4. [UI Components](#ui-components)
5. [Navigation Components](#navigation-components)
6. [Graphics Components](#graphics-components)
7. [Audio Components](#audio-components)
8. [Scripting Components](#scripting-components)

---

## Core Components

### Engine
**Location**: `src/core/engine.cr`  
**Purpose**: Main game engine coordinator

**Responsibilities**:
- Initialize Raylib window
- Manage game loop
- Coordinate all subsystems
- Handle global state

**Key Methods**:
- `init()` - Initialize engine and subsystems
- `run()` - Start main game loop
- `update(dt)` - Update all systems
- `render()` - Render frame
- `shutdown()` - Clean shutdown

**Usage**:
```crystal
engine = Engine.new(1024, 768, "My Game")
engine.init
engine.run
```

### SceneManager
**Location**: `src/core/scene_manager.cr`  
**Purpose**: Manage scene loading, caching, and transitions

**Responsibilities**:
- Load scenes from YAML/memory
- Cache scenes for performance
- Handle scene transitions
- Manage scene lifecycle

**Key Methods**:
- `load_scene(name)` - Load scene by name
- `change_scene(name, transition)` - Change with transition
- `reload_current_scene()` - Reload current scene
- `cache_scene(name)` - Pre-cache scene

### InputManager
**Location**: `src/core/input_manager.cr`  
**Purpose**: Priority-based input handling system

**Responsibilities**:
- Route input to handlers by priority
- Track input consumption
- Manage input state
- Handle keyboard/mouse/gamepad

**Key Methods**:
- `register_handler(handler, priority)` - Register handler
- `update()` - Process input
- `consume_input()` - Mark input consumed
- `is_input_consumed?()` - Check consumption

### RenderManager
**Location**: `src/core/render_manager.cr`  
**Purpose**: Layer-based rendering pipeline

**Responsibilities**:
- Manage render layers
- Coordinate rendering order
- Track performance metrics
- Handle render state

**Key Methods**:
- `register_renderer(renderer, layer)` - Add renderer
- `render()` - Execute render pipeline
- `set_layer_visible(layer, visible)` - Toggle layer
- `get_metrics()` - Performance data

### ResourceManager
**Location**: `src/core/resource_manager.cr`  
**Purpose**: Asset loading and caching

**Responsibilities**:
- Load textures/sounds/fonts
- Cache loaded assets
- Reference counting
- Hot-reload support

**Key Methods**:
- `load_texture(path)` - Load texture
- `load_sound(path)` - Load sound
- `get_texture(path)` - Get cached texture
- `reload_all()` - Hot reload assets

### GameStateManager
**Location**: `src/core/game_state_manager.cr`  
**Purpose**: Global game state and variables

**Responsibilities**:
- Store game variables
- Track game flags
- Provide state queries
- Persist state

**Key Methods**:
- `set_variable(name, value)` - Set variable
- `get_variable(name)` - Get variable
- `set_flag(name)` - Set boolean flag
- `has_flag?(name)` - Check flag

### QuestSystem
**Location**: `src/core/quest_system.cr`  
**Purpose**: Quest and objective tracking

**Responsibilities**:
- Track active quests
- Manage objectives
- Check completion conditions
- Trigger quest events

**Key Methods**:
- `add_quest(quest)` - Add new quest
- `complete_objective(quest_id, objective_id)` - Complete objective
- `is_quest_complete?(quest_id)` - Check completion
- `get_active_quests()` - List active quests

### SaveSystem
**Location**: `src/core/save_system.cr`  
**Purpose**: Game serialization and persistence

**Responsibilities**:
- Save game state
- Load saved games
- Manage save slots
- Auto-save functionality

**Key Methods**:
- `save_game(slot)` - Save to slot
- `load_game(slot)` - Load from slot
- `quick_save()` - Quick save
- `list_saves()` - Get save list

---

## Scene Components

### Scene
**Location**: `src/scenes/scene.cr`  
**Purpose**: Scene coordinator and container

**Responsibilities**:
- Coordinate scene components
- Manage scene objects
- Handle scene lifecycle
- Process scene logic

**Key Properties**:
- `name` - Scene identifier
- `background` - Background image
- `walkable_area` - Movement constraints
- `hotspots` - Interactive areas
- `characters` - Scene characters

### NavigationManager
**Location**: `src/scenes/navigation_manager.cr`  
**Purpose**: Pathfinding and navigation

**Responsibilities**:
- Generate navigation grid
- Calculate paths
- Validate movement
- Optimize paths

**Key Methods**:
- `setup_from_scene(scene)` - Initialize from scene
- `find_path(from, to)` - Calculate path
- `is_walkable?(point)` - Check walkability
- `get_nearest_walkable(point)` - Find nearest valid point

### HotspotManager
**Location**: `src/scenes/hotspot_manager.cr`  
**Purpose**: Interactive hotspot management

**Responsibilities**:
- Store and organize hotspots
- Handle hotspot detection
- Process interactions
- Manage hotspot states

**Key Methods**:
- `add_hotspot(hotspot)` - Add hotspot
- `get_hotspot_at(point)` - Find at position
- `set_enabled(name, enabled)` - Toggle hotspot
- `process_click(point)` - Handle click

### WalkableArea
**Location**: `src/scenes/walkable_area.cr`  
**Purpose**: Define walkable regions

**Responsibilities**:
- Store polygon regions
- Check point walkability
- Handle non-walkable obstacles
- Manage scale zones

**Key Methods**:
- `is_point_walkable?(point)` - Check walkability
- `is_area_walkable?(center, size)` - Check area
- `get_scale_at_y(y)` - Get character scale
- `constrain_to_walkable(from, to)` - Constrain movement

### BackgroundRenderer
**Location**: `src/scenes/background_renderer.cr`  
**Purpose**: Background rendering with scrolling

**Responsibilities**:
- Render scene background
- Handle camera offset
- Support parallax
- Manage background state

**Key Methods**:
- `render(camera_offset)` - Render background
- `set_parallax(factor)` - Set parallax
- `get_size()` - Get background size

### TransitionHelper
**Location**: `src/scenes/transition_helper.cr`  
**Purpose**: Scene transition effects

**Responsibilities**:
- Parse transition commands
- Execute transitions
- Handle door transitions
- Position characters

**Key Methods**:
- `parse_transition_action(action)` - Parse command
- `execute_transition(params)` - Execute effect
- `get_transition_duration(type)` - Get duration

---

## Character Components

### Character
**Location**: `src/characters/character.cr`  
**Purpose**: Base character coordinator

**Responsibilities**:
- Coordinate character components
- Manage character state
- Handle character updates
- Process character logic

**Key Components**:
- `animation_controller` - Animation management
- `sprite_controller` - Sprite rendering
- `movement_controller` - Movement logic
- `state_manager` - State machine

### AnimationController
**Location**: `src/characters/animation_controller.cr`  
**Purpose**: Character animation management

**Responsibilities**:
- Manage animation states
- Handle transitions
- Control playback
- Sync with movement

**Key Methods**:
- `play(animation_name)` - Play animation
- `set_direction(direction)` - Set facing
- `update(dt)` - Update animation
- `get_current_frame()` - Current frame

### MovementController
**Location**: `src/characters/movement_controller.cr`  
**Purpose**: Character movement and pathfinding

**Responsibilities**:
- Execute movement
- Follow paths
- Handle collisions
- Smooth movement

**Key Methods**:
- `move_to(target)` - Move to position
- `follow_path(path)` - Follow path
- `stop()` - Stop movement
- `update(dt)` - Update position

### CharacterStateManager
**Location**: `src/characters/character_state_manager.cr`  
**Purpose**: Character behavior states

**States**:
- `Idle` - Standing still
- `Walking` - Moving
- `Talking` - In conversation
- `Interacting` - Using object
- `Scripted` - Script control

**Key Methods**:
- `change_state(new_state)` - Change state
- `can_transition_to?(state)` - Check validity
- `update(dt)` - Update state
- `get_current_state()` - Current state

### Player
**Location**: `src/characters/player.cr`  
**Purpose**: Player-specific functionality

**Additional Features**:
- Click handling
- Inventory interaction
- Save/load support
- Player preferences

### NPC
**Location**: `src/characters/npc.cr`  
**Purpose**: Non-player character behaviors

**Additional Features**:
- AI behaviors
- Dialog trees
- Scheduled actions
- Interaction responses

---

## UI Components

### UIManager
**Location**: `src/ui/ui_manager.cr`  
**Purpose**: UI system coordinator

**Responsibilities**:
- Manage UI elements
- Handle UI updates
- Process UI input
- Coordinate rendering

**Key Components**:
- `dialog_manager` - Dialog boxes
- `menu_system` - Game menus
- `status_bar` - Status display
- `cursor_manager` - Cursor handling

### DialogManager
**Location**: `src/ui/dialog_manager.cr`  
**Purpose**: Dialog box rendering and text

**Responsibilities**:
- Display dialog boxes
- Handle text wrapping
- Manage dialog queue
- Support portraits

**Key Methods**:
- `show_dialog(text, character)` - Show dialog
- `close_dialog()` - Close current
- `is_dialog_active?()` - Check state
- `update(dt)` - Update display

### MenuSystem
**Location**: `src/ui/menu_system.cr`  
**Purpose**: Modular menu framework

**Components**:
- **MenuInputHandler** - Input processing
- **MenuRenderer** - Visual rendering
- **MenuNavigator** - Navigation logic
- **ConfigurationManager** - Settings

**Key Methods**:
- `show_menu(menu_type)` - Display menu
- `navigate(direction)` - Navigate items
- `select_current()` - Select item
- `close_menu()` - Close menu

### VerbCoin
**Location**: `src/ui/verb_coin.cr`  
**Purpose**: Context-sensitive action menu

**Responsibilities**:
- Display verb options
- Handle verb selection
- Position around target
- Animate appearance

**Verbs**:
- Look at
- Talk to
- Use
- Pick up
- Open/Close
- Push/Pull

### StatusBar
**Location**: `src/ui/status_bar.cr`  
**Purpose**: Game information display

**Displays**:
- Current location
- Score/points
- Game time
- Custom messages

### CursorManager
**Location**: `src/ui/cursor_manager.cr`  
**Purpose**: Context-aware cursor system

**Cursor States**:
- Default
- Hotspot hover
- Character hover
- Inventory item
- Verb selected

### FloatingDialogManager
**Location**: `src/ui/floating_dialog_manager.cr`  
**Purpose**: Speech bubbles and floating text

**Features**:
- Position above character
- Auto-dismiss timing
- Multiple active dialogs
- Screen edge handling

---

## Navigation Components

### Pathfinding
**Location**: `src/navigation/pathfinding.cr`  
**Purpose**: Main pathfinding coordinator

**Responsibilities**:
- Coordinate pathfinding components
- Execute A* algorithm
- Optimize paths
- Handle edge cases

### NavigationGrid
**Location**: `src/navigation/navigation_grid.cr`  
**Purpose**: Grid-based navigation mesh

**Features**:
- Dynamic grid generation
- Obstacle integration
- Cell state management
- Neighbor calculation

### AStarAlgorithm
**Location**: `src/navigation/astar_algorithm.cr`  
**Purpose**: Core A* implementation

**Features**:
- Optimal pathfinding
- Configurable heuristics
- Early termination
- Path reconstruction

### HeuristicCalculator
**Location**: `src/navigation/heuristic_calculator.cr`  
**Purpose**: Distance calculation strategies

**Implementations**:
- Manhattan distance
- Euclidean distance
- Diagonal distance
- Custom heuristics

### MovementValidator
**Location**: `src/navigation/movement_validator.cr`  
**Purpose**: Movement rule validation

**Validates**:
- Diagonal movement
- Corner cutting
- Character size
- Movement cost

### PathOptimizer
**Location**: `src/navigation/path_optimizer.cr`  
**Purpose**: Path smoothing and optimization

**Optimizations**:
- Remove redundant waypoints
- Smooth corners
- Straighten paths
- Reduce path length

---

## Graphics Components

### Camera
**Location**: `src/graphics/camera.cr`  
**Purpose**: Viewport and scrolling management

**Features**:
- Smooth scrolling
- Target following
- Boundary constraints
- Zoom support

**Key Methods**:
- `follow(target)` - Follow target
- `set_position(position)` - Set position
- `apply_transform()` - Apply to rendering
- `screen_to_world(point)` - Convert coordinates

### AnimatedSprite
**Location**: `src/graphics/animated_sprite.cr`  
**Purpose**: Sprite animation system

**Features**:
- Frame-based animation
- Multiple animations
- Playback control
- Event callbacks

### ParticleSystem
**Location**: `src/graphics/particle_system.cr`  
**Purpose**: Particle effects

**Effects**:
- Rain/Snow
- Smoke
- Sparkles
- Custom emitters

### TransitionManager
**Location**: `src/graphics/transition_manager.cr`  
**Purpose**: Scene transition effects

**Effects**:
- Fade
- Swirl
- Pixelate
- Slide
- Custom shaders

### DisplayManager
**Location**: `src/graphics/display_manager.cr`  
**Purpose**: Resolution and scaling

**Features**:
- Resolution independence
- Aspect ratio handling
- Fullscreen support
- Coordinate transformation

---

## Audio Components

### AudioManager
**Location**: `src/audio/audio_manager.cr`  
**Purpose**: Main audio coordinator

**Responsibilities**:
- Initialize audio system
- Manage audio resources
- Control global volume
- Handle audio state

### SoundEffectManager
**Location**: `src/audio/sound_effect_manager.cr`  
**Purpose**: Sound effect playback

**Features**:
- Spatial audio
- Volume control
- Effect caching
- Concurrent playback

### MusicManager
**Location**: `src/audio/music_manager.cr`  
**Purpose**: Background music control

**Features**:
- Crossfading
- Looping
- Dynamic music
- Playlist support

### AmbientSoundManager
**Location**: `src/audio/ambient_sound_manager.cr`  
**Purpose**: Environmental audio

**Features**:
- Positional sounds
- Area-based audio
- Dynamic volume
- Multiple layers

### FootstepSystem
**Location**: `src/audio/footstep_system.cr`  
**Purpose**: Surface-based footsteps

**Surface Types**:
- Wood
- Stone
- Grass
- Metal
- Water

---

## Scripting Components

### ScriptEngine
**Location**: `src/scripting/script_engine.cr`  
**Purpose**: Main Lua scripting interface

**Responsibilities**:
- Initialize Lua VM
- Execute scripts
- Handle errors
- Manage contexts

### LuaEnvironment
**Location**: `src/scripting/lua_environment.cr`  
**Purpose**: Lua VM management

**Features**:
- Sandboxed execution
- Memory limits
- Error handling
- State management

### ScriptAPIRegistry
**Location**: `src/scripting/script_api_registry.cr`  
**Purpose**: Crystal-to-Lua bindings

**API Categories**:
- Scene API
- Character API
- UI API
- Game state API
- Audio API

### EventSystem
**Location**: `src/scripting/event_system.cr`  
**Purpose**: Event-driven communication

**Features**:
- Event registration
- Event emission
- Handler priorities
- Event filtering

**Common Events**:
- `scene_changed`
- `quest_completed`
- `item_collected`
- `dialog_finished`
- `cutscene_ended`

---

## Component Integration Examples

### Scene Loading Flow
```
SceneManager.load_scene("hallway")
  → Load YAML configuration
  → Create Scene instance
  → Initialize components:
    - BackgroundRenderer
    - HotspotManager
    - NavigationManager
    - WalkableArea
  → Execute scene script
  → Add to active scenes
```

### Character Movement Flow
```
Player clicks position
  → InputManager routes to Scene
  → Scene checks hotspot/character
  → If walkable: Player.move_to(position)
    → MovementController.calculate_path()
    → NavigationManager.find_path()
    → Follow path with updates
```

### Dialog Display Flow
```
Script: show_dialog("Hello!")
  → ScriptEngine calls DialogManager
  → DialogManager creates dialog box
  → Positions based on character
  → Handles text wrapping
  → Displays with animation
  → Auto-dismiss or wait for input
```

This component reference provides a comprehensive overview of all major components in the Point & Click Engine. Each component is designed to be modular, testable, and reusable, following the engine's architectural principles.