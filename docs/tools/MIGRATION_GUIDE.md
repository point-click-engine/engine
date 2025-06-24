# Migration Guide

This guide helps you migrate from older versions of the Point & Click Engine to the latest modular architecture.

## Overview

The Point & Click Engine has been refactored to use a modular architecture while maintaining 100% backward compatibility. This means:

- ✅ All existing code continues to work without changes
- ✅ You can migrate gradually at your own pace
- ✅ New features are available in both old and new APIs

## What's Changed

### Project Structure

The engine is now organized into logical modules:

**Old Structure:**
```
src/
└── point_click_engine.cr  # Everything in one file
```

**New Structure:**
```
src/
├── point_click_engine.cr  # Main entry point
├── core/                   # Core functionality
├── graphics/               # Rendering systems
├── characters/             # Character management
├── scenes/                 # Scene system
├── inventory/              # Inventory system
├── ui/                     # User interface
├── audio/                  # Sound management
├── navigation/             # Pathfinding
├── cutscenes/             # Cutscene system
├── localization/          # Multi-language support
├── scripting/             # Lua integration
└── assets/                # Asset management
```

### Namespacing

All classes are now properly namespaced:

| Old Class | New Namespace |
|-----------|---------------|
| `Game` | `Core::Engine` |
| `GameObject` | `Core::GameObject` |
| `Character` | `Characters::Character` |
| `Player` | `Characters::Player` |
| `NPC` | `Characters::NPC` |
| `Scene` | `Scenes::Scene` |
| `Hotspot` | `Scenes::Hotspot` |
| `Dialog` | `UI::Dialog` |
| `InventoryItem` | `Inventory::InventoryItem` |
| `InventoryUI` | `Inventory::InventorySystem` |
| `AnimatedSprite` | `Graphics::AnimatedSprite` |
| `ParticleSystem` | `Graphics::ParticleSystem` |

## Migration Strategies

### Option 1: No Migration (Recommended for existing projects)

Your existing code will continue to work exactly as before:

```crystal
# This still works!
game = PointClickEngine::Game.new(800, 600, "My Game")
scene = PointClickEngine::Scene.new("main")
player = PointClickEngine::Player.new("Hero", position, size)
```

### Option 2: Gradual Migration

Update your code file by file as you work on different features:

```crystal
# Old way (still works)
game = PointClickEngine::Game.new(800, 600, "My Game")

# New way
game = PointClickEngine::Core::Engine.new(800, 600, "My Game")
```

### Option 3: Full Migration

Update all references to use the new namespaced modules:

```crystal
# Before
require "point_click_engine"

class MyGame
  def initialize
    @game = PointClickEngine::Game.new(800, 600, "Adventure")
    @player = PointClickEngine::Player.new("Hero", vec2(100, 100), vec2(32, 48))
    @scene = PointClickEngine::Scene.new("main")
  end
end

# After
require "point_click_engine"

class MyGame
  def initialize
    @game = PointClickEngine::Core::Engine.new(800, 600, "Adventure")
    @player = PointClickEngine::Characters::Player.new("Hero", vec2(100, 100), vec2(32, 48))
    @scene = PointClickEngine::Scenes::Scene.new("main")
  end
end
```

## New Features Available

The following new features are available in both old and new APIs:

### Dialog Trees
```crystal
# Works with both APIs
tree = PointClickEngine::DialogTree.new("conversation")
# or
tree = PointClickEngine::Characters::Dialogue::DialogTree.new("conversation")
```

### Pathfinding
```crystal
# Works with both APIs
nav_grid = PointClickEngine::NavigationGrid.new(25, 19, 32)
pathfinder = PointClickEngine::Pathfinding.new(nav_grid)
```

### Cutscenes
```crystal
# Works with both APIs
cutscene = PointClickEngine::Cutscene.new("intro")
cutscene.fade_in(1.0)
cutscene.move_character(hero, target_pos)
```

### Save System
```crystal
# Works with both APIs
PointClickEngine::SaveSystem.save_game(game, "slot1")
PointClickEngine::SaveSystem.load_game(game, "slot1")
```

### Localization
```crystal
# Works with both APIs
i18n = PointClickEngine::LocalizationManager.instance
i18n.load_from_file("translations.yml")
```

## Benefits of Migrating

While not required, migrating to the new module structure provides:

1. **Better Code Organization**: Clearer separation of concerns
2. **Improved Intellisense**: Better IDE support with namespaced modules
3. **Easier Testing**: Test individual modules in isolation
4. **Future Features**: New features will be designed with the modular structure in mind

## Common Migration Tasks

### Updating Requires

If you're using specific parts of the engine:

```crystal
# Old way - loads everything
require "point_click_engine"

# New way - load only what you need
require "point_click_engine/core"
require "point_click_engine/scenes"
require "point_click_engine/characters"
```

### Updating Specs

Update your test files to use the new namespaces:

```crystal
# Old spec
describe PointClickEngine::Character do
  it "moves to position" do
    character = PointClickEngine::Character.new("Test", pos, size)
    # ...
  end
end

# New spec
describe PointClickEngine::Characters::Character do
  it "moves to position" do
    character = PointClickEngine::Characters::Character.new("Test", pos, size)
    # ...
  end
end
```

### Updating Type Annotations

If you use explicit type annotations:

```crystal
# Old
@player : PointClickEngine::Player

# New
@player : PointClickEngine::Characters::Player
```

## Troubleshooting

### "undefined constant" Errors

If you get undefined constant errors after updating:

1. Make sure you're requiring the main file: `require "point_click_engine"`
2. Check that you're using the correct namespace
3. Verify the alias still exists in `point_click_engine.cr`

### Performance Concerns

The modular structure has **zero runtime overhead**. All modules are compiled into the same efficient code.

### Missing Features

All features from the original engine are preserved. If something appears missing:

1. Check the [features documentation](../features/) directory
2. Verify you're requiring the correct module
3. Check the alias definitions in the main file

## Getting Help

- Check the [crystal_mystery](../../crystal_mystery/) directory for a complete example game
- Read the [documentation](../) for detailed guides
- Open an [issue](https://github.com/point-click-engine/engine/issues) if you encounter problems

## Summary

- **No immediate action required** - your code continues to work
- **Migrate at your own pace** - update code as you work on it
- **New features available** - use them with old or new API
- **Better organization** - benefit from clearer code structure when ready

The Point & Click Engine remains committed to stability and backward compatibility while providing a cleaner, more maintainable architecture for the future.