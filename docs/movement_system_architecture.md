# Movement System Architecture

## Overview

The Point & Click Engine's movement system is designed as a layered architecture that separates concerns between user input, pathfinding logic, and character movement execution. This document provides a comprehensive overview of the system's architecture, components, and data flow.

## System Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           MOVEMENT SYSTEM ARCHITECTURE                        │
└─────────────────────────────────────────────────────────────────────────────┘

INPUT LAYER
┌──────────────────┐    ┌──────────────────┐    ┌──────────────────┐
│   Mouse/Touch    │    │   Keyboard       │    │   Game Events    │
│   Input          │    │   Input          │    │   (Cutscenes)    │
└─────────┬────────┘    └─────────┬────────┘    └─────────┬────────┘
          │                       │                       │
          └───────────────────────┼───────────────────────┘
                                  │
                                  ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                            VERB INPUT SYSTEM                                │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐           │
│  │  handle_walk_to │  │ handle_look_at  │  │  handle_use_on  │    ...    │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘           │
└──────────────────────────────┬──────────────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                             PLAYER LAYER                                    │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                     Player.handle_click()                           │   │
│  │                                                                     │   │
│  │  1. Validate movement_enabled flag                                  │   │
│  │  2. Check minimum click distance                                    │   │
│  │  3. Determine if target is walkable                                 │   │
│  │  4. Find nearest walkable point if needed                          │   │
│  │  5. Delegate to character.walk_to()                                │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
└──────────────────────────────┬──────────────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                           CHARACTER LAYER                                   │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                  Character.walk_to()                                │   │
│  │                                                                     │   │
│  │  1. Validate target position                                       │   │
│  │  2. Set character state to Walking                                 │   │
│  │  3. Delegate to MovementController                                 │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
└──────────────────────────────┬──────────────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                         MOVEMENT CONTROLLER                                 │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                MovementController.move_to()                         │   │
│  │                                                                     │   │
│  │  1. Clear existing movement data                                   │   │
│  │  2. Check pathfinding preference                                   │   │
│  │  3. Calculate path if pathfinding enabled                          │   │
│  │  4. Set up movement (direct or pathfinding)                        │   │
│  │  5. Start animation                                                 │   │
│  └─────────┬───────────────────────────────────────────────────────────┘   │
│            │                                                               │
│            ▼                                                               │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │              MovementController.update()                            │   │
│  │                                                                     │   │
│  │  Called every frame:                                                │   │
│  │  1. Check if character should be walking                           │   │
│  │  2. Route to direct movement OR pathfinding movement               │   │
│  │  3. Update character position                                      │   │
│  │  4. Handle arrival and waypoint advancement                        │   │
│  │  5. Trigger completion callbacks                                   │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
└──────────────────┬────────────────────────────┬─────────────────────────────┘
                   │                            │
                   ▼                            ▼
┌─────────────────────────────┐    ┌─────────────────────────────┐
│     DIRECT MOVEMENT         │    │    PATHFINDING MOVEMENT     │
│                             │    │                             │
│ update_direct_movement()    │    │ update_pathfinding_movement()│
│                             │    │                             │
│ 1. Calculate direction      │    │ 1. Get current waypoint     │
│ 2. Check arrival            │    │ 2. Calculate fresh distance │
│ 3. Move toward target       │    │ 3. Check waypoint reached   │
│ 4. Update position          │    │ 4. Advance or move toward   │
│                             │    │ 5. Handle path completion   │
└─────────────┬───────────────┘    └─────────────┬───────────────┘
              │                                  │
              └──────────────┬───────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                         PATHFINDING SYSTEM                                  │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                      Scene.find_path()                              │   │
│  │                                                                     │   │
│  │  1. Get navigation grid for scene                                  │   │
│  │  2. Create pathfinder instance                                     │   │
│  │  3. Run A* algorithm                                               │   │
│  │  4. Return optimized waypoint path                                 │   │
│  └─────────┬───────────────────────────────────────────────────────────┘   │
│            │                                                               │
│            ▼                                                               │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │              NavigationGrid Generation                              │   │
│  │                                                                     │   │
│  │  1. Divide scene into grid cells                                   │   │
│  │  2. Check walkable area for each cell                              │   │
│  │  3. Account for character radius                                   │   │
│  │  4. Mark obstacles from hotspots                                   │   │
│  │  5. Create pathfinding-ready grid                                  │   │
│  └─────────┬───────────────────────────────────────────────────────────┘   │
│            │                                                               │
│            ▼                                                               │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                    A* Pathfinding Algorithm                         │   │
│  │                                                                     │   │
│  │  1. Open list with start node                                      │   │
│  │  2. Evaluate neighbors (4 or 8 directional)                       │   │
│  │  3. Calculate G, H, and F costs                                    │   │
│  │  4. Select lowest F cost node                                      │   │
│  │  5. Repeat until goal found or exhausted                           │   │
│  │  6. Reconstruct path from goal to start                            │   │
│  │  7. Optimize path (remove redundant waypoints)                     │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────┘

SUPPORTING SYSTEMS
┌──────────────────┐    ┌──────────────────┐    ┌──────────────────┐
│  WalkableArea    │    │   VectorMath     │    │ AnimationSystem  │
│                  │    │                  │    │                  │
│ • Point testing  │    │ • Distance calc  │    │ • Direction anims│
│ • Nearest point  │    │ • Move towards   │    │ • Idle anims     │
│ • Polygon bounds │    │ • Direction calc │    │ • State mgmt     │
└──────────────────┘    └──────────────────┘    └──────────────────┘
```

## Core Components

### 1. VerbInputSystem
**Responsibility**: Translates high-level game interactions into movement commands.

**Key Methods**:
- `handle_walk_to()`: Processes walk commands from UI
- Delegates to `Player.handle_click()` for consistency

**Design Principle**: Single point of entry for all movement requests.

### 2. Player
**Responsibility**: Player-specific movement logic and input validation.

**Key Methods**:
- `handle_click(mouse_pos, scene)`: Main entry point for player movement
- Validates movement permissions and distances
- Finds nearest walkable points for invalid targets

**Features**:
- Movement enable/disable (for cutscenes)
- Minimum click distance filtering
- Automatic nearest-point finding

### 3. Character (Base Class)
**Responsibility**: Generic character movement interface.

**Key Methods**:
- `walk_to(target, use_pathfinding)`: Initiates movement
- `update(dt)`: Per-frame updates (delegates to MovementController)
- State management (Idle, Walking, etc.)

### 4. MovementController
**Responsibility**: Core movement execution and pathfinding integration.

**Key Features**:
- **Dual Movement Modes**: Direct movement and pathfinding
- **Fresh Distance Calculations**: Prevents cached value bugs
- **Waypoint Management**: Handles pathfinding route advancement
- **Animation Integration**: Coordinates movement with character animations

**Critical Methods**:
- `move_to()`: Sets up movement (pathfinding or direct)
- `update()`: Per-frame movement processing
- `update_pathfinding_movement()`: Handles waypoint advancement
- `update_direct_movement()`: Handles straight-line movement

### 5. Pathfinding System
**Responsibility**: Route calculation and navigation mesh management.

**Components**:
- **NavigationGrid**: Discrete walkability representation
- **Pathfinding**: A* algorithm implementation
- **Node**: Individual pathfinding graph nodes

**Key Features**:
- Grid-based navigation with configurable cell size
- Character radius awareness during grid generation
- Path optimization to reduce waypoint count
- Support for diagonal movement (optional)

### 6. WalkableArea
**Responsibility**: Defines valid movement regions using polygon geometry.

**Key Features**:
- Polygon-based walkable region definition
- Point-in-polygon testing
- Nearest walkable point search
- Scale zone integration for character sizing

## Data Flow Patterns

### Movement Initiation Flow

1. **User Input** → Mouse click or keyboard command
2. **VerbInputSystem** → Processes input type and delegates
3. **Player.handle_click()** → Validates and prepares movement
4. **Character.walk_to()** → Sets character state
5. **MovementController.move_to()** → Chooses movement mode
6. **Pathfinding (if enabled)** → Calculates route
7. **Movement Execution** → Begins per-frame updates

### Per-Frame Update Flow

1. **Character.update()** → Delegates to movement controller
2. **MovementController.update()** → Routes to appropriate handler
3. **Movement Handler** → Updates position and checks completion
4. **Position Update** → Updates character and sprite positions
5. **Animation Update** → Adjusts character direction and animation
6. **Completion Check** → Handles arrival and callbacks

### Pathfinding-Specific Flow

1. **Scene.find_path()** → Entry point for pathfinding requests
2. **NavigationGrid.from_scene()** → Generates walkability grid
3. **Pathfinding.find_path()** → Runs A* algorithm
4. **Path Optimization** → Removes redundant waypoints
5. **MovementController.setup_pathfinding()** → Prepares for execution
6. **Waypoint Advancement** → Moves through route step by step

## Key Design Decisions

### 1. Layered Architecture
**Decision**: Separate input processing, movement logic, and pathfinding execution.

**Rationale**: 
- Enables independent testing of each layer
- Allows different input sources (mouse, keyboard, AI)
- Facilitates debugging and maintenance

### 2. Fresh Distance Calculations
**Decision**: Always calculate fresh distances for critical pathfinding decisions.

**Rationale**:
- Prevents bugs from stale cached values
- Ensures accurate waypoint advancement
- Small performance cost vs. reliability

### 3. Character Position at Feet
**Decision**: Store character position at bottom-center (feet) of sprite.

**Rationale**:
- Natural visual alignment with ground surfaces
- Consistent depth sorting for overlapping characters
- Intuitive pathfinding waypoint placement

### 4. Dual Movement Modes
**Decision**: Support both direct movement and pathfinding in the same controller.

**Rationale**:
- Allows fallback when pathfinding fails
- Enables performance optimization for simple movements
- Provides flexibility for different game scenarios

### 5. Grid-Based Pathfinding
**Decision**: Use discrete grid cells for navigation mesh.

**Rationale**:
- Efficient A* algorithm implementation
- Predictable performance characteristics
- Easy integration with existing polygon-based walkable areas

## Error Handling and Edge Cases

### Movement Validation
- **Target too close**: Filtered out to prevent micro-movements
- **Target not walkable**: Automatically finds nearest valid point
- **Movement disabled**: Respects player control flags (cutscenes)

### Pathfinding Robustness
- **No path found**: Falls back to direct movement
- **Path becomes invalid**: Stops movement gracefully
- **Infinite loops**: Limited search nodes and recalculation attempts

### Character State Management
- **Movement interruption**: Clean state transitions
- **Completion callbacks**: Guaranteed execution on movement end
- **Animation synchronization**: Direction updates based on movement

## Performance Considerations

### Optimization Strategies

1. **Cached Direction Calculations**: Reuse vector math where safe
2. **Path Optimization**: Remove unnecessary waypoints
3. **Grid Generation**: Only regenerate when scene changes
4. **Search Limits**: Constrain A* algorithm to prevent hangs
5. **Distance Thresholds**: Early arrival detection

### Performance Monitoring

The system includes configurable debug levels for performance analysis:
- **Movement timing**: Track per-frame update costs
- **Pathfinding performance**: Monitor A* algorithm execution time
- **Memory usage**: Watch for pathfinding memory leaks

## Testing Strategy

### Unit Testing
- **MovementController**: Edge cases and state transitions
- **Pathfinding**: Algorithm correctness and performance
- **Coordinate Systems**: World-to-grid transformations

### Integration Testing
- **End-to-end movement**: Full pipeline from click to arrival
- **Pathfinding integration**: Complex multi-waypoint routes
- **Character interaction**: Multiple characters and collision

### Performance Testing
- **Large grids**: Pathfinding on complex scenes
- **Many characters**: Concurrent movement performance
- **Memory stress**: Long-running pathfinding operations

## Debug and Visualization

### Debug Configuration
The system provides comprehensive debug visualization:

```crystal
# Enable full movement debugging
Core::DebugConfig.enable_visual_debugging
Core::DebugConfig.enable_verbose_logging

# Shows:
# - Navigation grid overlay
# - Walkable area highlighting  
# - Pathfinding routes (yellow lines)
# - Waypoint positions (circles)
# - Character collision bounds
# - Movement state logging
```

### Debugging Tools
- **Grid Visualization**: Overlay showing walkable/blocked cells
- **Path Rendering**: Visual representation of calculated routes
- **Position Logging**: Detailed movement state information
- **Performance Metrics**: Timing and memory usage statistics

## Future Extensibility

### Planned Enhancements
1. **Hierarchical Pathfinding**: Multiple grid resolutions
2. **Dynamic Obstacles**: Moving objects in pathfinding
3. **Group Movement**: Coordinated multi-character movement
4. **Path Caching**: Store frequently used routes
5. **Smooth Curves**: Spline-based path smoothing

### Extension Points
The architecture supports extension through:
- **Custom Movement Controllers**: Specialized movement behaviors
- **Alternative Pathfinding**: Replace A* with other algorithms
- **Input Sources**: Additional input methods beyond mouse/keyboard
- **Movement Effects**: Speed boosts, obstacles, special abilities

This architecture provides a robust, maintainable foundation for character movement that can handle the complexity of adventure games while remaining performant and debuggable.