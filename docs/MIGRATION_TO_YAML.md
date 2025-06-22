# Migration Guide: From Code-Based to YAML-Based Configuration

This guide helps you migrate existing Point & Click Engine games from the old code-based approach to the new YAML-based configuration system.

## Overview of Changes

### Before (Code-Based)
- ~1000 lines of Crystal code in main.cr
- Scenes created programmatically
- Hardcoded interactions and game logic
- Manual system initialization
- Mixed concerns (engine setup + game logic)

### After (YAML-Based)
- ~45 lines of Crystal code in main.cr
- Scenes defined in YAML files
- Logic in Lua scripts
- Automatic system initialization
- Clean separation of concerns

## Migration Steps

### Step 1: Create game_config.yaml

Create a `game_config.yaml` file with your game settings:

```yaml
game:
  title: "Your Game Title"  # From Engine.new
  version: "1.0.0"

window:
  width: 1024  # From Engine.new parameters
  height: 768
  target_fps: 60

# Extract player configuration
player:
  name: "Player"  # From Characters::Player.new
  sprite_path: "assets/sprites/player.png"
  sprite:
    frame_width: 56
    frame_height: 56
    columns: 8
    rows: 4

# List features your game uses
features:
  - verbs  # If you called engine.enable_verb_input
  - floating_dialogs  # If dm.enable_floating = true
  - portraits  # If dm.enable_portraits = true
  - shaders  # If you set up shaders
  - auto_save  # If you want auto-saving

# Asset paths
assets:
  scenes: ["scenes/*.yaml"]
  dialogs: ["dialogs/*.yaml"]
  quests: ["quests/*.yaml"]
  audio:
    music:
      # Extract from audio_manager.load_music calls
      main_theme: "assets/music/main_theme.ogg"
    sounds:
      # Extract from audio_manager.load_sound_effect calls
      click: "assets/sounds/effects/click.ogg"

# Extract from ConfigManager settings
settings:
  debug_mode: false
  master_volume: 0.8

# Extract initial game state
initial_state:
  flags:
    game_started: true
  variables:
    investigation_progress: 0

start_scene: "first_scene_name"
```

### Step 2: Convert Scene Creation to YAML

Replace code like this:
```crystal
scene = Scene.new("library")
scene.background = "assets/backgrounds/library.png"

# Add hotspots
bookshelf = Hotspot.new("bookshelf", 100, 200, 150, 300)
bookshelf.description = "Ancient books line the shelves"
bookshelf.on_click = -> do
  @engine.dialog_manager.try &.show_message("You find a book...")
end
scene.add_hotspot(bookshelf)

@engine.add_scene(scene)
```

With a YAML file `scenes/library.yaml`:
```yaml
name: library
background_path: assets/backgrounds/library.png
script_path: scripts/library.lua

hotspots:
  - name: bookshelf
    x: 100
    y: 200
    width: 150
    height: 300
    description: "Ancient books line the shelves"
```

### Step 3: Move Logic to Lua Scripts

Extract interaction logic to Lua scripts.

Replace Crystal code:
```crystal
hotspot.on_click = -> do
  if @engine.inventory.has_item?("key")
    @engine.dialog_manager.try &.show_message("You unlock the door!")
    @engine.inventory.remove_item("key")
    @engine.change_scene("next_room")
  else
    @engine.dialog_manager.try &.show_message("The door is locked.")
  end
end
```

With Lua script `scripts/library.lua`:
```lua
hotspot.on_click("door", function()
  if has_item("key") then
    show_message("You unlock the door!")
    remove_from_inventory("key")
    change_scene("next_room")
  else
    show_message("The door is locked.")
  end
end)
```

### Step 4: Convert Character Dialogs

Replace dialog code:
```crystal
@engine.dialog_manager.try &.show_dialog_choices("What to ask?", [
  "Tell me about the crystal",
  "Where should I look?",
  "Goodbye"
]) do |choice|
  case choice
  when 0
    show_message("The crystal is ancient...")
  when 1
    show_message("Try the library...")
  when 2
    # End dialog
  end
end
```

With YAML dialog `dialogs/butler_dialog.yaml`:
```yaml
id: butler_dialog
start_node: greeting

nodes:
  - id: greeting
    speaker: Butler
    text: "How may I help you?"
    choices:
      - text: "Tell me about the crystal"
        next: about_crystal
      - text: "Where should I look?"
        next: hint
      - text: "Goodbye"
        next: end

  - id: about_crystal
    speaker: Butler
    text: "The crystal is ancient..."
    next: greeting

  - id: hint
    speaker: Butler
    text: "Try the library..."
    next: greeting

  - id: end
    speaker: Butler
    text: "Good day."
```

### Step 5: Update Main File

Replace your entire main.cr with:
```crystal
require "../src/point_click_engine"

class YourGame
  property engine : PointClickEngine::Core::Engine
  
  def initialize
    config = PointClickEngine::Core::GameConfig.from_file("game_config.yaml")
    @engine = config.create_engine
    
    # Register any custom Lua functions
    register_custom_functions
    
    @engine.show_main_menu
  end
  
  def run
    @engine.run
  end
  
  private def register_custom_functions
    # Add game-specific Lua functions if needed
  end
end

game = YourGame.new
game.run
```

### Step 6: Organize Files

Create the proper directory structure:
```
your_game/
├── game_config.yaml
├── main.cr
├── scenes/
│   └── *.yaml (converted from code)
├── scripts/
│   └── *.lua (extracted logic)
├── dialogs/
│   └── *.yaml (converted dialogs)
├── quests/
│   └── *.yaml (if using quests)
├── items/
│   └── items.yaml (item definitions)
└── assets/
    └── (existing assets)
```

## Common Patterns

### Converting Item Creation

Before:
```crystal
key = InventoryItem.new("key", "A brass key")
key.load_icon("assets/items/key.png")
key.usable_on = ["door", "cabinet"]
```

After in `items/items.yaml`:
```yaml
items:
  key:
    name: key
    display_name: "Brass Key"
    description: "A brass key"
    icon_path: "assets/items/key.png"
    usable_on: ["door", "cabinet"]
```

### Converting Game State

Before:
```crystal
@game_state_manager.set_flag("has_key", true)
@game_state_manager.set_variable("health", 100)
```

After in Lua:
```lua
set_flag("has_key", true)
set_variable("health", 100)
```

### Converting Custom Handlers

Before:
```crystal
verb_system.register_verb_handler(VerbType::Use) do |hotspot, pos|
  # Custom use logic
end
```

After in Lua:
```lua
hotspot.on_verb("item_name", "use", function()
  -- Custom use logic
end)
```

## Validation Checklist

After migration, verify:

- [ ] Game starts without errors
- [ ] All scenes load correctly
- [ ] Hotspots are interactive
- [ ] Scripts execute properly
- [ ] Dialogs work as expected
- [ ] Inventory functions correctly
- [ ] Save/load works
- [ ] Audio plays properly

## Benefits After Migration

1. **Easier Maintenance** - Change game without recompiling
2. **Faster Development** - Hot reload Lua scripts
3. **Better Organization** - Clear file structure
4. **Easier Collaboration** - Non-programmers can edit YAML
5. **Smaller Codebase** - 95% less Crystal code

## Troubleshooting

### Scripts Not Loading
- Check `script_path` in scene YAML
- Ensure Lua syntax is correct
- Check function names match

### Missing Assets
- Verify paths in YAML are relative to game root
- Check file extensions match
- Ensure assets exist at specified paths

### Dialog Issues
- Validate dialog YAML structure
- Check node IDs are unique
- Ensure start_node exists

## Example Migration

See `crystal_mystery` directory for a complete example of a migrated game. The original `main_old.cr.backup` shows the before state, while `main.cr` shows the simplified after state.

## Need Help?

If you encounter issues during migration:
1. Check the example game structure
2. Validate YAML files against schemas in docs
3. Review Lua API documentation
4. Ask in community Discord

The effort to migrate is worth it - your game will be much easier to maintain and extend!