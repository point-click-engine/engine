# Crystal Mystery Refactoring Guide

## Overview
This guide explains how to refactor the Crystal Mystery game to better utilize the Point & Click Engine's features.

## Current Issues with main.cr

1. **Hardcoded Scene Creation** - Scenes are created programmatically instead of using YAML files
2. **Inline Interaction Logic** - All interactions are hardcoded in Crystal instead of using Lua scripts
3. **Duplicated Engine Features** - The game reimplements features that already exist in the engine
4. **Poor Separation of Concerns** - Game logic is mixed with engine initialization

## Refactoring Strategy

### 1. Use YAML for Scene Definitions
Instead of creating scenes in code like this:
```crystal
scene_yaml = <<-YAML
name: library
background_path: assets/backgrounds/library.png
# ... lots of YAML
YAML

File.write("temp_library.yaml", scene_yaml)
scene = PointClickEngine::Scenes::SceneLoader.load_from_yaml("temp_library.yaml")
File.delete("temp_library.yaml")
```

Simply load existing YAML files:
```crystal
scene = PointClickEngine::Scenes::SceneLoader.load_from_yaml("crystal_mystery/scenes/library.yaml")
```

### 2. Move Interactions to Lua Scripts
Instead of hardcoding interactions:
```crystal
hotspot.on_click = -> do
  if @engine.inventory.selected_item.try(&.name) == "key"
    # Lots of game logic here
  end
end
```

Use Lua scripts that are already loaded with scenes:
```lua
function on_cabinet_click()
    if has_selected_item("key") then
        unlock_cabinet()
    else
        show_message("The cabinet is locked.")
    end
end
```

### 3. Leverage Engine Features

#### Dialog System
- Use dialog portraits: `dm.enable_portraits = true`
- Use dialog styles: Bubble, Rectangle, Thought, Shout
- Load dialog trees from YAML files

#### Quest System
- Use quest rewards
- Implement journal entries
- Use auto-start quests based on conditions

#### Scene Features
- Dynamic hotspots that change based on game state
- Walk-behind regions for depth
- Scale zones for character sizing
- Visibility conditions for hotspots

#### State Management
- Use timers: `game_state_manager.add_timer("timer_name", 5.0) { ... }`
- Use the day cycle system
- Leverage state change handlers for quest updates

### 4. File Organization

```
crystal_mystery/
├── main.cr              # Simplified main file
├── scenes/              # YAML scene definitions
│   ├── library.yaml
│   ├── laboratory.yaml
│   └── garden.yaml
├── scripts/             # Lua scripts for game logic
│   ├── library.lua
│   ├── laboratory.lua
│   └── garden.lua
├── dialogs/             # Dialog trees in YAML
│   ├── butler_dialog.yaml
│   └── scientist_dialog.yaml
├── items/               # Item definitions
│   └── items.yaml
├── quests/              # Quest definitions
│   └── main_quests.yaml
└── cutscenes/           # Cutscene definitions
    ├── intro_sequence.yaml
    └── ending_sequence.yaml
```

### 5. Benefits of Refactoring

1. **Easier Maintenance** - Logic is separated into appropriate files
2. **Hot Reloading** - Lua scripts can be reloaded without recompiling
3. **Better Performance** - Less code in the main game loop
4. **Cleaner Code** - Separation of concerns between engine and game
5. **Easier Modding** - Players can modify Lua scripts and YAML files

### 6. Migration Steps

1. **Create/Update YAML Files** - Ensure all scenes are defined in YAML
2. **Create Lua Scripts** - Move all interaction logic to Lua
3. **Simplify main.cr** - Remove hardcoded logic, just load assets
4. **Test Incrementally** - Test each scene after migration
5. **Add Engine Features** - Enhance with features like portraits, journals, etc.

### 7. Example: Refactored main.cr Structure

```crystal
class CrystalMysteryGame
  def initialize
    # Initialize engine and systems
    setup_engine
    
    # Load all assets from files
    load_scenes        # From YAML
    load_dialogs       # From YAML
    load_audio_assets  # Still in code, but could be YAML
    
    # Register Lua extensions
    register_lua_functions
    
    # Set up event handlers
    setup_event_handlers
    
    # Show main menu
    @engine.show_main_menu
  end
end
```

The refactored version is much cleaner and leverages the engine's full capabilities!