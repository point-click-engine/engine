# Point & Click Engine - Game Format Specification Overview

This document provides an overview of the Point & Click Engine's data-driven game format. The engine uses YAML configuration files and Lua scripts to define entire adventure games without requiring engine modifications.

## Overview

The Point & Click Engine uses a data-driven approach where games are defined entirely through configuration files:

- **YAML files** define static data (scenes, dialogs, quests, items)
- **Lua scripts** handle dynamic game logic
- **Assets** (images, sounds) are referenced by the configuration files
- **Minimal Crystal code** is needed (just the entry point)

This separation allows:
- Non-programmers to create content
- Easy modding and customization
- Visual editors to modify games
- Hot-reloading during development

## Documentation Structure

The complete game format documentation is organized into focused guides:

### 📄 [YAML Formats](YAML_FORMATS.md)
Complete specification for all YAML configuration files:
- Game Configuration (`game_config.yaml`)
- Scene Definitions (`scenes/*.yaml`)
- Dialog Trees (`dialogs/*.yaml`)
- Quest System (`quests/*.yaml`)
- Item Definitions (`items/*.yaml`)
- Action Sequences (`sequences/*.yaml`)

### 📜 [Lua Scripting Guide](LUA_SCRIPTING.md)
Complete Lua scripting reference:
- Script structure and lifecycle
- Event handlers
- Full API reference
- Common patterns and examples

### 🎨 [Asset Guidelines](ASSET_GUIDE.md)
Requirements and best practices for game assets:
- Image formats and resolutions
- Audio specifications
- Font requirements
- Localization files

## Directory Structure

A typical Point & Click Engine game has this structure:

```
my_adventure_game/
├── game_config.yaml          # Main game configuration
├── main.cr                   # Entry point (minimal boilerplate)
├── scenes/                   # Scene definitions
│   ├── intro.yaml
│   ├── hallway.yaml
│   └── ...
├── scripts/                  # Lua scripts for game logic
│   ├── intro.lua
│   ├── puzzles.lua
│   └── ...
├── dialogs/                  # Dialog tree definitions
│   ├── npc_guard.yaml
│   ├── npc_merchant.yaml
│   └── ...
├── quests/                   # Quest definitions
│   ├── main_quest.yaml
│   ├── side_quests.yaml
│   └── ...
├── items/                    # Inventory item definitions
│   ├── key_items.yaml
│   ├── consumables.yaml
│   └── ...
├── sequences/               # Scripted action sequences
│   ├── intro_sequence.yaml
│   └── ...
├── assets/                  # Game assets
│   ├── sprites/            # Character sprites
│   ├── backgrounds/        # Scene backgrounds
│   ├── portraits/          # Character portraits
│   ├── items/             # Item icons
│   ├── audio/             # Sound effects and music
│   │   ├── music/
│   │   └── sounds/
│   └── fonts/             # Game fonts
└── locales/               # Localization files (optional)
    ├── en.yaml
    ├── es.yaml
    └── ...
```

## File Formats

The engine uses these file types:

| Extension | Purpose | Format |
|-----------|---------|---------|
| `.yaml` | Configuration files | YAML 1.2 |
| `.lua` | Game scripts | Lua 5.4 |
| `.png` | Images | PNG with transparency |
| `.jpg` | Backgrounds | JPEG (no transparency) |
| `.ogg` | Music | Ogg Vorbis |
| `.wav` | Sound effects | WAV (uncompressed) |
| `.ttf` | Fonts | TrueType fonts |

## Quick Example

Here's a minimal game structure:

```yaml
# game_config.yaml
game:
  title: "My Adventure"
  version: "1.0.0"
  
window:
  width: 1024
  height: 768
  
start_scene: "intro"
```

```yaml
# scenes/intro.yaml
name: intro
background_path: assets/backgrounds/intro.png

hotspots:
  - name: door
    x: 400
    y: 300
    width: 100
    height: 200
    description: "A wooden door"
```

```lua
-- scripts/intro.lua
function on_enter()
  show_message("Welcome!")
end
```

## Editor Implementation Notes

For developers creating visual editors for the Point & Click Engine:

### Core Requirements
1. **YAML Schema Validation** - Use the JSON schemas in `GAME_FORMAT_SCHEMA.md`
2. **Live Preview** - Hot-reload changes without restarting
3. **Asset Management** - Validate asset references and paths
4. **Script Integration** - Syntax highlighting and validation for Lua

### Recommended Features
1. **Visual Scene Editor**
   - Drag-and-drop hotspot placement
   - Walkable area polygon editing
   - Character position preview
   - Background layer management

2. **Dialog Tree Editor**
   - Visual node-based editing
   - Condition builder
   - Preview dialog flow
   - Character portrait assignment

3. **Quest Designer**
   - Visual quest chain editor
   - Objective dependency graphs
   - Reward configuration
   - Testing tools

4. **Asset Pipeline**
   - Automatic format conversion
   - Resolution optimization
   - Audio normalization
   - Batch processing

5. **Localization Tools**
   - String extraction from YAML/Lua
   - Translation management
   - Preview in different languages
   - Export/import for translators

### Integration Points
- File watching for hot-reload
- Lua syntax checking via `luacheck`
- YAML validation against schemas
- Asset validation and preview
- Game state inspection

## Best Practices

1. **Organization**
   - Keep related files together (scene + script)
   - Use consistent naming conventions
   - Document complex scripts

2. **Performance**
   - Optimize image sizes
   - Use appropriate audio formats
   - Limit scene complexity

3. **Maintainability**
   - Use descriptive names
   - Comment complex logic
   - Keep scripts focused

4. **Testing**
   - Test each scene independently
   - Verify all dialog paths
   - Check quest completion logic

## Next Steps

- Review the [YAML Formats](YAML_FORMATS.md) for detailed configuration syntax
- Learn the [Lua Scripting API](LUA_SCRIPTING.md) for game logic
- Check the [Asset Guidelines](ASSET_GUIDE.md) for content requirements
- See `crystal_mystery/` for a complete example game

---

Remember: The Point & Click Engine handles all the complex implementation - you just provide the content!
