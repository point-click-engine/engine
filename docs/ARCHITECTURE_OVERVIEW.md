# Point & Click Engine Architecture Overview

## Table of Contents
1. [Introduction](#introduction)
2. [Architecture Philosophy](#architecture-philosophy)
3. [Core Architecture](#core-architecture)
4. [Module Overview](#module-overview)
5. [Component Relationships](#component-relationships)
6. [Data Flow](#data-flow)
7. [Design Patterns](#design-patterns)
8. [Best Practices](#best-practices)

## Introduction

The Point & Click Engine is a modern, component-based adventure game engine written in Crystal. It provides a complete framework for creating point-and-click adventure games with minimal code through its data-driven architecture.

## Architecture Philosophy

The engine follows these core architectural principles:

### 1. Component-Based Design
- Large systems are decomposed into focused, single-responsibility components
- Components are reusable and testable in isolation
- Coordinator classes orchestrate component interactions

### 2. Data-Driven Development
- Games are defined through YAML configuration files
- Minimal code required for game-specific logic
- Hot-reloading support for rapid development

### 3. SOLID Principles
- **S**ingle Responsibility: Each component has one clear purpose
- **O**pen/Closed: Extensible through interfaces, not modification
- **L**iskov Substitution: Components can be replaced with compatible implementations
- **I**nterface Segregation: Small, focused interfaces
- **D**ependency Inversion: Depend on abstractions, not concretions

### 4. Error Handling
- Result monad pattern (`Result<T, E>`) for explicit error handling
- No exceptions in normal control flow
- Comprehensive validation at load time

## Core Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                         Engine                              │
│  ┌─────────────────────────────────────────────────────┐  │
│  │                  System Manager                      │  │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐           │  │
│  │  │  Scene   │ │  Input   │ │  Render  │           │  │
│  │  │ Manager  │ │ Manager  │ │ Manager  │           │  │
│  │  └──────────┘ └──────────┘ └──────────┘           │  │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐           │  │
│  │  │ Resource │ │  Audio   │ │   UI     │           │  │
│  │  │ Manager  │ │ Manager  │ │ Manager  │           │  │
│  │  └──────────┘ └──────────┘ └──────────┘           │  │
│  └─────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

### Engine Class
The main coordinator that:
- Manages the game loop
- Initializes Raylib window
- Coordinates all subsystems through SystemManager
- Handles global state and configuration

### System Manager
Central hub for all major subsystems:
- Manages lifecycle of subsystems
- Provides access to managers
- Handles initialization order
- Coordinates shutdown

## Module Overview

### 1. Core Module (`src/core/`)

The foundation of the engine containing:

- **Engine**: Main game loop and coordination
- **SceneManager**: Scene loading, caching, and transitions
- **InputManager**: Priority-based input handling
- **RenderManager**: Layer-based rendering pipeline
- **ResourceManager**: Asset loading and caching
- **GameStateManager**: Global game state
- **QuestSystem**: Quest and objective tracking
- **SaveSystem**: Game persistence

### 2. Scenes Module (`src/scenes/`)

Scene representation and management:

```
Scene
├── NavigationManager (pathfinding)
├── BackgroundRenderer (visuals)
├── HotspotManager (interactions)
├── WalkableArea (movement constraints)
├── ScaleZoneManager (character scaling)
└── WalkBehindManager (depth sorting)
```

Key components:
- **Scene**: Coordinator for all scene elements
- **NavigationGrid**: A* pathfinding grid
- **PolygonRegion**: Walkable/non-walkable areas
- **Hotspot**: Interactive scene elements
- **TransitionHelper**: Scene transition effects

### 3. Characters Module (`src/characters/`)

Component-based character system:

```
Character
├── AnimationController (animation states)
├── SpriteController (rendering)
├── MovementController (pathfinding)
├── StateManager (behavior states)
└── DialogueManager (conversations)
```

Character types:
- **Player**: Player-controlled character
- **NPC**: Non-player characters
- **ScriptableCharacter**: Lua-controlled characters

### 4. UI Module (`src/ui/`)

User interface components:

- **UIManager**: Coordinates all UI elements
- **DialogManager**: Dialog boxes and text
- **MenuSystem**: Modular menu components
  - MenuInputHandler
  - MenuRenderer
  - MenuNavigator
- **VerbCoin**: Context-sensitive actions
- **StatusBar**: Game information display
- **CursorManager**: Context-aware cursors
- **FloatingDialogManager**: Speech bubbles

### 5. Navigation Module (`src/navigation/`)

Sophisticated pathfinding system:

```
Pathfinding
├── NavigationGrid (grid representation)
├── AStarAlgorithm (pathfinding)
├── HeuristicCalculator (distance calculation)
├── MovementValidator (movement rules)
├── PathOptimizer (path smoothing)
└── DebugRenderer (visualization)
```

### 6. Graphics Module (`src/graphics/`)

Rendering and visual effects:

- **Camera**: Viewport and scrolling
- **AnimatedSprite**: Sprite animations
- **ParticleSystem**: Particle effects
- **TransitionManager**: Scene transitions
- **DisplayManager**: Resolution handling

### 7. Audio Module (`src/audio/`)

Sound and music management:

- **AudioManager**: Main audio coordinator
- **SoundEffectManager**: Sound effects
- **MusicManager**: Background music
- **AmbientSoundManager**: Environmental audio
- **FootstepSystem**: Surface-based footsteps

### 8. Scripting Module (`src/scripting/`)

Lua integration:

- **ScriptEngine**: Main scripting interface
- **LuaEnvironment**: Lua VM management
- **ScriptAPIRegistry**: Crystal-to-Lua bindings
- **EventSystem**: Event-driven communication

### 9. Inventory Module (`src/inventory/`)

Item management:

- **InventorySystem**: Item storage and management
- **InventoryItem**: Item representation
- **ItemCombinations**: Item interaction logic

### 10. Cutscenes Module (`src/cutscenes/`)

Cinematic sequences:

- **CutsceneManager**: Playback control
- **Cutscene**: Action sequences
- **CutsceneAction**: Individual actions

## Component Relationships

### Direct Dependencies
```
Engine
  ├── SystemManager
  │     ├── SceneManager → Scene → [Components]
  │     ├── InputManager → InputHandlers
  │     ├── RenderManager → Renderers
  │     └── UIManager → UI Components
  └── Camera
```

### Event-Based Communication
Components communicate through:
1. Direct method calls (tight coupling)
2. Event system (loose coupling)
3. Callbacks (medium coupling)

Example flow:
```
User Click → InputManager → Scene.handle_click → Hotspot.activate → Script.execute
```

## Data Flow

### Input Flow
```
Raylib Input → InputManager → Priority Handlers → Components
                                ↓
                          Consumption Check
                                ↓
                          State Updates
```

### Update Flow
```
Engine.update(dt)
  ├── SystemManager.update(dt)
  │     ├── Scene.update(dt)
  │     ├── Characters.update(dt)
  │     └── UI.update(dt)
  └── Physics/Animation Updates
```

### Render Flow
```
Engine.render()
  └── RenderManager.render()
        ├── Layer 0: Background
        ├── Layer 1: Scene Objects
        ├── Layer 2: Characters
        ├── Layer 3: UI
        └── Layer 4: Debug
```

## Design Patterns

### 1. Coordinator Pattern
Main classes coordinate component interactions without handling implementation details.

```crystal
class Scene
  def initialize
    @navigation_manager = NavigationManager.new
    @hotspot_manager = HotspotManager.new
    @background_renderer = BackgroundRenderer.new
  end
  
  def update(dt)
    @navigation_manager.update(dt)
    # Coordinate component updates
  end
end
```

### 2. Component Pattern
Functionality is split into focused, reusable components.

```crystal
class MovementController
  def initialize(@character : Character)
  end
  
  def move_to(target : Vector2)
    # Handle movement logic
  end
end
```

### 3. Strategy Pattern
Pluggable implementations for algorithms.

```crystal
abstract class HeuristicCalculator
  abstract def calculate(from : Node, to : Node) : Float32
end

class ManhattanHeuristic < HeuristicCalculator
  def calculate(from : Node, to : Node) : Float32
    # Manhattan distance
  end
end
```

### 4. Observer Pattern
Event-driven communication between decoupled components.

```crystal
EventSystem.emit("scene_changed", {scene: "hallway"})
EventSystem.on("scene_changed") do |data|
  # React to scene change
end
```

### 5. Result Monad Pattern
Explicit error handling without exceptions.

```crystal
def load_scene(name : String) : Result(Scene, SceneError)
  # Returns either Success(scene) or Failure(error)
end
```

## Best Practices

### 1. Component Design
- Keep components focused on a single responsibility
- Use dependency injection for required dependencies
- Prefer composition over inheritance
- Make components testable in isolation

### 2. Error Handling
- Use Result types for operations that can fail
- Validate data at load time, not runtime
- Provide meaningful error messages
- Fail fast with clear diagnostics

### 3. Performance
- Use object pooling for frequently created objects
- Cache expensive computations
- Profile before optimizing
- Keep the hot path efficient

### 4. Testing
- Test components in isolation
- Use mocks for dependencies
- Focus on behavior, not implementation
- Maintain high test coverage

### 5. Documentation
- Document public APIs thoroughly
- Explain the "why", not just the "what"
- Keep examples up to date
- Use meaningful names

## Conclusion

The Point & Click Engine's architecture provides a robust foundation for adventure game development. Its component-based design ensures maintainability, testability, and extensibility while the data-driven approach enables rapid game development with minimal coding.

For detailed information about specific modules, see the individual documentation files in the `docs/` directory.