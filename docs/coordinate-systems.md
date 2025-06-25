# Coordinate Systems and Texture Independence

## Overview

The Point & Click Engine uses a texture-independent coordinate system to ensure consistent gameplay across different screen resolutions and texture sizes. This document explains how the coordinate system works and best practices for using it.

## Key Concepts

### Logical Dimensions

Every scene has logical dimensions that define the coordinate space for game logic:
- **logical_width**: The logical width of the scene (default: 1024)
- **logical_height**: The logical height of the scene (default: 768)

These dimensions are independent of:
- The actual texture/background image size
- The window/screen resolution
- The rendering viewport

### Why Texture Independence?

Previously, the engine used texture dimensions for game logic calculations, which caused several issues:
- Changing a background texture would break gameplay positioning
- Artists couldn't freely resize textures without affecting game logic
- Navigation grids would fail if texture dimensions didn't match expected values
- Different texture sizes across scenes caused inconsistent behavior

## Scene Configuration

### YAML Configuration

Always specify logical dimensions in your scene files:

```yaml
name: library
background_path: assets/backgrounds/library.png
logical_width: 1024    # Logical coordinate space width
logical_height: 768    # Logical coordinate space height
enable_pathfinding: true

walkable_areas:
  regions:
    - name: main_floor
      walkable: true
      vertices:
        # All coordinates are in logical space
        - {x: 100, y: 350}
        - {x: 900, y: 350}
        - {x: 900, y: 700}
        - {x: 100, y: 700}
```

### Coordinate Spaces

1. **Logical Space**: Used for all game logic
   - Character positions
   - Hotspot bounds
   - Walkable areas
   - Navigation grids
   - Camera bounds

2. **Texture Space**: Used only for rendering
   - The actual pixel dimensions of textures
   - Automatically scaled to fit logical space

3. **Screen Space**: The final rendered output
   - Window dimensions
   - May include letterboxing or scaling

## Best Practices

### 1. Always Use Logical Coordinates

When defining positions in YAML or code, always use logical coordinates:

```yaml
hotspots:
  - name: door
    x: 850        # Logical X coordinate
    y: 400        # Logical Y coordinate
    width: 100    # Logical width
    height: 200   # Logical height
```

### 2. Consistent Logical Dimensions

Use the same logical dimensions across all scenes for consistency:
- Recommended: 1024x768 (4:3 aspect ratio)
- Alternative: 1920x1080 (16:9 aspect ratio)

### 3. Navigation Grid Generation

The navigation grid now uses logical dimensions:

```crystal
grid = NavigationGrid.from_scene(
  scene,
  scene.logical_width,   # Use logical dimensions
  scene.logical_height,  # Not texture dimensions!
  cell_size
)
```

### 4. Character Scaling

Character sizes should be defined relative to logical dimensions:

```yaml
player:
  scale: 2.0    # Scale relative to logical space
  position:
    x: 300      # Logical coordinates
    y: 500
```

## Migration Guide

### From Texture-Based to Logical Coordinates

If you have existing scenes using texture-based coordinates:

1. Add logical dimensions to your scene files:
   ```yaml
   logical_width: 1024
   logical_height: 768
   ```

2. Scale existing coordinates if needed:
   - If texture was 320x180 and coordinates matched
   - Scale factor: 1024/320 = 3.2
   - Multiply all coordinates by 3.2

3. Test navigation and walkable areas:
   - Run the game and verify characters can move properly
   - Check that hotspots trigger at expected positions

## Debugging

### Coordinate Validation

The engine includes validators to check coordinate consistency:

```
⚠️  Warnings:
   Scene 'library': Region 'main_floor' vertex 2 X coordinate (1200) outside logical width (0-1024)
```

### Visual Debugging

Enable debug rendering to see coordinate spaces:
- Green: Walkable areas in logical space
- Red: Non-walkable areas
- Yellow: Navigation paths

## Technical Details

### Rendering Pipeline

1. Game logic operates in logical coordinates
2. Sprites/textures are rendered with scaling to fit logical space
3. Camera system uses logical coordinates for bounds
4. Final output is scaled to fit screen resolution

### Code Example

```crystal
# Scene setup with logical dimensions
scene.logical_width = 1024
scene.logical_height = 768

# All positions use logical coordinates
character.position = Vector2.new(500, 400)

# Camera uses logical dimensions
camera.set_scene_size(scene.logical_width, scene.logical_height)

# Navigation grid generation
grid = NavigationGrid.from_scene(
  scene,
  scene.logical_width,
  scene.logical_height,
  16  # cell size in logical units
)
```

## Common Issues and Solutions

### Issue: Characters can't navigate after texture change
**Solution**: Ensure you're using logical dimensions for navigation grid generation, not texture dimensions.

### Issue: Hotspots don't align with visual elements
**Solution**: Verify hotspot coordinates are in logical space and match the visual layout when scaled.

### Issue: Different behavior across scenes
**Solution**: Ensure all scenes use the same logical dimensions for consistency.

## Summary

The texture-independent coordinate system provides:
- Consistent gameplay regardless of texture sizes
- Freedom for artists to change textures without breaking game logic
- Predictable behavior across different resolutions
- Easier debugging and maintenance

Always think in terms of logical coordinates when designing scenes and implementing game logic.