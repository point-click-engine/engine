# Camera System Documentation

The Point & Click Engine provides a comprehensive camera system that handles viewport management, visual effects, and smooth transitions. The system consists of two main components: the basic `Camera` class for simple viewport management and the advanced `CameraManager` for complex camera behaviors and effects.

## Table of Contents
1. [Overview](#overview)
2. [Basic Camera](#basic-camera)
3. [Camera Manager](#camera-manager)
4. [Camera Effects](#camera-effects)
5. [Usage Examples](#usage-examples)
6. [Best Practices](#best-practices)

## Overview

The camera system provides:
- Multiple named cameras with smooth switching
- Visual effects (shake, zoom, pan, follow, sway)
- Scene boundary constraints
- Coordinate transformation (world ↔ screen)
- State persistence
- Effect stacking and composition

## Basic Camera

The `Graphics::Camera` class provides basic viewport functionality:

```crystal
# Create a camera
camera = Graphics::Camera.new(viewport_width, viewport_height)

# Set scene bounds
camera.set_scene_size(scene_width, scene_height)

# Follow a character
camera.follow(player)

# Convert coordinates
world_pos = camera.screen_to_world(mouse_x, mouse_y)
screen_pos = camera.world_to_screen(object_x, object_y)

# Check visibility
if camera.is_visible?(object_x, object_y, margin: 50.0f32)
  # Object is visible on screen
end
```

### Properties
- `position`: Current camera position (top-left corner)
- `viewport_width/height`: Size of the viewport
- `scene_width/height`: Total scene dimensions
- `zoom`: Zoom level (1.0 = normal)
- `rotation`: Camera rotation in radians
- `edge_scroll_enabled`: Enable mouse edge scrolling
- `follow_speed`: Speed of character following

## Camera Manager

The `Core::CameraManager` provides advanced camera functionality:

```crystal
# Access through engine
camera_manager = engine.camera_manager

# Add custom cameras
cutscene_camera = Graphics::Camera.new(800, 600)
camera_manager.add_camera("cutscene", cutscene_camera)

# Switch cameras with transition
camera_manager.switch_camera("cutscene", 
  transition_duration: 2.0f32,
  easing: CameraEasing::EaseInOut
)

# Apply effects
camera_manager.apply_effect(:shake, intensity: 10.0f32, duration: 1.0f32)
```

### Multiple Cameras

The CameraManager supports multiple named cameras:

```crystal
# Add cameras for different purposes
camera_manager.add_camera("gameplay", gameplay_camera)
camera_manager.add_camera("cutscene", cutscene_camera)
camera_manager.add_camera("menu", menu_camera)

# Switch between them
camera_manager.switch_camera("cutscene", transition_duration: 1.5f32)
```

## Camera Effects

### Shake Effect

Creates earthquake-like screen shake:

```crystal
camera_manager.apply_effect(:shake,
  intensity: 20.0f32,    # Shake amplitude in pixels
  duration: 2.0f32,      # Effect duration
  frequency: 15.0f32     # Shake frequency
)
```

### Zoom Effect

Smooth zoom in/out:

```crystal
# Zoom in 2x
camera_manager.apply_effect(:zoom,
  target: 2.0f32,        # Target zoom level
  duration: 1.5f32       # Transition duration
)

# Zoom out
camera_manager.apply_effect(:zoom,
  target: 0.5f32,
  duration: 1.0f32
)
```

### Pan Effect

Smooth camera movement to a target position:

```crystal
camera_manager.apply_effect(:pan,
  target_x: 800.0f32,    # Target X position
  target_y: 600.0f32,    # Target Y position
  duration: 2.0f32       # Movement duration
)
```

### Follow Effect

Follow a character with smooth movement:

```crystal
camera_manager.apply_effect(:follow,
  target: player,         # Character to follow
  smooth: true,          # Use smooth following
  deadzone: 50.0f32,     # Movement deadzone
  speed: 5.0f32          # Follow speed
)
```

### Sway Effect

Creates a sea-like swaying motion (perfect for boat scenes):

```crystal
camera_manager.apply_effect(:sway,
  amplitude: 15.0f32,          # Sway amplitude
  frequency: 0.3f32,           # Sway frequency
  duration: 5.0f32,            # Effect duration
  vertical_factor: 0.4f32,     # Vertical movement factor
  rotation_amplitude: 2.0f32   # Optional rotation
)
```

### Rotation Effect

Rotate the camera view:

```crystal
camera_manager.apply_effect(:rotation,
  target: 0.1f32,        # Target rotation in radians
  duration: 1.0f32       # Rotation duration
)
```

## Usage Examples

### Example 1: Earthquake Scene

```crystal
# Player triggers earthquake
def trigger_earthquake
  # Apply strong shake
  camera_manager.apply_effect(:shake,
    intensity: 30.0f32,
    duration: 3.0f32,
    frequency: 20.0f32
  )
  
  # Play rumble sound
  audio_manager.play_sound("earthquake_rumble")
end
```

### Example 2: Dramatic Zoom

```crystal
# Zoom in on important object
def focus_on_clue(clue_position : RL::Vector2)
  # Pan to clue
  camera_manager.apply_effect(:pan,
    target_x: clue_position.x - viewport_width / 2,
    target_y: clue_position.y - viewport_height / 2,
    duration: 1.5f32
  )
  
  # Then zoom in
  camera_manager.apply_effect(:zoom,
    target: 3.0f32,
    duration: 1.0f32
  )
end
```

### Example 3: Boat Scene

```crystal
# Create boat swaying effect
def enter_boat_scene
  # Apply continuous sway
  camera_manager.apply_effect(:sway,
    amplitude: 20.0f32,
    frequency: 0.2f32,
    duration: 0.0f32,  # Infinite duration
    vertical_factor: 0.5f32,
    rotation_amplitude: 3.0f32
  )
  
  # Follow player on boat
  camera_manager.apply_effect(:follow,
    target: player,
    smooth: true,
    deadzone: 100.0f32  # Larger deadzone for boat
  )
end
```

### Example 4: Cutscene Camera Control

```crystal
class DramaticCutscene < Cutscene
  def play
    # Save current camera state
    @saved_state = camera_manager.save_state
    
    # Switch to cutscene camera
    camera_manager.switch_camera("cutscene", transition_duration: 1.0f32)
    
    # Pan across scene
    camera_manager.apply_effect(:pan,
      target_x: 0.0f32,
      target_y: 0.0f32,
      duration: 5.0f32
    )
    
    # ... cutscene actions ...
    
    # Restore original camera
    on_complete do
      camera_manager.restore_state(@saved_state)
    end
  end
end
```

## Best Practices

### 1. Effect Management

```crystal
# Check for active effects before applying new ones
if !camera_manager.has_effect?(:shake)
  camera_manager.apply_effect(:shake, intensity: 10.0f32, duration: 1.0f32)
end

# Remove specific effects when needed
camera_manager.remove_effect(:follow)

# Clear all effects for clean state
camera_manager.remove_all_effects
```

### 2. Scene Transitions

```crystal
# Update camera bounds when changing scenes
def change_scene(scene_name : String)
  super(scene_name)
  
  # Update camera bounds to match new scene
  if scene = current_scene
    scene_width = scene.background.width
    scene_height = scene.background.height
    camera_manager.set_scene_bounds(scene_width, scene_height)
  end
end
```

### 3. Coordinate Conversion

```crystal
# Always use camera manager for coordinate conversion
def handle_click(mouse_pos : RL::Vector2)
  # Convert screen to world coordinates
  world_pos = camera_manager.screen_to_world(mouse_pos)
  
  # Check if position is visible
  if camera_manager.is_visible?(world_pos)
    # Process click
  end
end
```

### 4. Performance Considerations

- Limit the number of simultaneous shake effects
- Use appropriate durations for effects
- Remove effects when no longer needed
- Consider disabling effects on low-end systems

### 5. Save/Restore Camera State

```crystal
# Save state before cutscene
saved_state = camera_manager.save_state

# Do cutscene with camera changes
play_cutscene

# Restore original state
camera_manager.restore_state(saved_state)
```

## Integration with Engine

The CameraManager is automatically initialized by the Engine and can be accessed via:

```crystal
engine.camera_manager
```

The camera bounds are automatically updated when scenes change, and the camera manager integrates with the render system to apply all transformations during rendering.

## Troubleshooting

### Effects Not Visible
- Ensure the effect duration is greater than 0 (unless infinite)
- Check that the camera manager is being updated each frame
- Verify the effect parameters are reasonable for your viewport size

### Camera Stuck at Bounds
- Check scene bounds are set correctly
- Ensure the scene size is larger than the viewport
- Verify position constraints in custom camera implementations

### Coordinate Conversion Issues
- Always use the camera manager's transform methods
- Account for zoom when converting coordinates
- Consider camera effects when checking visibility