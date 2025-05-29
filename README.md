# Point & Click Engine

[![Crystal](https://img.shields.io/badge/crystal-%23000000.svg?style=for-the-badge&logo=crystal&logoColor=white)](https://crystal-lang.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A Crystal game engine for creating pixel art point-and-click adventure games, powered by [raylib-cr](https://github.com/sol-vin/raylib-cr).

## 🎮 Features

- **Scene Management**: Easy creation and transition between game scenes
- **Interactive Hotspots**: Define clickable areas with custom actions
- **Inventory System**: Built-in inventory with item management
- **Dialog System**: Support for character dialogs with multiple choices
- **Sprite Animation**: Frame-based animations for characters and objects
- **Particle Effects**: Dynamic particle system for visual effects
- **Scene Editor**: Visual editor for creating and editing scenes
- **YAML Import/Export**: Save and load scenes in YAML format
- **Debug Mode**: Visualize hotspots and debug information

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

### Dialog
Display character dialogs with choices.

```crystal
dialog = PointClickEngine::Dialog.new(
  "Hello! How can I help you?",
  RL::Vector2.new(x: 100, y: 400),
  RL::Vector2.new(x: 600, y: 150)
)
dialog.character = "Shop Keeper"
dialog.add_choice("Buy items") { open_shop }
dialog.add_choice("Leave") { dialog.hide }
game.show_dialog(dialog)
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

## 🛠️ Scene Editor

The engine includes a visual scene editor for creating game scenes.

### Usage

```crystal
require "scene_editor"

editor = SceneEditor::Editor.new
editor.run
```

### Features
- Visual hotspot placement and editing
- Drag & drop with snap-to-grid
- Properties panel for hotspot configuration
- YAML import/export
- Export to Crystal code

### Controls
- **Left Click**: Select/create hotspots
- **Middle Mouse**: Pan camera
- **Mouse Wheel**: Zoom
- **G**: Toggle grid
- **S**: Toggle snap to grid
- **Delete**: Delete selected hotspot
- **Ctrl+D**: Duplicate hotspot
- **Ctrl+S**: Save scene
- **F1**: Toggle debug mode

## 📁 Project Structure

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
│   └── ui/
├── scenes/
│   ├── main_room.yml
│   └── hallway.yml
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
item1.combinable_with = ["item2"]
# Handle combination logic in game
```

## 🐛 Debug Mode

Press **F1** during gameplay to toggle debug mode:
- Visualize hotspot boundaries
- Display FPS
- Show mouse coordinates

## 📝 Examples

Check out the [examples](https://github.com/point-click-engine/examples) repository for complete game examples.

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
