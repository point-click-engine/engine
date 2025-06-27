# Point & Click Engine Developer Quick Start

This guide helps developers quickly understand and work with the Point & Click Engine codebase.

## Table of Contents
1. [Project Setup](#project-setup)
2. [Architecture Overview](#architecture-overview)
3. [Key Concepts](#key-concepts)
4. [Common Tasks](#common-tasks)
5. [Testing](#testing)
6. [Debugging](#debugging)
7. [Contributing](#contributing)

## Project Setup

### Prerequisites
- Crystal 1.0+
- Raylib (installed via shards)
- Lua 5.4
- Git

### Initial Setup
```bash
# Clone repository
git clone <repository-url>
cd point_click_engine

# Install dependencies
shards install

# Run tests to verify setup
./run.sh spec

# Run example game
./run.sh crystal_mystery/main.cr
```

## Architecture Overview

The engine follows a **component-based architecture** with these key principles:

### Core Structure
```
Engine (Main Coordinator)
  └── SystemManager (Subsystem Management)
        ├── SceneManager
        ├── InputManager
        ├── RenderManager
        ├── UIManager
        ├── CameraManager (Advanced Camera System)
        ├── AudioManager
        └── Other Managers...
```

### Key Design Patterns
1. **Coordinator Pattern** - Main classes orchestrate components
2. **Component Pattern** - Functionality split into focused components
3. **Result Monad** - Error handling without exceptions
4. **Dependency Injection** - Components receive dependencies

## Key Concepts

### 1. Component-Based Design
Instead of monolithic classes, functionality is split into components:

```crystal
class Character
  def initialize
    @animation_controller = AnimationController.new(self)
    @movement_controller = MovementController.new(self)
    @sprite_controller = SpriteController.new(self)
  end
end
```

### 2. Error Handling
Use `Result<T, E>` for operations that can fail:

```crystal
def load_texture(path : String) : Result(Texture, AssetError)
  if File.exists?(path)
    Success(Texture).new(RL.load_texture(path))
  else
    Failure(AssetError).new("File not found: #{path}")
  end
end
```

### 3. Layer-Based Rendering
Rendering uses numbered layers:
- Layer 0: Background
- Layer 1: Scene objects
- Layer 2: Characters
- Layer 3: UI
- Layer 4: Debug overlay

### 4. Priority-Based Input
Input handlers have priorities (higher = processed first):
```crystal
input_manager.register_handler(dialog_handler, priority: 100)
input_manager.register_handler(scene_handler, priority: 50)
```

## Common Tasks

### Adding a New Component

1. Create component class:
```crystal
# src/characters/new_component.cr
module PointClickEngine
  module Characters
    class NewComponent
      def initialize(@character : Character)
      end
      
      def update(dt : Float32)
        # Update logic
      end
    end
  end
end
```

2. Add to coordinator:
```crystal
# In Character class
@new_component = NewComponent.new(self)
```

3. Write tests:
```crystal
# spec/characters/new_component_spec.cr
describe NewComponent do
  it "performs its function" do
    character = MockCharacter.new
    component = NewComponent.new(character)
    # Test component behavior
  end
end
```

### Creating a Custom Scene Transition

1. Create transition effect:
```crystal
# src/graphics/transitions/effects/custom_effect.cr
class CustomTransition < TransitionEffect
  def update(progress : Float32)
    # Update transition state
  end
  
  def render
    # Render transition effect
  end
end
```

2. Register with manager:
```crystal
transition_manager.register_effect("custom", CustomTransition)
```

### Adding a Lua API Function

1. Define Crystal method:
```crystal
# src/scripting/custom_api.cr
def lua_custom_function(x : Float32, y : Float32) : String
  "Called with #{x}, #{y}"
end
```

2. Register with API:
```crystal
registry.register_function("custom_function", ->lua_custom_function)
```

3. Use in Lua:
```lua
result = custom_function(10.5, 20.3)
```

### Working with Camera Effects

Apply various camera effects through CameraManager:
```crystal
# Access camera manager
camera_manager = engine.camera_manager

# Apply shake effect (earthquake)
camera_manager.apply_effect(:shake, 
  intensity: 20.0f32, 
  duration: 2.0f32
)

# Smooth zoom
camera_manager.apply_effect(:zoom, 
  target: 2.0f32, 
  duration: 1.5f32
)

# Follow character
camera_manager.apply_effect(:follow,
  target: player,
  smooth: true,
  deadzone: 50.0f32
)

# Remove all effects
camera_manager.remove_all_effects
```

### Implementing a New UI Element

1. Create UI component:
```crystal
class CustomUIElement
  include Renderable
  include InputHandler
  
  def update(dt : Float32)
    # Update logic
  end
  
  def render
    # Render element
  end
  
  def handle_input(input : InputState) : Bool
    # Return true if input consumed
  end
end
```

2. Register with UIManager:
```crystal
ui_manager.add_element(custom_element)
```

## Testing

### Running Tests
```bash
# All tests
./run.sh spec

# Specific module
crystal spec spec/core/

# Single file
crystal spec spec/core/engine_spec.cr

# With error trace
crystal spec --error-trace
```

### Writing Tests

#### Unit Test Example
```crystal
describe AnimationController do
  it "plays animations" do
    character = MockCharacter.new
    controller = AnimationController.new(character)
    
    controller.play("walk")
    controller.current_animation.should eq("walk")
  end
end
```

#### Integration Test Example
```crystal
describe "Scene transitions" do
  it "transitions between scenes" do
    engine = create_test_engine
    engine.scene_manager.add_scene(scene1)
    engine.scene_manager.add_scene(scene2)
    
    engine.scene_manager.change_scene("scene2")
    engine.current_scene.name.should eq("scene2")
  end
end
```

### Test Helpers
- `MockCharacter` - Character without graphics
- `MockScene` - Scene for testing
- `create_test_engine` - Engine without window

## Debugging

### Debug Mode
Enable debug rendering:
```crystal
Engine.debug_mode = true
```

Shows:
- Walkable areas
- Navigation grid
- Hotspot boundaries
- Character bounds
- Performance metrics

### Logging
```crystal
Log.info { "Scene loaded: #{scene.name}" }
Log.debug { "Character position: #{character.position}" }
Log.error { "Failed to load asset: #{path}" }
```

### Common Issues

#### "Engine not initialized"
Ensure Engine.new is called before accessing Engine.instance

#### "Asset not found"
Check working directory with `Dir.current`

#### Input not working
Check input consumption: `input_manager.is_consumed?(:mouse_click)`

## Contributing

### Code Style
- Use Crystal formatter: `crystal tool format`
- Follow naming conventions:
  - Classes: `PascalCase`
  - Methods/variables: `snake_case`
  - Constants: `SCREAMING_SNAKE_CASE`

### Pull Request Checklist
- [ ] Tests pass (`./run.sh spec`)
- [ ] Code formatted (`crystal tool format`)
- [ ] Documentation updated
- [ ] Examples work
- [ ] No compiler warnings

### Adding Features
1. Discuss in issue first
2. Write tests
3. Implement feature
4. Update documentation
5. Add example to crystal_mystery
6. Submit PR

### Component Guidelines
- Single responsibility
- Dependency injection
- Testable in isolation
- Clear public API
- Comprehensive documentation

## Quick Reference

### File Structure
```
src/
├── core/          # Engine core
├── scenes/        # Scene system
├── characters/    # Character system
├── ui/           # User interface
├── graphics/     # Rendering
├── audio/        # Sound system
├── navigation/   # Pathfinding
├── scripting/    # Lua integration
└── utils/        # Utilities

spec/             # Tests (mirrors src/)
docs/             # Documentation
examples/         # Example code
crystal_mystery/  # Example game
```

### Key Classes
- `Engine` - Main game engine
- `Scene` - Scene representation
- `Character` - Base character class
- `UIManager` - UI coordination
- `ScriptEngine` - Lua integration
- `ResourceManager` - Asset management

### Important Interfaces
- `Renderable` - Can be rendered
- `Updateable` - Has update method
- `InputHandler` - Handles input
- `Scriptable` - Lua scriptable

### Useful Commands
```bash
# Development
./run.sh main.cr              # Run game
./run.sh spec                 # Run tests
./run.sh build main.cr        # Build executable

# Debugging
export DEBUG=1                # Enable debug output
export LOG_LEVEL=debug        # Verbose logging

# Performance
./run.sh test-stress          # Stress tests
./run.sh test-memory          # Memory tests
```

## Next Steps

1. Read [Architecture Overview](ARCHITECTURE_OVERVIEW.md)
2. Study [Component Reference](COMPONENT_REFERENCE.md)
3. Explore example game in `crystal_mystery/`
4. Try modifying a simple component
5. Write and run tests

For detailed information, see the full documentation in the `docs/` directory.