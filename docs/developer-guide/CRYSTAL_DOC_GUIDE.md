# Crystal Documentation Guide for Point & Click Engine

This guide demonstrates how to write comprehensive documentation for the Point & Click Engine using Crystal's documentation system. The `crystal docs` tool will generate HTML documentation from these comments.

## Documentation Comment Syntax

Crystal uses special comment markers for documentation:
- `#` - Regular comments (not included in docs)
- `##` - Documentation comments for the next item
- `###` - Alternative doc comment style (rarely used)

## Complete Documentation Example

Here's a comprehensive example showing all documentation features:

```crystal
# Regular comment - not included in documentation
# This explains implementation details

## Main module for the Point & Click Engine framework.
##
## The `PointClickEngine` module is the top-level namespace containing all
## engine functionality. It provides a complete framework for building
## point-and-click adventure games with minimal code.
##
## ## Quick Start
##
## ```crystal
## require "point_click_engine"
##
## # Create a simple game
## engine = PointClickEngine::Core::Engine.new(800, 600, "My Game")
## engine.init
## engine.run
## ```
##
## ## Architecture
##
## The engine is organized into several key modules:
## - `Core` - Engine, game loop, and state management
## - `Scenes` - Scene graph and room management
## - `Characters` - Player and NPC systems
## - `UI` - User interface components
## - `Graphics` - Rendering and visual effects
##
## ## See Also
## - `Core::Engine` - Main engine class
## - `Scenes::Scene` - Scene management
## - [Getting Started Guide](https://docs.example.com/getting-started)
module PointClickEngine
  VERSION = "1.0.0"

  ## Base class for all interactive game objects.
  ##
  ## `GameObject` provides core functionality for objects that exist in
  ## the game world, including position, size, visibility, and interaction
  ## callbacks. All interactive elements inherit from this class.
  ##
  ## ## Properties
  ##
  ## - `position` - World position as a Vector2
  ## - `size` - Bounding box dimensions
  ## - `visible` - Whether the object is rendered
  ## - `interactive` - Whether the object responds to input
  ##
  ## ## Basic Usage
  ##
  ## ```crystal
  ## class Door < GameObject
  ##   def initialize(position)
  ##     super(position, Vector2.new(100, 200))
  ##     @description = "A sturdy wooden door"
  ##   end
  ##
  ##   def on_interact(player)
  ##     if player.has_item?("key")
  ##       change_scene("next_room")
  ##     else
  ##       show_message("The door is locked")
  ##     end
  ##   end
  ## end
  ## ```
  ##
  ## ## Advanced Features
  ##
  ## ### Custom Interaction Handlers
  ##
  ## ```crystal
  ## door = Door.new(Vector2.new(400, 300))
  ## door.on_interact do |player|
  ##   # Custom interaction logic
  ##   puts "Player #{player.name} interacted with door"
  ## end
  ## ```
  ##
  ## ### State Management
  ##
  ## ```crystal
  ## class Chest < GameObject
  ##   property opened : Bool = false
  ##
  ##   def on_interact(player)
  ##     unless @opened
  ##       @opened = true
  ##       player.add_item("treasure")
  ##       play_animation("chest_open")
  ##     end
  ##   end
  ## end
  ## ```
  ##
  ## ## Common Gotchas
  ##
  ## 1. **Position is mutable**: Changes to position affect the object immediately
  ##    ```crystal
  ##    obj.position.x += 10  # Moves object right by 10 pixels
  ##    ```
  ##
  ## 2. **Visibility doesn't affect interaction**: Set `interactive = false` to disable
  ##    ```crystal
  ##    obj.visible = false      # Still clickable!
  ##    obj.interactive = false  # Now unclickable
  ##    ```
  ##
  ## 3. **Bounding box origin**: Position refers to top-left corner, not center
  ##    ```crystal
  ##    # Center an object at screen center (800x600 screen)
  ##    obj.position = Vector2.new(400 - obj.size.x/2, 300 - obj.size.y/2)
  ##    ```
  ##
  ## ## Performance Considerations
  ##
  ## - Objects are checked for interaction every frame when interactive
  ## - Use `interactive = false` for decorative objects
  ## - Consider grouping static objects into the background
  ##
  ## ## Subclassing Guidelines
  ##
  ## When creating custom game objects:
  ## 1. Always call `super` in `initialize`
  ## 2. Override `on_interact` for click handling
  ## 3. Override `on_look` for examine actions
  ## 4. Override `update(dt)` for per-frame logic
  ## 5. Override `draw` for custom rendering
  ##
  ## NOTE: This is an abstract class - you must implement interaction methods
  abstract class GameObject
    ## Position in world coordinates
    property position : Vector2

    ## Bounding box size for interaction
    property size : Vector2

    ## Whether this object is rendered
    property visible : Bool = true

    ## Whether this object can be interacted with
    property interactive : Bool = true

    ## Description shown when examining this object
    property description : String = ""

    ## Creates a new game object at the specified position.
    ##
    ## - *position* : World position (top-left corner)
    ## - *size* : Bounding box dimensions
    ## - *visible* : Initial visibility state (default: true)
    ## - *interactive* : Whether object can be clicked (default: true)
    ##
    ## ```crystal
    ## obj = GameObject.new(
    ##   Vector2.new(100, 200),
    ##   Vector2.new(50, 50),
    ##   visible: true,
    ##   interactive: true
    ## )
    ## ```
    def initialize(@position : Vector2, @size : Vector2, 
                   @visible = true, @interactive = true)
    end

    ## Called when the player interacts with this object.
    ##
    ## Override this method to define custom interaction behavior.
    ## Common interactions include picking up items, opening doors,
    ## or triggering conversations.
    ##
    ## - *interactor* : The character performing the interaction (usually the player)
    ##
    ## ```crystal
    ## def on_interact(interactor)
    ##   interactor.say("I can't use that!")
    ## end
    ## ```
    ##
    ## GOTCHA: This is called even if the object is not visible!
    ## Check visibility in your implementation if needed.
    abstract def on_interact(interactor : Character)

    ## Called when the player examines/looks at this object.
    ##
    ## Override to provide custom examine behavior. Default
    ## implementation shows the description property.
    ##
    ## - *examiner* : The character examining the object
    ##
    ## ```crystal
    ## def on_look(examiner)
    ##   if @opened
    ##     examiner.say("An empty chest")
    ##   else
    ##     examiner.say("A mysterious chest")
    ##   end
    ## end
    ## ```
    def on_look(examiner : Character)
      examiner.say(@description) unless @description.empty?
    end

    ## Updates the object's state.
    ##
    ## Called once per frame. Override for animated or dynamic objects.
    ##
    ## - *dt* : Delta time in seconds since last frame
    ##
    ## ```crystal
    ## def update(dt)
    ##   # Bobbing animation
    ##   @position.y += Math.sin(Time.now.to_f) * 50 * dt
    ## end
    ## ```
    ##
    ## TIP: Always multiply movements by dt for frame-rate independence
    def update(dt : Float32)
      # Base implementation does nothing
    end

    ## Checks if a point is within this object's bounding box.
    ##
    ## Used by the engine for mouse interaction detection.
    ##
    ## - *point* : The point to test (usually mouse position)
    ## - Returns true if the point is inside the bounding box
    ##
    ## ```crystal
    ## if object.contains_point?(mouse_pos)
    ##   object.on_interact(player)
    ## end
    ## ```
    def contains_point?(point : Vector2) : Bool
      point.x >= @position.x &&
      point.x <= @position.x + @size.x &&
      point.y >= @position.y &&
      point.y <= @position.y + @size.y
    end
  end

  ## Represents errors that occur during game execution.
  ##
  ## `GameError` is the base exception type for all game-related errors.
  ## Catch this to handle all game errors, or catch specific subtypes
  ## for more granular error handling.
  ##
  ## ## Error Hierarchy
  ##
  ## - `GameError` - Base class
  ##   - `SceneError` - Scene loading/management errors  
  ##   - `AssetError` - Asset loading failures
  ##   - `ScriptError` - Lua scripting errors
  ##   - `SaveError` - Save/load failures
  ##
  ## ## Usage Examples
  ##
  ## ### Basic Error Handling
  ##
  ## ```crystal
  ## begin
  ##   engine.change_scene("dungeon")
  ## rescue e : SceneError
  ##   puts "Failed to load scene: #{e.message}"
  ##   engine.change_scene("error_room")
  ## end
  ## ```
  ##
  ## ### Comprehensive Error Handling
  ##
  ## ```crystal
  ## begin
  ##   game.risky_operation
  ## rescue e : AssetError
  ##   # Handle missing assets
  ##   use_placeholder_asset
  ## rescue e : ScriptError
  ##   # Handle script failures
  ##   disable_scripting
  ## rescue e : GameError
  ##   # Handle any other game error
  ##   show_error_dialog(e.message)
  ## rescue e : Exception
  ##   # Handle non-game errors
  ##   crash_gracefully(e)
  ## end
  ## ```
  ##
  ## ## Creating Custom Errors
  ##
  ## ```crystal
  ## class InventoryError < GameError
  ##   def initialize(item_name : String)
  ##     super("Cannot add item '#{item_name}': Inventory full")
  ##   end
  ## end
  ##
  ## raise InventoryError.new("sword") if inventory.full?
  ## ```
  class GameError < Exception
  end

  ## Defines the possible states for a character.
  ##
  ## Character states control animation, behavior, and available
  ## interactions. The engine automatically manages state transitions
  ## based on character actions.
  ##
  ## ## State Descriptions
  ##
  ## - `Idle` - Default state, character is stationary
  ## - `Walking` - Character is moving to a destination  
  ## - `Talking` - Character is engaged in dialogue
  ## - `Interacting` - Character is using an object
  ## - `Thinking` - Character is in a thinking animation
  ##
  ## ## State Transitions
  ##
  ## ```crystal
  ## character.walk_to(target)  # Idle -> Walking
  ## # Arrives at target        # Walking -> Idle
  ## character.say("Hello!")    # Idle -> Talking
  ## # Finishes dialogue        # Talking -> Idle
  ## ```
  ##
  ## ## Checking States
  ##
  ## ```crystal
  ## case character.state
  ## when .idle?
  ##   # Character can accept new commands
  ## when .walking?
  ##   # Character is busy moving
  ## when .talking?
  ##   # Character is in conversation
  ## end
  ## ```
  ##
  ## GOTCHA: Some states block interactions. Check `can_interact?`
  ## instead of checking state directly.
  enum CharacterState
    Idle
    Walking  
    Talking
    Interacting
    Thinking

    ## Checks if the character can accept new commands.
    ##
    ## Returns true only for states that allow interruption.
    ##
    ## ```crystal
    ## if character.state.interruptible?
    ##   character.walk_to(new_target)
    ## end
    ## ```
    def interruptible? : Bool
      idle? || walking?
    end
  end

  ## Configuration structure for sprite animations.
  ##
  ## Defines frame ranges, timing, and playback options for
  ## character and object animations. Used by the animation system
  ## to control sprite playback.
  ##
  ## ## Basic Usage
  ##
  ## ```crystal
  ## idle_anim = AnimationData.new(
  ##   start_frame: 0,
  ##   frame_count: 1,
  ##   frame_speed: 0.1,
  ##   loop: true
  ## )
  ##
  ## walk_anim = AnimationData.new(
  ##   start_frame: 1,
  ##   frame_count: 4,
  ##   frame_speed: 0.15,
  ##   loop: true
  ## )
  ## ```
  ##
  ## ## Animation Timing
  ##
  ## Frame speed is in seconds per frame:
  ## - 0.1 = 10 FPS animation
  ## - 0.033 = ~30 FPS animation  
  ## - 0.016 = ~60 FPS animation
  ##
  ## ## Advanced Configuration
  ##
  ## ```crystal
  ## # One-shot animation
  ## death_anim = AnimationData.new(
  ##   start_frame: 20,
  ##   frame_count: 5,
  ##   frame_speed: 0.2,
  ##   loop: false  # Plays once and stops
  ## )
  ##
  ## # Ping-pong animation (requires custom animator)
  ## breathe_anim = AnimationData.new(
  ##   start_frame: 0,
  ##   frame_count: 3,
  ##   frame_speed: 0.3,
  ##   loop: true,
  ##   ping_pong: true  # Forward then backward
  ## )
  ## ```
  struct AnimationData
    ## First frame index in the sprite sheet
    getter start_frame : Int32

    ## Number of frames in this animation
    getter frame_count : Int32

    ## Time in seconds between frame changes
    getter frame_speed : Float32

    ## Whether animation repeats after completion
    getter loop : Bool

    ## Creates animation data with specified parameters.
    ##
    ## - *start_frame* : First frame index (0-based)
    ## - *frame_count* : Total frames in sequence  
    ## - *frame_speed* : Seconds per frame
    ## - *loop* : Whether to repeat (default: true)
    ##
    ## ```crystal
    ## # Create a 4-frame walk cycle at 10 FPS
    ## AnimationData.new(0, 4, 0.1, true)
    ## ```
    ##
    ## NOTE: Frame indices are calculated as:
    ## `row * columns + column` in the sprite sheet
    def initialize(@start_frame : Int32, @frame_count : Int32,
                   @frame_speed : Float32, @loop : Bool = true)
    end

    ## Calculates the current frame based on elapsed time.
    ##
    ## - *elapsed_time* : Seconds since animation started
    ## - Returns the frame index to display
    ##
    ## ```crystal
    ## current_frame = anim_data.frame_at_time(1.5)
    ## sprite.source_rect = calculate_rect(current_frame)
    ## ```
    def frame_at_time(elapsed_time : Float32) : Int32
      return @start_frame if @frame_count == 1

      total_duration = @frame_count * @frame_speed
      
      if @loop
        time_in_cycle = elapsed_time % total_duration
      else
        time_in_cycle = Math.min(elapsed_time, total_duration - @frame_speed)
      end

      frame_offset = (time_in_cycle / @frame_speed).to_i
      @start_frame + frame_offset
    end
  end
end
```

## Documentation Best Practices

### 1. Module and Class Documentation

Always document modules and classes with:
- Brief one-line description
- Detailed explanation of purpose
- Usage examples
- Architecture notes when relevant

```crystal
## Manages save game data and persistence.
##
## The `SaveSystem` provides automatic and manual save functionality,
## supporting multiple save slots and cloud synchronization. Save data
## is stored in JSON format for easy debugging and modification.
##
## ## Features
## - Multiple save slots (default: 10)
## - Automatic saves on scene transitions
## - Quick save/load functionality
## - Save data compression
## - Steam Cloud integration (optional)
##
## ## Usage
## ```crystal
## SaveSystem.save_game("slot1", engine)
## SaveSystem.load_game("slot1", engine)
## ```
module SaveSystem
```

### 2. Method Documentation

Document all public methods with:
- Brief description
- Parameter explanations with types
- Return value description
- Usage examples
- Gotchas or warnings

```crystal
## Loads a game from the specified save slot.
##
## Restores complete game state including scene, inventory,
## variables, and character positions. Validates save data
## integrity before loading.
##
## - *slot_name* : Save slot identifier (e.g., "slot1", "autosave")
## - *engine* : Engine instance to restore state into
## - Returns true if load succeeded, false otherwise
##
## ```crystal
## if SaveSystem.load_game("quicksave", engine)
##   puts "Game loaded successfully"
## else
##   puts "Failed to load save"
## end
## ```
##
## WARNING: Loading a save will overwrite current game state!
## Consider prompting the user for confirmation.
##
## NOTE: Corrupted saves are automatically backed up before
## failing to load.
def self.load_game(slot_name : String, engine : Engine) : Bool
```

### 3. Property Documentation

Document properties that aren't self-explanatory:

```crystal
## Maximum distance in pixels for automatic interactions.
##
## When the player clicks on an interactive object beyond this
## distance, they will automatically walk closer before interacting.
## Set to 0 to disable automatic movement.
property interaction_distance : Float32 = 100.0

## Sprite tint color for visual effects.
##
## Useful for day/night cycles, damage indication, or mood lighting.
## Default white (255,255,255,255) applies no tint.
##
## ```crystal
## # Make character appear in shadow
## character.tint = Color.new(128, 128, 128, 255)
## ```
property tint : Color = Color::WHITE
```

### 4. Enum Documentation

Document enums and their values:

```crystal
## Defines available transition effects between scenes.
##
## Used by the `TransitionManager` to create smooth scene changes.
## Different effects suit different narrative moments.
enum TransitionEffect
  ## Instant scene change with no transition
  None

  ## Gradual fade through black
  ##
  ## Classic transition suitable for most scene changes.
  ## Duration controlled by `transition_duration`.
  FadeBlack

  ## Fade through white
  ##
  ## Good for dream sequences or flashbacks.
  FadeWhite

  ## Horizontal sliding transition
  ##
  ## The new scene slides in from the right.
  ## Creates a sense of lateral movement.
  SlideLeft

  ## Iris wipe effect (circle closing/opening)
  ##
  ## Vintage cartoon-style transition.
  ## Focuses attention on screen center.
  IrisWipe

  ## Dissolve with dithering pattern
  ##
  ## Retro pixel-art style transition.
  ## Uses ordered dithering for authentic look.
  Dissolve
end
```

### 5. Common Gotchas to Document

Always document these common issues:

1. **Mutable vs Immutable behavior**
   ```crystal
   ## NOTE: Position is mutable - changes affect the object immediately
   property position : Vector2
   ```

2. **Nil safety**
   ```crystal
   ## Returns the current scene, or nil if no scene is loaded.
   ##
   ## GOTCHA: Always check for nil before using:
   ## ```crystal
   ## if scene = engine.current_scene
   ##   scene.add_character(npc)
   ## end
   ## ```
   def current_scene : Scene?
   ```

3. **Performance implications**
   ```crystal
   ## Finds all objects within the specified radius.
   ##
   ## WARNING: O(n) complexity - avoid calling every frame!
   ## Consider using spatial partitioning for many objects.
   def find_objects_in_radius(center : Vector2, radius : Float32)
   ```

4. **Side effects**
   ```crystal
   ## Clears all game data and resets to initial state.
   ##
   ## WARNING: This is irreversible! All unsaved progress is lost.
   ## Side effects:
   ## - Clears all scenes from memory
   ## - Resets all game variables
   ## - Clears inventory
   ## - Stops all audio
   def reset_game
   ```

### 6. Cross-References

Use See Also sections and link related items:

```crystal
## Handles character pathfinding and movement.
##
## ## See Also
## - `NavigationGrid` - The underlying grid system
## - `Scene#setup_navigation` - Navigation initialization  
## - `Character#walk_to` - High-level movement API
## - [Pathfinding Guide](https://docs.example.com/pathfinding)
```

### 7. Code Examples

Provide realistic, runnable examples:

```crystal
## ## Complete Example
##
## ```crystal
## # Create a complete interactive scene
## scene = Scene.new("library")
## scene.load_background("assets/library.png")
##
## # Add walkable area
## walkable = WalkableArea.new
## walkable.add_polygon([
##   Vector2.new(100, 400),
##   Vector2.new(700, 400),
##   Vector2.new(700, 550),
##   Vector2.new(100, 550)
## ])
## scene.walkable_area = walkable
##
## # Add interactive bookshelf
## bookshelf = Hotspot.new(
##   name: "bookshelf",
##   position: Vector2.new(300, 200),
##   size: Vector2.new(200, 300)
## )
## bookshelf.on_interact do |player|
##   player.say("So many books to read!")
## end
## scene.add_hotspot(bookshelf)
##
## # Add the scene to engine
## engine.add_scene(scene)
## ```
```

### 8. Version and Deprecation Notes

Document API changes:

```crystal
## Plays a sound effect at the specified position.
##
## @deprecated Use `AudioManager.play_3d_sound` instead.
## This method will be removed in version 2.0.
##
## ```crystal
## # Old way (deprecated)
## play_sound_at("boom.wav", Vector2.new(400, 300))
##
## # New way
## AudioManager.play_3d_sound("boom.wav", Vector2.new(400, 300))
## ```
@[Deprecated("Use AudioManager.play_3d_sound instead")]
def play_sound_at(sound : String, position : Vector2)
```

## Running Crystal Docs

To generate documentation:

```bash
# Generate docs for your project
crystal docs

# Generate docs with custom options
crystal docs --output=docs/api --project-name="Point & Click Engine" --project-version=1.0.0

# Include private APIs (useful for internal documentation)
crystal docs --private

# Serve documentation locally
crystal docs --serve
```

## Tips for Great Documentation

1. **Write for your audience**: Assume readers know Crystal but not your engine
2. **Show, don't just tell**: Examples are worth 1000 words  
3. **Document the why**: Explain design decisions and use cases
4. **Be honest about limitations**: Document what doesn't work
5. **Keep it current**: Update docs when changing code
6. **Test your examples**: Ensure code snippets actually work
7. **Use consistent style**: Follow the same patterns throughout

## Common Patterns in Game Engine Docs

### System Overview
```crystal
## Audio management system for the Point & Click Engine.
##
## The `AudioManager` provides a high-level interface for:
## - Playing sound effects and music
## - 3D positional audio
## - Dynamic music layering  
## - Ambient soundscapes
##
## ## Architecture
## 
## The audio system uses Raylib's audio backend with custom
## mixing and effect processing. Audio resources are cached
## and reference counted for efficient memory usage.
##
## ## Basic Usage
## [examples...]
```

### Lifecycle Documentation
```crystal
## Called when the scene becomes active.
##
## Override this method to initialize scene-specific resources,
## start animations, or begin ambient sounds. This is called
## after all objects are loaded but before the first frame.
##
## ## Execution Order
## 1. Scene assets loaded
## 2. Objects instantiated  
## 3. `on_enter` called ← You are here
## 4. First frame rendered
##
## ```crystal
## def on_enter
##   super  # Don't forget to call super!
##   start_ambient_sound("wind.ogg")
##   @torch.start_flickering
## end
## ```
def on_enter
```

This comprehensive guide should help you document the Point & Click Engine to Crystal's high standards. Remember: good documentation makes your engine accessible and enjoyable to use!