# Point & Click Engine

[![Crystal](https://img.shields.io/badge/crystal-%23000000.svg?style=for-the-badge&logo=crystal&logoColor=white)](https://crystal-lang.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A Crystal game engine for creating pixel art point-and-click adventure games, powered by [raylib-cr](https://github.com/sol-vin/raylib-cr).

## 🎮 Features

### Core Features
- **Scene Management**: Easy creation and transition between game scenes
- **Interactive Hotspots**: Define clickable areas with custom actions
- **Inventory System**: Advanced item management with combinations
- **Dialog System**: Branching dialog trees with conditions
- **Sprite Animation**: Frame-based animations for characters and objects
- **Particle Effects**: Dynamic particle system for visual effects
- **Scene Editor**: Visual editor for creating and editing scenes
- **YAML Import/Export**: Save and load scenes in YAML format
- **Debug Mode**: Visualize hotspots and debug information

### Advanced Features
- **Pathfinding**: A* navigation system with grid-based navigation mesh
- **Shader System**: Support for custom visual effects with GLSL shaders
- **Cutscene System**: Scripted sequences with character movements and dialogs
- **Localization**: Multi-language support with YAML-based translations
- **Save/Load System**: Complete game state persistence
- **Audio Manager**: Sound effects and music with volume control
- **Character AI**: Multiple behavior types (Patrol, Follow, RandomWalk)
- **Asset Management**: Centralized asset loading with archive support
- **Display Scaling**: Adaptive resolution for multiple screen sizes

## 📦 Installation

1. Add the dependency to your `shard.yml`:

```yaml
dependencies:
  point_click_engine:
    github: point-click-engine/engine
  raylib-cr:
    github: sol-vin/raylib-cr
```

2. Run `shards install`

## 🚀 Quick Start

```crystal
require "point_click_engine"

# Create a new game
game = PointClickEngine::Game.new(800, 600, "My Adventure Game")

# Create a scene
main_scene = PointClickEngine::Scene.new("main_room")
main_scene.load_background("assets/room.png")

# Add an interactive hotspot
door = PointClickEngine::Hotspot.new(
  "door",
  RL::Vector2.new(x: 300, y: 200),
  RL::Vector2.new(x: 100, y: 150)
)
door.on_click = ->{ game.change_scene("hallway") }
main_scene.add_hotspot(door)

# Add the scene to the game
game.add_scene(main_scene)
game.change_scene("main_room")

# Run the game!
game.run
```

## 🎯 Core Concepts

### GameObject
Base class for all game objects with position, size, and update/draw methods.

### Scene
Represents a game location with background, hotspots, and objects.

```crystal
scene = PointClickEngine::Scene.new("kitchen")
scene.load_background("assets/kitchen.png", scale: 2.0)
scene.on_enter = ->{ puts "Entered kitchen" }
```

### Hotspot
Interactive areas that respond to mouse clicks.

```crystal
hotspot = PointClickEngine::Hotspot.new(
  "cabinet",
  RL::Vector2.new(x: 100, y: 100),
  RL::Vector2.new(x: 50, y: 80)
)
hotspot.cursor_type = PointClickEngine::Hotspot::CursorType::Look
hotspot.on_click = ->{ show_cabinet_contents }
```

### Inventory
Manage game items with visual representation.

```crystal
key = PointClickEngine::InventoryItem.new("key", "A rusty old key")
key.load_icon("assets/key.png")
game.inventory.add_item(key)
```

### Dialog Trees
Create branching conversations with conditions and choices.

```crystal
# Create a dialog tree
tree = PointClickEngine::DialogTree.new("wizard_conversation")

# Create dialog nodes
greeting = PointClickEngine::DialogNode.new("greeting", "Hello, adventurer!")
greeting.character_name = "Wizard"

# Add conditional choices
choice = PointClickEngine::DialogChoice.new("Tell me about magic", "magic_info")
choice.conditions = ["player_level >= 5"]  # Only shown if condition is met
choice.once_only = true  # Choice disappears after selection
greeting.add_choice(choice)

tree.add_node(greeting)
tree.start_conversation("greeting")
```

### Animated Sprites
Create animated characters and objects.

```crystal
sprite = PointClickEngine::AnimatedSprite.new(
  RL::Vector2.new(x: 200, y: 300),
  frame_width: 32,
  frame_height: 48,
  frame_count: 8
)
sprite.load_texture("assets/character.png")
sprite.frame_speed = 0.1
sprite.play
```

### Pathfinding
Enable character navigation with A* pathfinding.

```crystal
# Create navigation grid
nav_grid = PointClickEngine::Navigation::NavigationGrid.new(
  width: 25,  # Grid cells
  height: 19,
  cell_size: 32  # Pixels per cell
)

# Mark obstacles
nav_grid.set_walkable(10, 10, false)  # Wall at grid position 10,10

# Find path
pathfinder = PointClickEngine::Navigation::Pathfinding.new(nav_grid)
path = pathfinder.find_path(
  RL::Vector2.new(x: 100, y: 100),  # Start position
  RL::Vector2.new(x: 400, y: 300)   # End position
)

# Character automatically follows path
character.follow_path(path)
```

### Cutscenes
Create scripted sequences for storytelling.

```crystal
cutscene = PointClickEngine::Cutscenes::Cutscene.new("intro")

# Chain actions together
cutscene.fade_in(1.0)
cutscene.move_character(hero, RL::Vector2.new(x: 300, y: 200))
cutscene.dialog(hero, "Where am I?", 3.0)
cutscene.wait(1.0)
cutscene.dialog(wizard, "Welcome to the Crystal Kingdom!")
cutscene.fade_out(1.0)
cutscene.change_scene("throne_room")

# Play cutscene
game.cutscene_manager.play(cutscene)
```

### Localization
Support multiple languages easily.

```crystal
# Load translations
localization = PointClickEngine::Localization::LocalizationManager.instance
localization.load_from_file("locales/translations.yml")
localization.set_locale(PointClickEngine::Localization::Locale::Fr_FR)

# Use translations
dialog.text = localization.get("dialog.greeting")  # "Bonjour!"
item.name = localization.get("items.key")  # "Clé"

# Pluralization support
text = localization.get("items.count", {"count" => item_count})
```

### Shaders
Add visual effects with GLSL shaders.

```crystal
shader_system = PointClickEngine::Graphics::Shaders::ShaderSystem.new

# Load shader
shader_system.load_shader(:grayscale, "shaders/grayscale.frag")

# Apply to scene
shader_system.set_active(:grayscale)
shader_system.begin_mode
scene.draw
shader_system.end_mode

# Set shader parameters
shader_system.set_value(:water, "time", Time.local.to_unix_f)
```

## 🛠️ Scene Editor

The engine includes a comprehensive visual scene editor for creating game scenes.

### Building and Running

```bash
# Using the build script
./editor.sh

# Or manually
crystal build src/scene_editor.cr -o bin/scene_editor -Deditor --release
```

### Features
- **Multiple Editor Modes**: Scene, Character, Hotspot, Dialog, Assets
- **Visual Scene Editing**: Drag & drop interface for placing objects
- **Tool Palette**: Select, Move, Place, Delete, Paint, and Zoom tools
- **Property Panel**: Edit object properties in real-time
- **Grid System**: Snap objects to grid for precise placement
- **Multi-Selection**: Select multiple objects with Ctrl+Click or rectangle selection
- **Keyboard Shortcuts**: Productivity shortcuts for common operations
- **YAML Import/Export**: Save and load scenes in YAML format
- **Project Management**: Create and manage complete game projects

### Controls

#### Camera Controls
- **Middle Mouse**: Pan the camera
- **Mouse Wheel**: Zoom in/out
- **W/A/S/D**: Pan with keyboard

#### Tools
- **S**: Select tool - Click to select, drag for rectangle selection
- **M**: Move tool - Drag selected objects
- **P**: Place tool - Click to place new hotspots
- **D**: Delete tool - Click to delete objects
- **B**: Paint tool (coming soon)
- **Z**: Zoom tool (coming soon)

#### Keyboard Shortcuts
- **Ctrl+S**: Save project
- **Ctrl+Z**: Undo
- **Ctrl+Y**: Redo
- **Delete**: Delete selected objects
- **G**: Toggle grid
- **X**: Toggle snap to grid
- **F1**: Toggle debug mode

#### Selection
- **Click**: Select single object
- **Ctrl+Click**: Add/remove from selection
- **Drag**: Rectangle selection
- **Ctrl+A**: Select all (coming soon)

## 📁 Project Structure

### Engine Structure
```
point_click_engine/
├── src/
│   ├── point_click_engine.cr     # Main entry point
│   ├── core/                      # Core engine functionality
│   │   ├── engine.cr             # Main game loop
│   │   ├── game_object.cr        # Base game object
│   │   └── save_system.cr        # Save/load functionality
│   ├── graphics/                  # Rendering and visuals
│   │   ├── animated_sprite.cr    # Sprite animations
│   │   ├── particles.cr          # Particle effects
│   │   ├── display_manager.cr    # Resolution scaling
│   │   └── shaders/              # Shader system
│   ├── characters/                # Character management
│   │   ├── character.cr          # Base character class
│   │   ├── player.cr             # Player character
│   │   ├── npc.cr                # Non-player characters
│   │   ├── ai/                   # AI behaviors
│   │   └── dialogue/             # Dialog system
│   ├── scenes/                    # Scene management
│   │   ├── scene.cr              # Scene class
│   │   └── hotspot.cr            # Interactive areas
│   ├── inventory/                 # Inventory system
│   ├── ui/                        # User interface
│   ├── audio/                     # Sound management
│   ├── navigation/                # Pathfinding
│   ├── cutscenes/                 # Cutscene system
│   ├── localization/              # Multi-language support
│   ├── scripting/                 # Lua scripting
│   ├── assets/                    # Asset management
│   └── editor/                    # Scene editor
└── example/                       # Example games

### Game Project Structure
```
my_game/
├── src/
│   ├── my_game.cr
│   └── scenes/
│       ├── main_room.cr
│       └── hallway.cr
├── assets/
│   ├── backgrounds/
│   ├── sprites/
│   ├── sounds/
│   ├── music/
│   └── ui/
├── scenes/                        # YAML scene files
│   ├── main_room.yml
│   └── hallway.yml
├── locales/                       # Translation files
│   ├── en-us.yml
│   └── fr-fr.yml
├── shaders/                       # Custom shaders
│   └── effects.frag
└── shard.yml
```

## 🎨 Asset Guidelines

### Backgrounds
- Recommended format: PNG
- Use pixel art for best results
- Consider scene scale factor for retro look

### Sprites
- Use sprite sheets for animations
- Transparent backgrounds (PNG)
- Consistent frame sizes

### UI Elements
- Inventory icons: 64x64 pixels recommended
- Cursor: 32x32 pixels or smaller

## 🔧 Advanced Features

### Custom Game Objects

```crystal
class NPC < PointClickEngine::GameObject
  property name : String
  property dialogue : String

  def initialize(position, size, @name : String, @dialogue : String)
    super(position, size)
  end

  def update(dt : Float32)
    # Update NPC logic
  end

  def draw
    # Draw NPC sprite
  end
end
```

### Scene Transitions

```crystal
door.on_click = ->{
  # Fade out effect
  game.change_scene("next_room")
}
```

### Item Combinations

```crystal
# Set up item combinations
rope.combinable_with = ["Hook"]
rope.combine_actions = {"Hook" => "create_grappling_hook"}

# Handle combination
inventory.on_items_combined = ->(item1, item2, action) {
  if action == "create_grappling_hook"
    inventory.remove_item(item1)
    inventory.remove_item(item2)
    inventory.add_item(grappling_hook)
  end
}
```

### Save/Load System

```crystal
# Save game state
PointClickEngine::SaveSystem.save_game(game, "slot1")

# Load game state
PointClickEngine::SaveSystem.load_game(game, "slot1")

# Quick save/load
game.on_key_pressed = ->(key) {
  case key
  when .f5 then PointClickEngine::SaveSystem.save_game(game, "quicksave")
  when .f9 then PointClickEngine::SaveSystem.load_game(game, "quicksave")
  end
}
```

### Asset Archives

```crystal
# Load assets from archives
asset_manager = PointClickEngine::AssetManager.new
asset_manager.mount_archive("game_assets.zip")

# Assets are automatically loaded from archives
texture = asset_manager.load_texture("sprites/hero.png")
sound = asset_manager.load_sound("effects/footstep.wav")
```

### Scripting with Lua

```crystal
# Initialize script engine
script_engine = PointClickEngine::ScriptEngine.new

# Register game objects
script_engine.register_game(game)
script_engine.register_scene(scene)

# Load and run scripts
script_engine.load_script("scripts/game_logic.lua")
script_engine.call_function("on_scene_enter")

# Handle events from Lua
hotspot.on_click = ->{ script_engine.call_function("on_door_click") }
```

## 🐛 Debug Mode

Press **F1** during gameplay to toggle debug mode:
- Visualize hotspot boundaries
- Display FPS
- Show mouse coordinates

## 📝 Examples

The engine includes several example games demonstrating different features:

- **example.cr** - Basic point & click game with scenes and inventory
- **enhanced_example.cr** - Advanced features like dialog trees and animations
- **pathfinding_example.cr** - Character navigation with A* pathfinding
- **shader_example.cr** - Visual effects using GLSL shaders
- **scripting_example.cr** - Lua scripting integration
- **archive_example.cr** - Loading assets from archives
- **modular_example.cr** - Using the modular architecture

Run examples:
```bash
cd example
crystal run enhanced_example.cr
```

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [raylib-cr](https://github.com/sol-vin/raylib-cr) for Crystal bindings to Raylib
- [Raylib](https://www.raylib.com/) for the awesome game development library
- The Crystal community for their support

## 💬 Support

- [Issues](https://github.com/point-click-engine/engine/issues)
- [Discussions](https://github.com/point-click-engine/engine/discussions)
- [Discord](https://discord.gg/crystal-lang)

---

Made with ❤️ using Crystal and Raylib
