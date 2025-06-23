# Point & Click Engine

A modern, data-driven adventure game engine written in Crystal, designed for creating point-and-click adventure games with minimal code.

## Features

- **YAML-Based Configuration** - Define your entire game through configuration files
- **Visual Scene System** - Hotspots, walkable areas, character scaling
- **Camera Scrolling** - Support for scenes larger than the viewport with smooth scrolling
- **Lua Scripting** - Powerful scripting for game logic
- **Dialog Trees** - Branching conversations with conditions
- **Quest System** - Complex multi-objective quests
- **Inventory Management** - Drag-and-drop inventory with item combinations
- **Save/Load System** - Automatic and manual save games
- **Audio System** - Music and sound effects with 3D positioning
- **Pathfinding** - A* pathfinding for character movement
- **Localization Ready** - Built-in support for multiple languages

## Quick Start

### 1. Create a Game Configuration

Create `game_config.yaml`:
```yaml
game:
  title: "My Adventure"
  version: "1.0.0"

window:
  width: 1024
  height: 768

player:
  name: "Hero"
  sprite_path: "assets/sprites/player.png"
  sprite:
    frame_width: 64
    frame_height: 64
    columns: 8
    rows: 4

features:
  - verbs        # Enable verb interface
  - floating_dialogs
  - portraits

assets:
  scenes: ["scenes/*.yaml"]
  quests: ["quests/*.yaml"]

start_scene: "intro"
```

### 2. Create Your Main File

Create `main.cr`:
```crystal
require "point_click_engine"

config = PointClickEngine::Core::GameConfig.from_file("game_config.yaml")
engine = config.create_engine
engine.show_main_menu
engine.run
```

### 3. Define a Scene

Create `scenes/intro.yaml`:
```yaml
name: intro
background_path: assets/backgrounds/intro.png
script_path: scripts/intro.lua

hotspots:
  - name: door
    type: exit
    x: 400
    y: 300
    width: 100
    height: 200
    target_scene: hallway
    description: "A wooden door"
```

### 4. Add Scene Logic

Create `scripts/intro.lua`:
```lua
function on_enter()
  show_message("Welcome to the adventure!")
end

hotspot.on_click("door", function()
  play_sound("door_open")
  change_scene("hallway")
end)
```

### 5. Build and Run

```bash
crystal build main.cr
./main
```

That's it! You have a working adventure game.

## Architecture

The engine uses a data-driven architecture where games are defined through YAML configuration files and Lua scripts:

```
game/
├── game_config.yaml     # Main configuration
├── main.cr             # Entry point (minimal)
├── scenes/             # Scene definitions (YAML)
├── scripts/            # Game logic (Lua)
├── dialogs/            # Dialog trees (YAML)
├── quests/             # Quest definitions (YAML)
├── items/              # Item definitions (YAML)
└── assets/             # Images, sounds, etc.
```

## Core Concepts

### Scenes
Scenes are game locations with backgrounds, interactive hotspots, and characters. They support:
- Rectangle and polygon hotspots
- Exit zones with transitions
- Walkable area definition
- Character walk-behind regions
- Dynamic scaling zones

### Scripting
Lua scripts handle all game logic with access to a rich API:
- Scene management
- Character control
- Dialog system
- Inventory management
- Quest tracking
- Audio control
- Visual effects

### Dialogs
Dialog trees support:
- Branching conversations
- Conditional choices
- Character portraits
- Effects and state changes
- Multiple dialog styles

### Quests
The quest system features:
- Multi-objective quests
- Prerequisites and dependencies
- Conditional rewards
- Journal entries
- Auto-start conditions

## Examples

See the `crystal_mystery` directory for a complete example game demonstrating all engine features.

## Templates

The `templates` directory contains:
- `game_config_template.yaml` - Starting point for new games
- `minimal_game.cr` - Minimal game setup

## Documentation

Comprehensive documentation is available in the `docs` directory:
- `GAME_FORMAT_SPECIFICATION.md` - Complete format reference
- `GAME_FORMAT_SCHEMA.md` - JSON schemas for validation
- `EDITOR_IMPLEMENTATION_GUIDE.md` - Building a visual editor

## Requirements

- Crystal 1.0+
- Raylib (automatically installed via shards)
- Lua 5.4 (for scripting)

## Installation

1. Install Crystal from https://crystal-lang.org
2. Clone this repository
3. Run `shards install`

## Creating Your Game

1. Copy the `templates/game_config_template.yaml`
2. Customize it for your game
3. Create your scenes, scripts, and assets
4. Use `templates/minimal_game.cr` as your entry point
5. Build and distribute!

## Building Games

### Development Build
```bash
crystal build main.cr
```

### Release Build
```bash
crystal build main.cr --release
```

### Platform-Specific Builds
The engine supports building for:
- Windows (64-bit)
- macOS (Universal Binary)
- Linux (64-bit)

## Contributing

Contributions are welcome! Please read our contributing guidelines and submit pull requests to our repository.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Built with [Crystal](https://crystal-lang.org/)
- Graphics powered by [Raylib](https://www.raylib.com/)
- Scripting via [Lua](https://www.lua.org/)

## Roadmap

- [ ] Visual editor application
- [ ] Steam integration
- [ ] Mobile platform support
- [ ] Multiplayer support
- [ ] 3D scene support
- [ ] VR mode

## Support

- Documentation: See `docs/` directory
- Issues: GitHub Issues
- Discord: [Join our community](#)

---

**Ready to create your adventure? Start with the templates and let your imagination run wild!**