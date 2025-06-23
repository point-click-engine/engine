# Engine Architecture

## Overview

The Point & Click Engine follows a modular architecture with clear separation of concerns. The design emphasizes testability, maintainability, and extensibility through interface-based programming and dependency injection.

## Core Principles

### SOLID Design
- **Single Responsibility**: Each manager handles one specific aspect of the engine
- **Open/Closed**: Extensible through interfaces without modifying core code
- **Liskov Substitution**: All implementations properly fulfill their interface contracts
- **Interface Segregation**: Small, focused interfaces for specific functionality
- **Dependency Inversion**: High-level modules depend on abstractions, not concretions

### Design Patterns
- **Manager Pattern**: Dedicated managers for each subsystem
- **Dependency Injection**: Interface-based dependencies resolved at runtime
- **Result Monad**: Error handling without exceptions
- **Observer Pattern**: Event system for decoupled communication
- **Strategy Pattern**: Pluggable implementations for rendering, input, etc.

## Core Components

### Engine (`Core::Engine`)
The main coordinator that manages the game loop and ties all systems together.

**Responsibilities:**
- Window initialization and main game loop
- System coordination and lifecycle management
- Scene transitions and state management
- Save/load orchestration

**Key Methods:**
- `init()` - Initialize all engine systems
- `run()` - Start the main game loop
- `add_scene(scene)` - Register a new scene
- `change_scene(name)` - Transition to a different scene

### SceneManager
Handles all scene-related operations including loading, transitions, and caching.

**Features:**
- Scene validation and integrity checking
- Smooth transitions with callbacks
- Scene preloading and caching
- Memory management for unused scenes

**Key Methods:**
- `add_scene(scene)` - Add a scene to the manager
- `change_scene(name)` - Switch to a different scene
- `preload_scene(name)` - Load scene into cache
- `remove_scene(name)` - Unload and remove a scene

### ResourceManager
Manages all game assets with automatic loading, caching, and cleanup.

**Features:**
- Automatic asset loading on demand
- Memory limit enforcement
- Hot-reload support for development
- Reference counting for cleanup

**Key Methods:**
- `load_texture(path)` - Load or retrieve cached texture
- `load_sound(path)` - Load or retrieve cached sound
- `preload_assets(paths)` - Batch preload assets
- `enable_hot_reload()` - Enable file watching

### InputManager
Coordinates all input handling with a priority-based system.

**Features:**
- Priority-based input handlers
- Input consumption tracking
- Named handler registration
- Event filtering and routing

**Key Methods:**
- `register_handler(name, priority)` - Register input handler
- `consume_input(type, handler)` - Mark input as consumed
- `is_consumed(type)` - Check if input was handled
- `process_input(dt)` - Process input for frame

### RenderManager
Manages the rendering pipeline with layer-based drawing.

**Features:**
- Z-ordered rendering layers
- Performance metrics tracking
- Layer visibility control
- Render state management

**Key Methods:**
- `add_layer(name, z_order)` - Create rendering layer
- `render(scene, dialogs, ...)` - Render frame
- `get_render_stats()` - Get performance metrics
- `set_layer_visible(name, visible)` - Toggle layer

## Dependency Injection

The engine uses a simplified dependency injection container that avoids type erasure issues:

```crystal
container = SimpleDependencyContainer.new
container.register_resource_loader(ResourceManager.new)
container.register_scene_manager(SceneManager.new)
```

This approach provides:
- Type safety at compile time
- No runtime casting errors
- Clear registration API
- Fast resolution

## Error Handling

The engine uses a `Result<T, E>` type for error handling:

```crystal
def load_scene(name : String) : Result(Scene, SceneError)
  # Returns either Success(scene) or Failure(error)
end
```

Benefits:
- No exceptions in normal flow
- Explicit error handling
- Composable error chains
- Type-safe error propagation

## Event System

Components communicate through a decoupled event system:

```crystal
event_system.emit("scene_changed", {scene: "hallway"})
event_system.on("scene_changed") do |data|
  # Handle scene change
end
```

## Performance Monitoring

Built-in performance tracking for optimization:

```crystal
monitor = PerformanceMonitor.new
monitor.start_frame
# ... frame logic ...
monitor.end_frame
stats = monitor.get_stats(60) # Last 60 frames
```

Tracks:
- Frame times and FPS
- Memory usage
- Draw calls
- Asset loading times

## Testing Architecture

The modular design enables comprehensive testing:
- Unit tests for individual components
- Integration tests for system interactions
- Mock implementations of interfaces
- No dependency on graphics for most tests

## File Organization

```
src/
├── core/
│   ├── engine.cr          # Main engine
│   ├── scene_manager.cr   # Scene management
│   ├── resource_manager.cr # Resource handling
│   ├── input_manager.cr   # Input processing
│   └── render_manager.cr  # Rendering pipeline
├── graphics/              # Graphics subsystems
├── ui/                    # User interface
├── characters/            # Character system
├── scenes/                # Scene components
└── utils/                 # Utilities

spec/
├── core/                  # Core component specs
├── graphics/              # Graphics specs
├── ui/                    # UI specs
└── integration/           # Integration tests
```

## Future Considerations

The architecture is designed to support:
- Plugin systems through interface extensions
- Multiple rendering backends
- Network multiplayer
- Modding support
- Visual scripting integration