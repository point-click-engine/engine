# Point & Click Engine

A modern, data-driven adventure game engine written in Crystal, designed for creating point-and-click adventure games with minimal code.

## Features

- **YAML-Based Configuration** - Define your entire game through configuration files
- **Visual Scene System** - Hotspots, walkable areas, character scaling
- **Camera Scrolling** - Support for scenes larger than the viewport with smooth scrolling
- **Scene Transitions** - 25+ cheesy transition effects with configurable durations
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
default_transition_duration: 2.0  # Default transition time for this scene

hotspots:
  - name: door
    x: 400
    y: 300
    width: 100
    height: 200
    description: "A wooden door"
    actions:
      open: "transition:hallway:swirl::100,200"  # Uses scene's default duration
      use: "transition:hallway:fade:1.5"         # Override with specific duration
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
./run.sh build main.cr
./run.sh main.cr
```

Or for development:
```bash
./run.sh spec              # Run tests
./run.sh crystal_mystery/main.cr  # Run example game
```

That's it! You have a working adventure game.

## Documentation

### 📚 User Guide
- **[Getting Started](docs/user-guide/GETTING_STARTED.md)** - Installation and first game tutorial
- **[Quick Reference](docs/user-guide/QUICK_REFERENCE.md)** - Quick lookup for common tasks
- **[Game Formats Overview](docs/user-guide/GAME_FORMAT_SPECIFICATION.md)** - Introduction to YAML formats
  - **[YAML Formats](docs/user-guide/YAML_FORMATS.md)** - Complete YAML specification
  - **[Lua Scripting](docs/user-guide/LUA_SCRIPTING.md)** - Full Lua API reference
  - **[Asset Guide](docs/user-guide/ASSET_GUIDE.md)** - Asset requirements and guidelines

### 🔧 Developer Guide
- **[Architecture](docs/developer-guide/ARCHITECTURE.md)** - Technical architecture and design
- **[Testing Guide](docs/developer-guide/TESTING_GUIDE.md)** - Testing strategies and implementation
- **[Validation System](docs/developer-guide/VALIDATION_SYSTEM.md)** - Error handling and validation
- **[Debugging Guide](docs/developer-guide/DEBUGGING_GUIDE.md)** - Debugging techniques

### ✨ Features
- **[Dialog System](docs/features/dialog_system.md)** - Dialog trees and conversations
- **[Dialog Input](docs/features/dialog_input_handling.md)** - Input handling during dialogs
- **[Feature Specs](docs/features/specs/)** - Detailed feature specifications

### 🛠️ Tools & Editor
- **[Editor Development](docs/tools/EDITOR_DEVELOPMENT.md)** - Building a visual editor
- **[Migration Guide](docs/tools/MIGRATION_GUIDE.md)** - Migrating existing games

## Project Structure

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

## Examples

See the `crystal_mystery` directory for a complete example game demonstrating all engine features.

## Requirements

- Crystal 1.0+
- Raylib (automatically installed via shards)
- Lua 5.4 (for scripting)

## Installation

1. Install Crystal from https://crystal-lang.org
2. Clone this repository
3. Run `shards install`

### Audio Support Setup

The engine uses raylib-cr which includes audio support via miniaudiohelpers. If you encounter linking errors like:

```
ld: library 'miniaudiohelpers' not found
```

This means the library path isn't set correctly. There are several solutions:

#### Solution: Use the run.sh script

This project includes a `run.sh` script that handles all audio library setup automatically:

```bash
./run.sh main.cr                # Run your game
./run.sh spec                   # Run standard tests  
./run.sh build main.cr         # Build your game
./run.sh test-comprehensive    # Run comprehensive test suite
./run.sh test-stress          # Run stress tests only
./run.sh test-memory          # Run memory-focused tests
```

For other projects using this engine, copy the `run.sh` script to your project root.

**Note**: Always use `./run.sh` instead of calling `crystal` directly. This ensures proper audio library linking and compatibility.

## Building Games

### Development Build
```bash
./run.sh build main.cr
```

### Release Build
```bash
./run.sh build main.cr --release
```

### Platform-Specific Builds
The engine supports building for:
- Windows (64-bit)
- macOS (Universal Binary)
- Linux (64-bit)

## Contributing

Contributions are welcome! Please read our contributing guidelines and submit pull requests to our repository.

When adding new features:
1. Update the Game Format Specification
2. Add JSON schemas if needed
3. Update the Quick Reference
4. Add examples to crystal_mystery

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

- Documentation: See organized documentation above
- Example Game: See `crystal_mystery/` directory
- Issues: GitHub Issues
- Discord: [Join our community](#)

---

**Ready to create your adventure? Start with the templates and let your imagination run wild!**