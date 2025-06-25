# Coordinate Systems in Point & Click Engine

## Overview

This document standardizes the coordinate systems used throughout the Point & Click Engine to ensure consistency and prevent bugs. Understanding these coordinate systems is crucial for proper movement, pathfinding, and collision detection.

## World Coordinates

**Definition**: World coordinates represent the actual pixel positions in the game world.

### Characteristics:
- **Origin**: Top-left corner (0, 0)
- **Units**: Pixels (Float32)
- **Positive X**: Rightward
- **Positive Y**: Downward (screen coordinate system)
- **Range**: 0.0 to scene width/height (typically 1024x768 or larger)

### Usage:
- Character positions
- Mouse click positions
- Sprite rendering positions
- Walkable area polygon vertices
- Hotspot boundaries

### Example:
```crystal
player_position = RL::Vector2.new(x: 456.5_f32, y: 312.8_f32)
mouse_click = RL::Vector2.new(x: 720.0_f32, y: 480.0_f32)
```

## Grid Coordinates

**Definition**: Grid coordinates represent discrete cell positions in the navigation mesh.

### Characteristics:
- **Origin**: Top-left corner (0, 0)
- **Units**: Grid cells (Int32)
- **Cell Size**: Configurable (default: 32 pixels)
- **Positive X**: Rightward
- **Positive Y**: Downward
- **Range**: 0 to (scene_dimension / cell_size)

### Usage:
- Navigation mesh generation
- Pathfinding algorithm (A*)
- Obstacle placement
- Walkability checks

### Example:
```crystal
# For 32x32 pixel cells
world_pos = RL::Vector2.new(x: 100.0_f32, y: 200.0_f32)
grid_x, grid_y = navigation_grid.world_to_grid(world_pos.x, world_pos.y)
# Result: grid_x = 3, grid_y = 6 (100/32 = 3.125 → 3, 200/32 = 6.25 → 6)
```

## Coordinate Transformations

### World to Grid Conversion

Converts world pixel coordinates to grid cell indices:

```crystal
def world_to_grid(world_x : Float32, world_y : Float32) : {Int32, Int32}
  grid_x = (world_x / cell_size).to_i
  grid_y = (world_y / cell_size).to_i
  {grid_x, grid_y}
end
```

**Important**: This truncates to the grid cell containing the point.

### Grid to World Conversion

Converts grid cell indices to world coordinates at the **cell center**:

```crystal
def grid_to_world(grid_x : Int32, grid_y : Int32) : {Float32, Float32}
  world_x = (grid_x * cell_size + cell_size / 2).to_f32
  world_y = (grid_y * cell_size + cell_size / 2).to_f32
  {world_x, world_y}
end
```

**Key Point**: Grid-to-world conversion always returns the center of the cell, not the top-left corner.

### Example Coordinate Mappings

For 32x32 pixel cells:

| World Coordinates | Grid Coordinates | Grid Center (World) |
|-------------------|------------------|---------------------|
| (0, 0)           | (0, 0)           | (16, 16)           |
| (15, 15)         | (0, 0)           | (16, 16)           |
| (32, 32)         | (1, 1)           | (48, 48)           |
| (100, 200)       | (3, 6)           | (112, 208)         |

## Character Position System

### Character Position Reference Point

**Critical**: Character positions are stored at the **bottom-center** of the character sprite (at the character's "feet").

```crystal
# Character position represents the feet position
character.position = RL::Vector2.new(x: 400.0_f32, y: 300.0_f32)

# The character sprite extends upward from this point
# For a 32x64 character:
# - Feet at: (400, 300)
# - Top at: (400, 236) [300 - 64]
# - Left edge: (384, y) [400 - 16]
# - Right edge: (416, y) [400 + 16]
```

### Character Collision Bounds

For collision detection, the character's center position is calculated:

```crystal
def get_character_center(character : Character) : RL::Vector2
  RL::Vector2.new(
    x: character.position.x,
    y: character.position.y - (character.size.y * character.scale) / 2.0_f32
  )
end
```

### Why This Matters

This positioning system ensures:
1. Characters appear to "stand on" surfaces correctly
2. Pathfinding waypoints align with where characters should walk
3. Collision detection works consistently
4. Visual depth sorting works properly (characters further down appear in front)

## Movement Thresholds and Constants

### Key Distance Thresholds

```crystal
module GameConstants
  MOVEMENT_ARRIVAL_THRESHOLD     = 5.0_f32  # Distance to consider "arrived"
  PATHFINDING_WAYPOINT_THRESHOLD = 10.0_f32 # Distance to waypoint "reached"
  DIRECTION_UPDATE_THRESHOLD     = 5.0_f32  # Min distance for direction change
  MINIMUM_CLICK_DISTANCE         = 2.0_f32  # Min click distance for movement
end
```

### Grid Constants

```crystal
module GameConstants
  DEFAULT_NAVIGATION_CELL_SIZE = 32         # Grid cell size in pixels
  DEFAULT_CHARACTER_RADIUS    = 32.0_f32   # Character radius for navigation
  NAVIGATION_RADIUS_REDUCTION = 0.7_f32    # Radius reduction for grid generation
end
```

## Common Coordinate Issues and Solutions

### Issue 1: Character Getting Stuck at Grid Boundaries

**Problem**: Character stops at navigation grid cell boundaries.

**Cause**: Mixing grid coordinates with world coordinates in movement calculations.

**Solution**: Always use fresh world coordinate calculations for movement, not cached grid-based values.

### Issue 2: Pathfinding Returns Wrong Positions

**Problem**: Waypoints don't align with clickable positions.

**Cause**: Forgetting that grid-to-world returns cell centers, not exact click positions.

**Solution**: For same-cell movement, return exact target positions rather than grid centers.

### Issue 3: Collision Detection Fails

**Problem**: Character clips through obstacles or can't walk in valid areas.

**Cause**: Character position (feet) vs collision center mismatch.

**Solution**: Always convert to appropriate coordinate space for the operation being performed.

## Best Practices

### 1. Coordinate Conversion

```crystal
# ✅ Good: Clear about coordinate space
world_pos = RL::Vector2.new(x: 150.0_f32, y: 200.0_f32)
grid_x, grid_y = navigation_grid.world_to_grid(world_pos.x, world_pos.y)

# ❌ Bad: Mixing coordinate spaces
character.position = RL::Vector2.new(x: 5, y: 3)  # These look like grid coords!
```

### 2. Distance Calculations

```crystal
# ✅ Good: Use fresh calculations for critical logic
fresh_distance = Utils::VectorMath.distance(character.position, target)
if fresh_distance <= PATHFINDING_WAYPOINT_THRESHOLD
  advance_to_next_waypoint()
end

# ❌ Bad: Using potentially stale cached values
if cached_distance <= threshold  # May be outdated!
```

### 3. Pathfinding Integration

```crystal
# ✅ Good: Handle same-cell movement correctly
if start_grid == end_grid && distance > SAME_CELL_DISTANCE_THRESHOLD
  return [start_pos, end_pos]  # Direct path to exact position
end

# ❌ Bad: Always using grid centers
return [grid_center_start, grid_center_end]  # Loses precision
```

### 4. Character Positioning

```crystal
# ✅ Good: Remember character position is at feet
collision_center = RL::Vector2.new(
  x: character.position.x,
  y: character.position.y - character.size.y / 2.0_f32
)

# ❌ Bad: Using character position directly for collision
if bounds.contains?(character.position)  # Wrong reference point!
```

## Debug Visualization

When debugging coordinate issues, enable visual debugging:

```crystal
# Enable visual debugging
Core::DebugConfig.enable_visual_debugging

# This will show:
# - Navigation grid overlay
# - Walkable areas (colored)
# - Pathfinding routes (yellow lines with waypoints)
# - Character collision bounds
```

## Testing Coordinate Systems

Always test coordinate transformations with these cases:

1. **Origin**: (0, 0) world coordinates
2. **Grid boundaries**: Positions exactly at grid cell edges
3. **Large coordinates**: Near scene boundaries
4. **Fractional positions**: Non-integer world coordinates
5. **Same-cell movement**: Start and end in same grid cell

## Migration Notes

When updating coordinate-related code:

1. **Always verify** that world coordinates are being used for movement
2. **Check** that grid coordinates are only used for navigation mesh operations
3. **Test** pathfinding at grid boundaries
4. **Ensure** character collision detection uses the correct reference point
5. **Validate** that cached values are properly invalidated

This coordinate system standardization prevents the types of bugs that caused characters to get stuck during movement and ensures consistent behavior across all movement-related systems.