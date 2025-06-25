# Component Architecture Guide

## Overview

The Point & Click Engine follows a modular component-based architecture, where large monolithic classes have been refactored into focused, reusable components. This guide explains the component system, design patterns used, and how to work with the modular architecture.

## Core Design Principles

### SOLID Principles
- **Single Responsibility**: Each component has one clear purpose
- **Open/Closed**: Components are open for extension but closed for modification
- **Liskov Substitution**: Implementations can be swapped without affecting behavior
- **Interface Segregation**: Components expose minimal, focused interfaces
- **Dependency Inversion**: High-level modules don't depend on low-level details

### Key Patterns
- **Composition over Inheritance**: Systems use composition for flexibility
- **Dependency Injection**: Components accept dependencies rather than creating them
- **Coordinator Pattern**: Main classes coordinate component interactions
- **Strategy Pattern**: Swappable algorithms for different behaviors

## Component Catalog

### Character System Components

#### AnimationController
**Location**: `src/characters/animation_controller.cr`
**Purpose**: Manages all character animation logic
**Key Features**:
- Animation state management
- Frame timing and progression
- Animation transition handling
- Looping and one-shot animations

```crystal
animation_controller = AnimationController.new
animation_controller.play("walk_right")
animation_controller.update(delta_time)
```

#### SpriteController
**Location**: `src/characters/sprite_controller.cr`
**Purpose**: Handles sprite rendering and visual representation
**Key Features**:
- Sprite sheet management
- Frame extraction and rendering
- Scaling and transformation
- Visual effects application

```crystal
sprite_controller = SpriteController.new(sprite_config)
sprite_controller.render(position, current_frame)
```

#### CharacterStateManager
**Location**: `src/characters/character_state_manager.cr`
**Purpose**: Manages character state and behavior transitions
**Key Features**:
- State machine implementation
- State transition validation
- State persistence and restoration
- Event-driven state changes

```crystal
state_manager = CharacterStateManager.new
state_manager.transition_to(CharacterState::Walking)
```

### Scene System Components

#### NavigationManager
**Location**: `src/scenes/navigation_manager.cr`
**Purpose**: Handles pathfinding and navigation within scenes
**Key Features**:
- Walkable area management
- Navigation mesh generation
- Path request handling
- Movement validation

```crystal
nav_manager = NavigationManager.new(walkable_area)
path = nav_manager.find_path(start_pos, end_pos)
```

#### BackgroundRenderer
**Location**: `src/scenes/background_renderer.cr`
**Purpose**: Manages scene background rendering and effects
**Key Features**:
- Background image loading and rendering
- Parallax scrolling support
- Environmental effects
- Performance optimization

```crystal
bg_renderer = BackgroundRenderer.new
bg_renderer.render(camera_position)
```

#### HotspotManager
**Location**: `src/scenes/hotspot_manager.cr`
**Purpose**: Manages interactive hotspots in scenes
**Key Features**:
- Hotspot registration and removal
- Click detection and handling
- Hotspot highlighting
- Action mapping

```crystal
hotspot_manager = HotspotManager.new
hotspot_manager.add_hotspot(hotspot)
clicked_hotspot = hotspot_manager.get_hotspot_at(mouse_pos)
```

### Menu System Components

#### MenuInputHandler
**Location**: `src/ui/menu_input_handler.cr`
**Purpose**: Centralizes all menu input processing
**Key Features**:
- Keyboard navigation handling
- Mouse interaction processing
- Gamepad support
- Input repeat management

```crystal
input_handler = MenuInputHandler.new
action = input_handler.process_input(delta_time)
```

#### MenuRenderer
**Location**: `src/ui/menu_renderer.cr`
**Purpose**: Handles visual rendering for menus
**Key Features**:
- Theme management
- Layout calculation
- Animation effects
- Responsive design

```crystal
renderer = MenuRenderer.new
renderer.draw_menu(bounds, title, items, selected_index)
```

#### MenuNavigator
**Location**: `src/ui/menu_navigator.cr`
**Purpose**: Manages menu navigation logic
**Key Features**:
- Item selection tracking
- Wrap-around navigation
- Disabled item handling
- Navigation callbacks

```crystal
navigator = MenuNavigator.new(item_count)
navigator.navigate_next
selected = navigator.get_selected_index
```

#### ConfigurationManager
**Location**: `src/ui/configuration_manager.cr`
**Purpose**: Handles game settings and configuration
**Key Features**:
- Settings persistence
- Configuration validation
- Change notifications
- Default management

```crystal
config_manager = ConfigurationManager.new
config_manager.set_resolution(1920, 1080)
config_manager.save_configuration
```

### Navigation System Components

#### Node
**Location**: `src/navigation/node.cr`
**Purpose**: Pathfinding graph node representation
**Key Features**:
- Cost calculations (g, h, f costs)
- Parent tracking for path reconstruction
- Equality and hashing for collections
- Adjacent node detection

```crystal
node = Node.new(x, y, g_cost, h_cost, parent)
total_cost = node.f_cost
```

#### NavigationGrid
**Location**: `src/navigation/navigation_grid.cr`
**Purpose**: Grid-based navigation mesh
**Key Features**:
- Walkable/non-walkable cell management
- World-to-grid coordinate conversion
- Neighbor cell queries
- Grid generation from scenes

```crystal
grid = NavigationGrid.new(width, height, cell_size)
grid.set_walkable(x, y, false)
neighbors = grid.get_walkable_neighbors(x, y)
```

#### AStarAlgorithm
**Location**: `src/navigation/astar_algorithm.cr`
**Purpose**: Core A* pathfinding implementation
**Key Features**:
- Optimal path finding
- Configurable heuristics
- Performance optimization
- Partial path support

```crystal
astar = AStarAlgorithm.new(grid, heuristic, movement_validator)
path = astar.find_path(start_x, start_y, end_x, end_y)
```

#### HeuristicCalculator
**Location**: `src/navigation/heuristic_calculator.cr`
**Purpose**: Distance calculation strategies
**Key Features**:
- Multiple heuristic methods (Manhattan, Euclidean, Octile, Chebyshev)
- Movement cost calculation
- Admissibility validation
- Performance benchmarking

```crystal
heuristic = HeuristicCalculator.for_point_and_click
distance = heuristic.calculate(from_node, to_node)
```

#### MovementValidator
**Location**: `src/navigation/movement_validator.cr`
**Purpose**: Movement rule validation
**Key Features**:
- Diagonal movement validation
- Corner cutting prevention
- Movement cost calculation
- Path validation

```crystal
validator = MovementValidator.for_point_and_click
can_move = validator.can_move?(grid, from_x, from_y, to_x, to_y)
```

#### PathOptimizer
**Location**: `src/navigation/path_optimizer.cr`
**Purpose**: Path smoothing and optimization
**Key Features**:
- Redundant waypoint removal
- Line-of-sight optimization
- Path smoothing algorithms
- Path length calculation

```crystal
optimizer = PathOptimizer.new(grid)
smooth_path = optimizer.optimize_path(raw_path)
```

#### PathfindingDebugRenderer
**Location**: `src/navigation/pathfinding_debug_renderer.cr`
**Purpose**: Debug visualization for pathfinding
**Key Features**:
- Grid visualization
- Path rendering
- Algorithm state display
- Performance metrics

```crystal
debug_renderer = PathfindingDebugRenderer.new(grid)
debug_renderer.draw_grid
debug_renderer.draw_path(path)
```

### Validation System Components

#### ValidationResult
**Location**: `src/core/validation/validation_result.cr`
**Purpose**: Standardized validation result structure
**Key Features**:
- Multiple severity levels
- Result aggregation
- Summary generation
- Issue categorization

```crystal
result = ValidationResult.new
result.add_error("Configuration invalid")
result.add_warning("Large asset detected")
```

#### AssetValidationChecker
**Location**: `src/core/validation/asset_validation_checker.cr`
**Purpose**: Validates game assets
**Key Features**:
- File existence checking
- Size validation
- Format verification
- Performance analysis

```crystal
checker = AssetValidationChecker.new
result = checker.validate(config, context)
```

#### RenderingValidationChecker
**Location**: `src/core/validation/rendering_validation_checker.cr`
**Purpose**: Validates rendering configuration
**Key Features**:
- Sprite configuration validation
- Resolution checking
- Animation validation
- GPU compatibility

```crystal
checker = RenderingValidationChecker.new
result = checker.validate(config, context)
```

#### PerformanceValidationChecker
**Location**: `src/core/validation/performance_validation_checker.cr`
**Purpose**: Analyzes performance considerations
**Key Features**:
- Asset size analysis
- Memory usage estimation
- Optimization recommendations
- Platform-specific advice

```crystal
checker = PerformanceValidationChecker.new
result = checker.validate(config, context)
```

#### PreflightOrchestrator
**Location**: `src/core/validation/preflight_orchestrator.cr`
**Purpose**: Coordinates all validation components
**Key Features**:
- Validator execution management
- Result aggregation
- Priority-based execution
- Report generation

```crystal
orchestrator = PreflightOrchestrator.new
result = orchestrator.run_all_validations(config_path)
```

## Working with Components

### Creating New Components

1. **Define Clear Responsibility**
   ```crystal
   # Good: Single, focused responsibility
   class InputValidator
     def validate_key_press(key : Key) : Bool
   
   # Bad: Multiple responsibilities
   class InputManager
     def validate_key_press
     def process_mouse_input
     def update_gamepad_state
   ```

2. **Use Dependency Injection**
   ```crystal
   class MyComponent
     def initialize(@dependency : DependencyInterface)
     end
   end
   ```

3. **Provide Clean Interfaces**
   ```crystal
   abstract class BaseComponent
     abstract def update(dt : Float32)
     abstract def render
   end
   ```

### Composing Components

Example of composing components in a coordinator class:

```crystal
class Character
  def initialize
    @animation = AnimationController.new
    @sprite = SpriteController.new(sprite_config)
    @state = CharacterStateManager.new
    @movement = MovementController.new
  end

  def update(dt : Float32)
    @state.update(dt)
    @movement.update(dt)
    @animation.update(dt)
    @sprite.update_frame(@animation.current_frame)
  end

  def render
    @sprite.render(@movement.position)
  end
end
```

### Testing Components

Components should be tested in isolation:

```crystal
describe AnimationController do
  let(controller) { AnimationController.new }

  it "plays animations" do
    controller.play("walk")
    controller.current_animation.should eq("walk")
  end

  it "updates frame timing" do
    controller.play("walk", loop: true)
    controller.update(0.1)
    controller.current_frame.should eq(expected_frame)
  end
end
```

## Best Practices

### 1. Component Independence
- Components should not depend on specific implementations
- Use interfaces/abstract classes for dependencies
- Avoid circular dependencies

### 2. Clear Communication
- Use events/callbacks for loose coupling
- Document component interfaces thoroughly
- Provide usage examples

### 3. Performance Considerations
- Keep components lightweight
- Avoid unnecessary allocations in update loops
- Profile component performance

### 4. Configuration
- Make components configurable
- Provide sensible defaults
- Validate configuration

### 5. Error Handling
- Components should handle errors gracefully
- Provide meaningful error messages
- Don't hide failures

## Migration Guide

### Migrating from Monolithic Classes

1. **Identify Responsibilities**
   - List all methods and their purposes
   - Group related functionality
   - Define component boundaries

2. **Extract Components**
   - Create new component classes
   - Move related methods
   - Update tests

3. **Create Coordinator**
   - Build coordinator class
   - Inject components
   - Delegate to components

4. **Maintain Compatibility**
   - Keep existing public interfaces
   - Delegate to new components
   - Deprecate old methods gradually

## Component Interaction Patterns

### Event-Driven Communication
```crystal
class EventBus
  def publish(event : Event)
  def subscribe(event_type : Class, &block)
end

# Components communicate through events
@event_bus.publish(PlayerMovedEvent.new(position))
```

### Callback Pattern
```crystal
class Component
  property on_state_changed : Proc(State, Nil)?
  
  private def notify_state_change(new_state : State)
    @on_state_changed.try(&.call(new_state))
  end
end
```

### Service Locator
```crystal
class ServiceLocator
  def self.register(service : T.class, instance : T)
  def self.get(service : T.class) : T
end

# Components can find services
audio = ServiceLocator.get(AudioSystem)
```

## Performance Optimization

### Component Pooling
```crystal
class ComponentPool(T)
  def acquire : T
  def release(component : T)
end
```

### Update Ordering
```crystal
class ComponentManager
  def update_all(dt : Float32)
    # Update in dependency order
    @physics_components.each(&.update(dt))
    @movement_components.each(&.update(dt))
    @animation_components.each(&.update(dt))
  end
end
```

## Debugging Components

### Component Inspector
```crystal
class ComponentInspector
  def inspect_component(component)
    puts "Component: #{component.class}"
    puts "State: #{component.state}"
    puts "Performance: #{component.metrics}"
  end
end
```

### Logging Best Practices
```crystal
class Component
  Log = ::Log.for(self)
  
  def update(dt : Float32)
    Log.debug { "Updating with dt=#{dt}" }
  end
end
```

## Future Directions

### Planned Enhancements
- Component serialization system
- Hot-reloading for development
- Visual component editor
- Performance profiler integration
- Component dependency graph visualization

### Extension Points
- Custom component types
- Plugin system for components
- Component marketplace
- Visual scripting for components

## Conclusion

The component architecture provides a solid foundation for building maintainable and extensible game systems. By following these patterns and practices, developers can create robust, reusable components that work together harmoniously while remaining independently testable and maintainable.