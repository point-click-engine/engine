# Camera Manager Refactoring Plan

## Final Status: COMPLETED ✅

### Summary of Changes:
The camera system has been successfully refactored with improved naming conventions and better module organization.

### Module Structure:
```
src/graphics/
├── camera.cr                    # Basic Camera class (Graphics::Camera)
└── cameras/                     # Cameras module
    ├── camera_manager.cr        # CameraManager (Graphics::Cameras::CameraManager)
    ├── state.cr                 # State struct for saving/restoring camera state
    └── effects/                 # Camera effects module
        ├── effect.cr            # Base Effect class
        ├── enums.cr             # EffectType and Easing enums
        ├── shake.cr             # Shake effect
        ├── zoom.cr              # Zoom effect
        ├── sway.cr              # Sway effect
        ├── rotation.cr          # Rotation effect
        ├── pan.cr               # Pan effect
        └── follow.cr            # Follow effect
```

### Naming Changes:
- `CameraEffect` → `Effect`
- `CameraEffectType` → `Type` (enum in Effects module)
- `CameraEasing` → `Easing`
- `CameraState` → `State`
- `ShakeEffect` → `Shake`
- `ZoomEffect` → `Zoom`
- `SwayEffect` → `Sway`
- `RotationEffect` → `Rotation`
- `PanEffect` → `Pan`
- `FollowEffect` → `Follow`

### Module Namespaces:
- Camera: `Graphics::Camera`
- CameraManager: `Graphics::Cameras::CameraManager`
- Effects: `Graphics::Cameras::Effects::Effect`, `Graphics::Cameras::Effects::Shake`, etc.
- Enums: `Graphics::Cameras::Effects::Type`, `Graphics::Cameras::Effects::Easing`
- State: `Graphics::Cameras::State`

### Available Aliases:
The following aliases are available in `PointClickEngine` module for convenience:
```crystal
# Camera aliases
alias CameraManager = Graphics::Cameras::CameraManager
alias CameraEffect = Graphics::Cameras::Effects::Effect
alias CameraEffectType = Graphics::Cameras::Effects::Type
alias CameraEasing = Graphics::Cameras::Effects::Easing
alias CameraState = Graphics::Cameras::State

# Camera effect aliases
alias ShakeEffect = Graphics::Cameras::Effects::Shake
alias ZoomEffect = Graphics::Cameras::Effects::Zoom
alias SwayEffect = Graphics::Cameras::Effects::Sway
alias RotationEffect = Graphics::Cameras::Effects::Rotation
alias PanEffect = Graphics::Cameras::Effects::Pan
alias FollowEffect = Graphics::Cameras::Effects::Follow
```

### Usage Examples:

#### Using Full Namespaces:
```crystal
# Create camera manager
manager = PointClickEngine::Graphics::Cameras::CameraManager.new(800, 600)

# Apply effects
manager.apply_effect(:shake, intensity: 10.0f32, duration: 1.0f32)
manager.apply_effect(:zoom, target: 2.0f32, duration: 2.0f32)

# Check effect type
effect.type == PointClickEngine::Graphics::Cameras::Effects::Type::Shake
```

#### Using Aliases:
```crystal
# Include the module for easier access
include PointClickEngine

# Create camera manager
manager = CameraManager.new(800, 600)

# Apply effects (same as above)
manager.apply_effect(:shake, intensity: 10.0f32, duration: 1.0f32)

# Check effect type using alias
effect.type == CameraEffectType::Shake
```

### Critical Lessons Learned (Preserved from Original):

#### 1. Crystal's Pass-by-Value Issue
**Problem**: In Crystal, primitive types and structs (like RL::Vector2) are passed by value, not by reference.

**Solution**: Return values instead of trying to modify parameters:
```crystal
def calculate_shake_offset : RL::Vector2
  # Calculate and return the offset
  RL::Vector2.new(x: offset_x, y: offset_y)
end
```

#### 2. Effect Application Pattern
**Working Pattern**:
1. Effect classes inherit from Effect (formerly CameraEffect)
2. They store their specific parameters in the constructor
3. They provide calculation methods that return values
4. CameraManager calls these methods and applies the results

#### 3. Multiple Return Values
For effects that modify multiple properties:
```crystal
def calculate_sway : Tuple(RL::Vector2, Float32)
  # Return both offset and rotation
  {offset, rotation}
end
```

#### 4. Effect State Management
- Effects maintain their own state (elapsed time, parameters)
- CameraManager maintains accumulator variables
- Accumulators are reset each frame before effects are applied
- Effects ADD to these accumulators

### Migration Guide:

If you have existing code using the old names, update as follows:
- `CameraEffect` → `Effect` (or use `CameraEffect` alias)
- `CameraEffectType::Shake` → `Type::Shake` (or use `CameraEffectType` alias)
- `CameraEasing::Linear` → `Easing::Linear` (or use `CameraEasing` alias)
- `CameraState` → `State` (or use `CameraState` alias)

The aliases maintain backward compatibility, so existing code using the aliases will continue to work.