# Camera Manager Refactoring Plan

## Update: Current Status

### Completed:
- ✅ Extracted enums (CameraEffectType, CameraEasing) to camera_enums.cr
- ✅ Extracted CameraState struct to camera_state.cr  
- ✅ Extracted CameraEffect base class to camera_effect.cr
- ✅ Successfully extracted ShakeEffect (confirmed working by user)
- ✅ Successfully extracted ZoomEffect (user unsure if it worked before)
- ✅ Successfully extracted SwayEffect (confirmed working by user)
- ✅ Successfully extracted RotationEffect
- ✅ Successfully extracted PanEffect
- ✅ Successfully extracted FollowEffect

### Critical Lessons Learned:

#### 1. Crystal's Pass-by-Value Issue
**Problem**: In Crystal, primitive types and structs (like RL::Vector2) are passed by value, not by reference. When we tried to have effects modify a parameter directly:
```crystal
def apply_shake_to(effect_offset : RL::Vector2)
  effect_offset.x += offset_x  # This modifies a COPY, not the original!
end
```

**Solution**: Return values instead of trying to modify parameters:
```crystal
def calculate_shake_offset : RL::Vector2
  # Calculate and return the offset
  RL::Vector2.new(x: offset_x, y: offset_y)
end
```

#### 2. Effect Application Pattern
**Working Pattern**:
1. Effect classes inherit from CameraEffect
2. They store their specific parameters in the constructor
3. They provide calculation methods that return values
4. CameraManager calls these methods and applies the results

**Example**:
```crystal
# In effect class
def calculate_shake_offset : RL::Vector2
  # Return calculated offset
end

# In camera_manager
if effect.is_a?(ShakeEffect)
  shake_offset = effect.calculate_shake_offset
  @effect_offset.x += shake_offset.x
  @effect_offset.y += shake_offset.y
end
```

#### 3. Multiple Return Values
For effects that modify multiple properties (like sway affecting both position and rotation):
```crystal
def calculate_sway : Tuple(RL::Vector2, Float32)
  # Return both offset and rotation
  {offset, rotation}
end

# Usage
offset, rotation = effect.calculate_sway
@effect_offset.x += offset.x
@effect_offset.y += offset.y
@effect_rotation += rotation
```

#### 4. Effect State Management
- Effects maintain their own state (elapsed time, parameters)
- CameraManager maintains accumulator variables (@effect_offset, @effect_zoom, @effect_rotation)
- These accumulators are reset each frame before effects are applied
- Effects ADD to these accumulators, they don't replace them

#### 5. Backward Compatibility
Always maintain the inline fallback logic for backward compatibility:
```crystal
if effect.is_a?(SpecificEffect)
  # Use extracted effect
else
  # Use original inline logic
end
```

### All Effects Successfully Extracted!

All camera effects have been successfully extracted into separate files while maintaining backward compatibility through fallback logic in camera_manager.cr.

### Special Considerations for Position-Modifying Effects:
PanEffect and FollowEffect are different because they modify the camera's actual position, not just an offset. They were successfully extracted by:
- PanEffect: Returns the new camera position directly
- FollowEffect: Returns the position delta to apply, which camera_manager adds to current position

## Overview
This document outlines a detailed, foolproof plan to refactor the camera_manager.cr file by extracting camera effects into separate files while ensuring the system continues to work at every step.

## Current State Analysis

### File Structure
- `camera_manager.cr` contains:
  - Enums: `CameraEffectType`, `CameraEasing`
  - Classes: `CameraEffect`, `CameraManager`, `CameraError`
  - Struct: `CameraState`
  - All effect implementations inline in private methods

### How Effects Currently Work
1. `apply_effect` creates a `CameraEffect` instance with parameters
2. `CameraEffect` instances are stored in `@active_effects` array
3. `update` method:
   - Resets `@effect_offset`, `@effect_zoom`, `@effect_rotation` to default values
   - Calls `update_effects` which:
     - Updates each effect's elapsed time
     - Calls appropriate `apply_*_effect` method for each effect
   - Effects accumulate changes to `@effect_offset`, `@effect_zoom`, `@effect_rotation`
   - `apply_effects_to_camera` applies accumulated effects to camera

### Critical Implementation Details
- `@effect_offset` is reset to (0,0) every frame before effects are applied
- Effects modify `@effect_offset` by adding to it (+=)
- `transform_position` uses both camera position AND effect offset
- `apply_effects_to_camera` adds effect offset to base position

## Refactoring Strategy

### Phase 1: Extract Non-Dependent Components
These have no dependencies and can be safely extracted first.

#### Step 1.1: Extract Enums
- Create `src/core/camera_effects/camera_enums.cr`
- Move `CameraEffectType` and `CameraEasing` enums
- Update camera_manager.cr to require this file

#### Step 1.2: Extract CameraState
- Create `src/core/camera_effects/camera_state.cr`
- Move `CameraState` struct
- Update requires

#### Step 1.3: Test
- Run existing tests to ensure nothing broke
- Test shake effect manually

### Phase 2: Extract CameraEffect Base Class
This is trickier because CameraEffect is used throughout camera_manager.

#### Step 2.1: Create CameraEffect File
- Create `src/core/camera_effects/camera_effect.cr`
- Copy `CameraEffect` class exactly as-is
- Add requires for enums

#### Step 2.2: Update Requires
- Update camera_manager.cr to require camera_effect.cr
- Remove CameraEffect definition from camera_manager.cr

#### Step 2.3: Test
- Ensure compilation works
- Run tests

### Phase 3: Create Effect Infrastructure

#### Step 3.1: Create Effect Interface
Instead of inheritance, we'll use a clear interface pattern:

```crystal
module CameraEffects
  # Each effect will have this method signature
  # It receives the camera_manager's effect accumulator variables
  # and modifies them directly
  abstract class BaseEffect < CameraEffect
    abstract def apply_to(effect_offset : RL::Vector2, 
                         effect_zoom : Float32*, 
                         effect_rotation : Float32*) : Nil
  end
end
```

Wait, this won't work because Crystal doesn't allow modifying Float32 by reference.

#### Step 3.1 (Revised): Effect Application Pattern
Effects need to modify the camera manager's state. The current pattern is:
- Effect methods receive the effect instance
- They read parameters from the effect
- They modify `@effect_offset`, `@effect_zoom`, `@effect_rotation` directly

For extracted effects, we have several options:

**Option A: Return accumulated values**
```crystal
class ShakeEffect < CameraEffect
  def calculate_offset : RL::Vector2
    # return the offset to add
  end
end
```

**Option B: Pass accumulator object**
```crystal
struct EffectAccumulator
  property offset : RL::Vector2
  property zoom : Float32
  property rotation : Float32
end

class ShakeEffect < CameraEffect
  def apply_to(accumulator : EffectAccumulator)
    # modify accumulator
  end
end
```

**Option C: Keep effect logic in camera_manager but make it cleaner**
- Extract just the calculation logic
- Keep the accumulation in camera_manager

### Phase 4: Extract Individual Effects

#### Step 4.1: ShakeEffect First (Simplest)
1. Create `shake_effect.cr` with the exact logic from `apply_shake_effect`
2. Make it inherit from CameraEffect
3. Add a method that matches current pattern
4. Update camera_manager to detect and use ShakeEffect instances

**Critical Success Factors:**
- The effect must modify the SAME variables in the SAME way
- The math/logic must be IDENTICAL
- Only the location of the code changes

#### Step 4.2: Test Shake Thoroughly
- Visual test
- Unit tests
- Compare behavior with original

#### Step 4.3: Extract Other Effects One by One
- ZoomEffect
- PanEffect (careful - it modifies camera position directly)
- FollowEffect (also modifies camera position)
- SwayEffect
- RotationEffect

## Potential Pitfalls to Avoid

1. **Circular Dependencies**
   - Don't have effect files require camera_manager
   - Keep dependencies one-way

2. **Reference vs Value**
   - Crystal passes primitives by value
   - Need to ensure effects can modify shared state

3. **Type Compatibility**
   - `@active_effects` is `Array(CameraEffect)`
   - All effect classes must inherit from CameraEffect

4. **Effect Application Order**
   - Current system applies effects in array order
   - Must maintain this behavior

5. **State Reset Timing**
   - Effect accumulators are reset BEFORE effects apply
   - This timing is critical

## Implementation Order

1. **Extract enums** → Test
2. **Extract CameraState** → Test  
3. **Extract CameraEffect** → Test
4. **Create ShakeEffect that inherits from CameraEffect**
   - Keep the exact apply logic
   - Make camera_manager detect ShakeEffect type
   - Use the extracted apply method
5. **Test shake effect thoroughly**
6. **If successful, continue with other effects**

## Testing Strategy

After each step:
1. Compile the project
2. Run `crystal spec spec/core/camera_manager_spec.cr`
3. Run the camera effects demo
4. Test shake effect with spacebar

## Rollback Strategy

If anything breaks:
1. Git reset to last working state
2. Analyze what went wrong
3. Adjust approach
4. Try smaller steps

## Success Criteria

- All tests pass
- Shake effect works visually identical to original
- No performance degradation
- Code is more modular and maintainable