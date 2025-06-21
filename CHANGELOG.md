# Changelog

All notable changes to the Point & Click Engine will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **Dialog Tree System**: Complex branching conversations with conditions and variables
- **A* Pathfinding**: Grid-based navigation with automatic obstacle avoidance
- **Cutscene System**: Scripted sequences with character movements and effects
- **Localization System**: Multi-language support with YAML-based translations
- **Save/Load System**: Complete game state persistence with multiple save slots
- **Audio Manager**: Centralized sound effect and music management
- **Shader System**: GLSL shader support for visual effects
- **Asset Manager**: Unified asset loading with archive support
- **Character AI**: Multiple behavior types (Patrol, Follow, RandomWalk, Idle)
- **Enhanced Scene Editor**: Multi-selection, advanced tools, and project management
- **Lua Scripting**: Integrate game logic with Lua scripts
- **Display Scaling**: Adaptive resolution for multiple screen sizes

### Changed
- **Modular Architecture**: Refactored codebase into logical modules while maintaining backward compatibility
- **Enhanced Inventory**: Added item combinations and usage on objects
- **Improved Character System**: Added sprite-based animations and state management
- **Better Editor**: Added tool palette, property panel, and keyboard shortcuts

### Fixed
- Audio system now gracefully handles missing audio libraries
- Improved memory management in particle system
- Better error handling in save/load system

## [0.2.0] - 2024-01-15

### Added
- Scene Editor with visual hotspot placement
- YAML import/export for scenes
- Particle effects system
- Debug mode visualization
- Inventory UI with drag & drop

### Changed
- Improved sprite animation performance
- Better mouse input handling
- Enhanced dialog system with choices

### Fixed
- Memory leaks in texture loading
- Scene transition bugs
- Dialog rendering issues

## [0.1.0] - 2023-12-01

### Added
- Initial release
- Basic scene management
- Interactive hotspots
- Simple inventory system
- Character movement
- Dialog bubbles
- Sprite animations

[Unreleased]: https://github.com/point-click-engine/engine/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/point-click-engine/engine/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/point-click-engine/engine/releases/tag/v0.1.0