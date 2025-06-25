# Changelog

All notable changes to the Point & Click Engine will be documented in this file.

## [Unreleased]

### Added
- Comprehensive test suite with 700+ specs covering all major components
- New modular architecture with dedicated managers:
  - `SceneManager` for scene loading, transitions, and caching
  - `ResourceManager` for asset loading with hot-reload support
  - `InputManager` for priority-based input handling
  - `RenderManager` for layer-based rendering
- Dependency injection system for better testability
- `Result<T, E>` monad for comprehensive error handling
- Performance monitoring system with detailed metrics
- Movement controller for smooth character movement
- Vector math utilities using Raylib's optimized functions
- Configurable game constants module
- Scene-level default transition durations
- Support for "default" keyword in transition commands
- Visual transition effects now properly render with shaders
- Comprehensive pathfinding improvements with diagonal movement and corner-cutting prevention
- FloatingText and FloatingTextManager for character dialogue
- Enhanced walkable area system with polygon regions and scale zones
- Test suite safety script (`run_specs_safely.sh`) for running large test suites

### Changed
- Refactored core engine to use manager pattern instead of monolithic design
- Simplified dependency injection from complex Box-based type erasure to type-safe approach
- Improved error handling throughout the codebase
- Updated all specs to match new architecture
- Better separation of concerns with interface-based design
- Improved verb detection logic for hotspots

### Fixed
- Segmentation fault issues in dependency injection system
- Memory corruption when using Box pointers for type erasure
- Dialog positioning in reference resolution (1024x768)
- Verb detection for various hotspot types
- Scene validation error handling
- Various spec failures related to UI components
- Transition shaders not loading properly
- Transition visual effects not rendering
- Pathfinding issues including path simplification bugs and missing diagonal corner checks
- Crystal spec contain matcher compatibility
- Malloc double-free error in test suite by improving resource cleanup in finalizers
- Resource manager safety issues preventing double-free errors
- Audio system finalizer error handling
- DialogManager handling of uninitialized Engine.instance

### Removed
- Complex dependency container implementation
- Obsolete test files and temporary debugging scripts
- Backup files and old disabled specs
- Duplicate executable files

## [0.1.0] - Previous Release

### Initial Features
- Scene management with YAML configuration
- Character pathfinding and movement
- Inventory system
- Dialog system with branching conversations
- Save/load functionality
- Lua scripting support
- Debug visualization tools
- Camera scrolling for large scenes
- Verb-based interaction system