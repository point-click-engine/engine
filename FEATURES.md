# Point & Click Engine - Feature Documentation

This document provides detailed information about all features available in the Point & Click Engine.

## Table of Contents

1. [Core Systems](#core-systems)
2. [Graphics and Rendering](#graphics-and-rendering)
3. [Character System](#character-system)
4. [Dialog System](#dialog-system)
5. [Inventory System](#inventory-system)
6. [Navigation and Pathfinding](#navigation-and-pathfinding)
7. [Cutscene System](#cutscene-system)
8. [Audio System](#audio-system)
9. [Localization](#localization)
10. [Save/Load System](#save-load-system)
11. [Asset Management](#asset-management)
12. [Scripting](#scripting)
13. [Scene Editor](#scene-editor)

## Core Systems

### Engine Architecture

The engine follows a modular architecture with clear separation of concerns:

```crystal
# Main game loop
game = PointClickEngine::Core::Engine.new(800, 600, "My Game")
game.run
```

### GameObject Base Class

All game entities inherit from GameObject:

```crystal
class MyObject < PointClickEngine::Core::GameObject
  def update(dt : Float32)
    # Update logic
  end
  
  def draw
    # Rendering logic
  end
end
```

## Graphics and Rendering

### Display Manager

Handles adaptive resolution scaling:

```crystal
display = PointClickEngine::Graphics::DisplayManager.new(
  base_width: 320,
  base_height: 240,
  window_width: 1280,
  window_height: 960
)

# Everything scales automatically
display.scale_factor # => 4.0
```

### Animated Sprites

Support for sprite sheet animations:

```crystal
sprite = PointClickEngine::Graphics::AnimatedSprite.new(
  position: RL::Vector2.new(x: 100, y: 100),
  frame_width: 32,
  frame_height: 48,
  frame_count: 8
)

sprite.load_texture("hero_walk.png")
sprite.frame_speed = 0.1
sprite.play
```

### Particle System

Dynamic particle effects:

```crystal
particles = PointClickEngine::Graphics::ParticleSystem.new(500)
particles.emit(
  position: RL::Vector2.new(x: 400, y: 300),
  count: 50,
  velocity_range: {-100.0, 100.0},
  lifetime_range: {1.0, 3.0},
  color: RL::Color.new(r: 255, g: 200, b: 0, a: 255)
)
```

### Shader System

Custom visual effects with GLSL:

```crystal
shader_system = PointClickEngine::Graphics::Shaders::ShaderSystem.new

# Load shader
shader_system.load_shader(:blur, "shaders/blur.frag")

# Set uniforms
shader_system.set_value(:blur, "blur_amount", 0.5f32)

# Apply shader
shader_system.set_active(:blur)
shader_system.begin_mode
scene.draw
shader_system.end_mode
```

## Character System

### Base Character Class

```crystal
character = PointClickEngine::Characters::Character.new(
  name: "Hero",
  position: RL::Vector2.new(x: 100, y: 300),
  size: RL::Vector2.new(x: 32, y: 48)
)

# Animation states
character.add_animation("idle", start_frame: 0, frame_count: 2, speed: 0.5)
character.add_animation("walk_right", start_frame: 2, frame_count: 4, speed: 0.1)

# Movement
character.walk_to(RL::Vector2.new(x: 400, y: 300))
```

### AI Behaviors

NPCs can have different AI behaviors:

```crystal
# Patrol between waypoints
patrol = PointClickEngine::Characters::AI::PatrolBehavior.new(
  waypoints: [
    RL::Vector2.new(x: 100, y: 100),
    RL::Vector2.new(x: 300, y: 100),
    RL::Vector2.new(x: 300, y: 300)
  ]
)

# Random wandering
wander = PointClickEngine::Characters::AI::RandomWalkBehavior.new(
  radius: 100.0,
  wait_time: 2.0
)

# Follow player
follow = PointClickEngine::Characters::AI::FollowBehavior.new(
  target: player,
  min_distance: 50.0
)

npc.behavior = patrol
```

### Scriptable Characters

Characters that can be controlled via Lua scripts:

```crystal
scriptable_npc = PointClickEngine::Characters::ScriptableCharacter.new(
  name: "Wizard",
  position: RL::Vector2.new(x: 200, y: 200),
  script_path: "scripts/wizard_ai.lua"
)
```

## Dialog System

### Dialog Trees

Complex branching conversations:

```crystal
tree = PointClickEngine::DialogTree.new("merchant_dialog")

# Create nodes
greeting = PointClickEngine::DialogNode.new("start", "Welcome to my shop!")
greeting.character_name = "Merchant"

# Add choices
buy_choice = PointClickEngine::DialogChoice.new("I'd like to buy something", "shop_menu")
buy_choice.conditions = ["gold >= 10"]  # Only show if player has gold
buy_choice.once_only = true  # Can only select once

info_choice = PointClickEngine::DialogChoice.new("Tell me about this town", "town_info")

greeting.add_choice(buy_choice)
greeting.add_choice(info_choice)

tree.add_node(greeting)

# Start conversation
tree.start_conversation("start")
```

### Dialog Variables

Track conversation state:

```crystal
tree.set_variable("talked_to_merchant", true)
tree.set_variable("quest_stage", 2)

# Use in conditions
choice.conditions = ["quest_stage >= 2", "has_key == true"]
```

## Inventory System

### Advanced Item Management

```crystal
# Create items
sword = PointClickEngine::Inventory::InventoryItem.new(
  name: "Iron Sword",
  description: "A sturdy iron sword"
)
sword.icon_path = "items/sword.png"
sword.stackable = false
sword.max_stack = 1

# Combinable items
rope = PointClickEngine::Inventory::InventoryItem.new("Rope", "A length of rope")
hook = PointClickEngine::Inventory::InventoryItem.new("Hook", "A metal hook")

rope.combinable_with = ["Hook"]
rope.combine_actions = {"Hook" => "create_grappling_hook"}

# Item usage
key.usable_on = ["door", "chest", "gate"]

# Inventory system
inventory = PointClickEngine::Inventory::InventorySystem.new
inventory.add_item(sword)

# Handle combinations
inventory.on_items_combined = ->(item1, item2, action) {
  case action
  when "create_grappling_hook"
    inventory.remove_item(item1)
    inventory.remove_item(item2)
    grappling_hook = PointClickEngine::Inventory::InventoryItem.new(
      "Grappling Hook",
      "Perfect for climbing"
    )
    inventory.add_item(grappling_hook)
  end
}
```

## Navigation and Pathfinding

### A* Pathfinding

```crystal
# Create navigation grid
nav_grid = PointClickEngine::Navigation::NavigationGrid.new(
  width: 25,    # Grid cells wide
  height: 19,   # Grid cells tall
  cell_size: 32 # Pixels per cell
)

# Mark obstacles
nav_grid.set_walkable(10, 10, false)  # Wall
nav_grid.set_walkable(11, 10, false)
nav_grid.set_walkable(12, 10, false)

# Create obstacles from hotspots
scene.hotspots.each do |hotspot|
  if hotspot.blocks_movement
    grid_x, grid_y = nav_grid.world_to_grid(hotspot.position.x, hotspot.position.y)
    nav_grid.set_walkable(grid_x, grid_y, false)
  end
end

# Find path
pathfinder = PointClickEngine::Navigation::Pathfinding.new(nav_grid)
path = pathfinder.find_path(
  start_pos: character.position,
  end_pos: click_position
)

# Character follows path
if path
  character.follow_path(path)
end
```

### Navigation Visualization

```crystal
# Debug mode shows navigation grid
if game.debug_mode
  nav_grid.draw_debug
end
```

## Cutscene System

### Creating Cutscenes

```crystal
cutscene = PointClickEngine::Cutscenes::Cutscene.new("intro_cutscene")

# Chain actions
cutscene.fade_in(1.0)
cutscene.wait(0.5)
cutscene.move_character(hero, RL::Vector2.new(x: 300, y: 200), use_pathfinding: true)
cutscene.dialog(hero, "Where am I?", 3.0)
cutscene.wait(1.0)
cutscene.dialog(wizard, "Welcome to the Crystal Kingdom!")
cutscene.play_sound("magic_sparkle")
cutscene.spawn_particles(RL::Vector2.new(x: 400, y: 200), "sparkle")
cutscene.wait(2.0)
cutscene.fade_out(1.0)
cutscene.change_scene("throne_room")

# Make unskippable
cutscene.skippable = false

# Callback when complete
cutscene.on_complete = ->{ game.unlock_achievement("intro_watched") }

# Play cutscene
game.cutscene_manager.play(cutscene)
```

### Custom Cutscene Actions

```crystal
class CustomAction < PointClickEngine::Cutscenes::CutsceneAction
  def initialize(@effect_name : String)
    super()
  end
  
  def start
    # Initialize effect
  end
  
  def update(dt : Float32) : Bool
    # Update effect
    # Return true when complete
    @elapsed_time >= 2.0
  end
  
  def draw
    # Draw effect
  end
end

cutscene.add_action(CustomAction.new("lightning"))
```

## Audio System

### Sound Management

```crystal
audio = PointClickEngine::AudioManager.new

# Load sounds
audio.load_sound_effect("footstep", "sounds/footstep.wav")
audio.load_sound_effect("door_open", "sounds/door_creak.wav")
audio.load_music("theme", "music/main_theme.ogg")

# Play sounds
audio.play_sound_effect("footstep")
audio.play_music("theme", loop: true)

# Volume control
audio.set_master_volume(0.8)
audio.set_sfx_volume(0.6)
audio.set_music_volume(0.7)

# Mute functionality
audio.toggle_mute
audio.is_muted? # => true
```

### Audio Fallback

The audio system gracefully handles missing audio libraries:

```crystal
# Compile with audio support
crystal build game.cr -Dwith_audio

# Without audio support, all audio calls are silently ignored
# Game runs normally without sound
```

## Localization

### Translation Management

```crystal
# Setup localization
i18n = PointClickEngine::Localization::LocalizationManager.instance
i18n.load_from_file("locales/translations.yml")
i18n.set_locale(PointClickEngine::Localization::Locale::Fr_FR)

# Use translations
dialog.text = i18n.get("dialog.greeting")  # "Bonjour!"
item.name = i18n.get("items.sword")        # "Épée"

# With parameters
text = i18n.get("messages.items_found", {"count" => 3})  # "3 objets trouvés"

# Pluralization
text = i18n.get_plural("items.count", count)
# count = 1: "1 item"
# count = 5: "5 items"
```

### Translation File Format

```yaml
# locales/translations.yml
en-us:
  dialog:
    greeting: "Hello!"
    farewell: "Goodbye!"
  items:
    sword: "Sword"
    key: "Key"
    count:
      one: "{{count}} item"
      other: "{{count}} items"
      
fr-fr:
  dialog:
    greeting: "Bonjour!"
    farewell: "Au revoir!"
  items:
    sword: "Épée"
    key: "Clé"
    count:
      one: "{{count}} objet"
      other: "{{count}} objets"
```

## Save/Load System

### Game State Persistence

```crystal
# Save game
save_data = PointClickEngine::SaveSystem.save_game(game, "slot1")

# Save includes:
# - Current scene and position
# - Inventory items
# - Dialog variables
# - Quest progress
# - Character states
# - Hotspot states

# Load game
PointClickEngine::SaveSystem.load_game(game, "slot1")

# List saves
saves = PointClickEngine::SaveSystem.get_save_files
saves.each do |save_name|
  info = PointClickEngine::SaveSystem.get_save_info(save_name)
  puts "#{save_name}: #{info.scene_name} - #{info.play_time}"
end

# Delete save
PointClickEngine::SaveSystem.delete_save("slot1")
```

### Auto-save

```crystal
# Enable auto-save
game.enable_autosave(interval: 300.0)  # Every 5 minutes

# Quick save/load
game.on_key_pressed = ->(key) {
  case key
  when .f5
    PointClickEngine::SaveSystem.save_game(game, "quicksave")
    game.show_notification("Game Saved")
  when .f9
    PointClickEngine::SaveSystem.load_game(game, "quicksave")
    game.show_notification("Game Loaded")
  end
}
```

## Asset Management

### Asset Manager

```crystal
assets = PointClickEngine::AssetManager.new

# Load from directories
assets.add_search_path("assets")
assets.add_search_path("mods/awesome_mod/assets")

# Load from archives
assets.mount_archive("game_assets.zip")
assets.mount_archive("dlc_content.pak")

# Load assets (searches all paths/archives)
texture = assets.load_texture("sprites/hero.png")
sound = assets.load_sound("effects/explosion.wav")
font = assets.load_font("fonts/pixel.ttf", 16)

# Cache management
assets.clear_cache  # Free memory
assets.preload_directory("sprites/enemies")  # Load ahead of time
```

### Custom Asset Loaders

```crystal
# Register custom loader
assets.register_loader(".dialogue") do |path|
  DialogTree.from_yaml(File.read(path))
end

# Use custom asset
dialog = assets.load_asset("conversations/wizard.dialogue")
```

## Scripting

### Lua Integration

```crystal
# Initialize scripting
script_engine = PointClickEngine::ScriptEngine.new

# Register game objects
script_engine.register_game(game)
script_engine.register_scene(current_scene)
script_engine.register_inventory(inventory)

# Load scripts
script_engine.load_script("scripts/game_logic.lua")
script_engine.load_script("scripts/puzzles.lua")

# Call Lua functions
script_engine.call_function("on_game_start")
script_engine.call_function("check_puzzle", [player_answer])

# Get values from Lua
score = script_engine.get_global("player_score")
```

### Lua Script Example

```lua
-- scripts/game_logic.lua

function on_door_click()
  if game:has_item("key") then
    game:remove_item("key")
    game:change_scene("next_room")
    game:play_sound("door_open")
  else
    game:show_message("The door is locked. You need a key.")
  end
end

function on_npc_talk()
  local times_talked = game:get_variable("wizard_talks") or 0
  times_talked = times_talked + 1
  game:set_variable("wizard_talks", times_talked)
  
  if times_talked == 1 then
    game:show_dialog("wizard", "Welcome, traveler!")
  elseif times_talked < 5 then
    game:show_dialog("wizard", "Good to see you again.")
  else
    game:show_dialog("wizard", "You sure are persistent...")
  end
end
```

## Scene Editor

### Editor Features

The built-in scene editor provides:

- **Visual Editing**: See changes in real-time
- **Multi-Selection**: Edit multiple objects at once
- **Property Panel**: Modify object properties
- **Tool Palette**: Various editing tools
- **Project Management**: Organize game assets
- **YAML Export**: Human-readable scene files
- **Code Generation**: Export to Crystal code

### Editor Workflow

1. **Create Project**
   - File → New Project
   - Choose project location
   - Set base resolution

2. **Design Scenes**
   - Import background images
   - Place hotspots
   - Add characters
   - Set up navigation mesh

3. **Configure Objects**
   - Set hotspot interactions
   - Define cursor types
   - Add descriptions
   - Link to scripts

4. **Test Scene**
   - Press F5 to play test
   - Click hotspots to verify
   - Check pathfinding

5. **Export**
   - Save as YAML
   - Export to code
   - Generate assets

### Editor Shortcuts

- **Ctrl+N**: New scene
- **Ctrl+O**: Open scene
- **Ctrl+S**: Save scene
- **Ctrl+Z/Y**: Undo/Redo
- **Delete**: Delete selected
- **Ctrl+D**: Duplicate selected
- **Ctrl+A**: Select all
- **G**: Toggle grid
- **X**: Toggle snap
- **F1**: Debug mode
- **F5**: Test play

---

This comprehensive guide covers all major features of the Point & Click Engine. For specific implementation details, refer to the API documentation and example projects.