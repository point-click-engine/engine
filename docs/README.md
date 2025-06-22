# Point & Click Engine Documentation

Welcome to the Point & Click Engine documentation! This engine uses a modern, data-driven approach where games are defined through YAML configuration files and Lua scripts.

## Documentation Index

### Getting Started
- **[Quick Reference](QUICK_REFERENCE.md)** - Quick lookup for common tasks
- **[Migration Guide](MIGRATION_TO_YAML.md)** - Migrate from code-based to YAML-based games

### Core Documentation
- **[Game Format Specification](GAME_FORMAT_SPECIFICATION.md)** - Complete reference for all file formats
  - Directory structure
  - YAML file formats (scenes, dialogs, quests, items)
  - Lua scripting API
  - Asset requirements
  
- **[Game Format Schema](GAME_FORMAT_SCHEMA.md)** - JSON schemas and validation
  - JSON Schema definitions
  - TypeScript type definitions
  - Validation rules
  - Editor implementation notes

### Development
- **[Editor Implementation Guide](EDITOR_IMPLEMENTATION_GUIDE.md)** - Building a visual game editor
  - Technology stack recommendations
  - Component implementations
  - UI/UX guidelines
  - Testing strategies

### Historical
- **[Refactoring Guide](REFACTORING_GUIDE.md)** - How the YAML system was implemented
- **[Refactoring Summary](REFACTORING_SUMMARY.md)** - Summary of improvements

## Key Concepts

### Data-Driven Design
The engine uses YAML files for all game configuration:
- **game_config.yaml** - Main game settings
- **scenes/*.yaml** - Scene definitions
- **dialogs/*.yaml** - Conversation trees  
- **quests/*.yaml** - Quest definitions
- **items/*.yaml** - Inventory items

### Scripting
Game logic is written in Lua with a rich API:
- Scene management
- Character control
- Dialog system
- Inventory management
- Audio control
- Visual effects

### Minimal Code
A complete game requires only ~45 lines of Crystal code:
```crystal
require "point_click_engine"

config = PointClickEngine::Core::GameConfig.from_file("game_config.yaml")
engine = config.create_engine
engine.show_main_menu
engine.run
```

## Example Game

See the `crystal_mystery` directory for a complete example game that demonstrates all engine features.

## Creating Your Game

1. Start with `templates/game_config_template.yaml`
2. Create your scenes in YAML
3. Write game logic in Lua
4. Add your assets
5. Build and run!

## Advanced Topics

### Archive Documentation
The `archive/` directory contains historical documentation from the engine's development. These files may be outdated but can provide context on design decisions and evolution.

## Contributing

When adding new features:
1. Update the Game Format Specification
2. Add JSON schemas if needed
3. Update the Quick Reference
4. Add examples to crystal_mystery

## Support

For questions and support:
- Review the example game
- Check the Quick Reference
- Read the full specifications
- Join our community Discord

---

**Remember**: With the Point & Click Engine, you define your game's content in YAML and Lua - the engine handles all the complex implementation details!