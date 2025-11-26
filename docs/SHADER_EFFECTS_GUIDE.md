# Shader Effects System Guide

## Overview

The Point & Click Engine now features a comprehensive shader-based effects system that leverages GPU processing for high-performance visual effects. All effects that benefit from parallel processing have been migrated to GLSL shaders, while simpler transformations remain CPU-based for efficiency.

## Architecture

### Effect Hierarchy

```
Effect (base class)
├── ShaderEffect (GPU-based effects)
│   ├── Object Effects (applied to sprites/objects)
│   ├── Scene Effects (applied to entire scenes)
│   └── Post-Processing Effects (screen-space effects)
└── CPU Effects (simple transformations)
    └── Camera Effects (position/rotation transforms)
```

### Key Components

1. **ShaderEffect Base Class** (`src/graphics/effects/shader_effect.cr`)
   - Handles shader loading and compilation
   - Manages common uniforms (time, progress, resolution)
   - Provides helper methods for setting shader values

2. **ShaderLibrary** (`src/graphics/effects/shader_library.cr`)
   - Reusable GLSL code snippets
   - Noise functions, easing curves, color utilities
   - Shape and distortion functions

3. **Effect Factories**
   - `ObjectEffects.create()` - Creates object-level effects
   - `SceneEffectFactory.create()` - Creates scene-wide effects
   - `PostProcessing.create()` - Creates post-processing effects

## Object Effects

Effects applied to individual sprites and game objects:

### ColorShiftShader
```crystal
# Tint effect
effect = ObjectEffects.create("tint", color: "blue", duration: 2.0)

# Rainbow effect
effect = ObjectEffects.create("rainbow", speed: 2.0)

# Grayscale effect
effect = ObjectEffects.create("color", mode: "grayscale", intensity: 0.8)

# Flash effect
effect = ObjectEffects.create("flash", color: "white", duration: 0.5)
```

### DissolveShader
```crystal
# Dissolve out with orange edge
effect = ObjectEffects.create("dissolve", 
  mode: "out", 
  duration: 2.0, 
  edge_color: "orange",
  edge_thickness: 0.05
)

# Dissolve in
effect = ObjectEffects.create("dissolve", mode: "in", duration: 1.5)
```

### FloatShader
```crystal
# Simple float
effect = ObjectEffects.create("float", amplitude: 20.0, speed: 1.0)

# Float with sway
effect = ObjectEffects.create("float", 
  amplitude: 15.0, 
  sway: true, 
  sway_amplitude: 10.0
)

# Orbit motion
effect = ObjectEffects.create("float", orbit: true, amplitude: 30.0)
```

### HighlightShader
```crystal
# Glow effect
effect = ObjectEffects.create("highlight", 
  type: "glow", 
  color: "yellow", 
  intensity: 2.0
)

# Outline effect
effect = ObjectEffects.create("highlight", 
  type: "outline", 
  color: "red", 
  thickness: 3.0
)

# Rim lighting
effect = ObjectEffects.create("highlight", type: "rim", color: "white")
```

### PulseShader
```crystal
# Breathe animation
effect = ObjectEffects.create("pulse", scale_amount: 0.2, speed: 1.0)

# Heartbeat pattern
effect = ObjectEffects.create("pulse", 
  mode: "heartbeat", 
  scale_amount: 0.15,
  glow: true
)
```

### ShakeShader
```crystal
# Basic shake
effect = ObjectEffects.create("shake", 
  amplitude: 10.0, 
  frequency: 15.0, 
  duration: 0.5
)

# Directional shake with chromatic aberration
effect = ObjectEffects.create("shake", 
  amplitude: 5.0, 
  direction: "horizontal", 
  chromatic: 0.005
)
```

## Scene Effects

Effects applied to entire scenes or layers:

### FogShader
```crystal
# Linear fog
effect = SceneEffectFactory.create("fog", 
  type: "linear",
  color: [128, 128, 150, 200],
  density: 0.02,
  start: 100.0,
  end: 500.0
)

# Volumetric fog
effect = SceneEffectFactory.create("fog", type: "volumetric")
```

### RainShader
```crystal
# Storm with heavy rain
effect = SceneEffectFactory.create("rain", 
  intensity: "storm",
  wind: 0.5,
  splashes: true,
  color: [200, 200, 255, 100]
)
```

### DarknessShader

Supports four darkness modes:

```crystal
# Vignette - darkens edges, light in center
effect = SceneEffectFactory.create("darkness",
  type: "vignette",
  intensity: 0.8,
  inner_radius: 0.5,
  outer_radius: 1.2
)

# Gradient - directional darkness
effect = SceneEffectFactory.create("darkness",
  type: "gradient",
  intensity: 0.7,
  gradient_angle: 45.0  # Angle in degrees
)

# Spotlight - circular light area
effect = SceneEffectFactory.create("darkness",
  type: "spotlight",
  intensity: 0.9,
  inner_radius: 0.3,
  outer_radius: 0.6
)

# Multi-light system - up to 8 dynamic light sources
darkness = SceneEffectFactory.create("darkness", type: "multilight")
darkness.add_light(Vector2.new(100, 100), 150.0, 1.0, YELLOW)
darkness.add_light(Vector2.new(500, 300), 200.0, 0.8, WHITE)
```

### UnderwaterShader
```crystal
# High quality underwater
effect = SceneEffectFactory.create("underwater", 
  quality: "high",
  color: [0, 80, 120, 100],
  wave_amplitude: 0.02,
  wave_frequency: 15.0
)
```

### TransitionEffect
```crystal
# Swirl transition
effect = SceneEffectFactory.create("transition", 
  type: "swirl",
  duration: 1.5
)

# Heart wipe
effect = SceneEffectFactory.create("transition", 
  type: "heart_wipe",
  duration: 2.0
)
```

## Post-Processing Effects

Advanced screen-space effects:

### BlurShader
```crystal
# Gaussian blur
effect = PostProcessing.create("gaussian_blur", 
  radius: 5.0,
  quality: 4
)

# Motion blur
effect = PostProcessing.create("motion_blur", 
  angle: 0.785,  # 45 degrees
  strength: 0.03
)

# Radial zoom blur
effect = PostProcessing.create("radial_blur", 
  center: [640, 360],
  zoom: true
)
```

### DistortionShader
```crystal
# Heat haze
effect = PostProcessing.create("heat_haze", 
  strength: 0.02,
  frequency: 8.0,
  layers: 3
)

# Shock wave
effect = PostProcessing.create("shock_wave", 
  center: [640, 360],
  radius: 0.5,
  force: 0.1
)

# Lens distortion
effect = PostProcessing.create("lens_distortion", 
  k1: 0.2,  # Barrel distortion
  k2: 0.0
)
```

### GlowShader
```crystal
# Simple bloom
effect = PostProcessing.create("glow", 
  threshold: 0.7,
  intensity: 2.0,
  tint: "yellow"
)

# Selective glow by color
effect = PostProcessing.create("selective_glow", 
  select_color: "red",
  tolerance: 0.1
)

# Lens flare style
effect = PostProcessing.create("lens_flare", 
  threshold: 0.9,
  dispersion: 0.3
)
```

## Usage Example

```crystal
# Create effect manager
effect_manager = Graphics::Effects::EffectManager.new

# Add effects to a sprite
sprite = Graphics::Sprites::Sprite.new
glow = ObjectEffects.create("highlight", type: "glow", color: "yellow")
effect_manager.add_effect(sprite, glow)

# Add scene effect
fog = SceneEffectFactory.create("fog", type: "linear", density: 0.02)
effect_manager.add_scene_effect("main_layer", fog)

# Update effects
effect_manager.update(delta_time)

# Apply effects during rendering
context = EffectContext.new(TargetType::Sprite, renderer, delta_time)
effect_manager.apply_effects(sprite, context)
```

## GPU Context and Graceful Fallbacks

The shader effects system includes robust handling for environments without GPU access:

### Context Checking

```crystal
# Check if GPU/OpenGL context is available
if ShaderEffect.gl_context_available?
  # Safe to create shader effects
  effect = ObjectEffects.create("highlight", type: "glow")
else
  # Will automatically fall back to CPU effects
end

# Factory-level availability checks
ShaderObjectFactory.available?        # Object shader effects
PostProcessingFactory.available?      # Post-processing effects
ShaderSceneEffectFactory.available?   # Scene shader effects
```

### Automatic Fallback Behavior

When no GPU context is available:

1. **Object Effects**: `ObjectEffects.create()` returns CPU-based effects instead of shader effects
2. **Scene Effects**: Shader effects return `nil`, non-shader effects (shake, flash) still work
3. **Post-Processing**: Returns `nil` (no CPU fallback for screen-space effects)

```crystal
# This works in both GPU and headless environments
effect = ObjectEffects.create("highlight", type: "glow", color: "yellow")
# With GPU: Returns HighlightShader (GPU-accelerated)
# Without GPU: Returns HighlightEffect (CPU-based)

# Check if shader acceleration is active
if effect.is_a?(ShaderEffect) && effect.shader_available
  puts "Using GPU-accelerated effect"
else
  puts "Using CPU fallback"
end
```

### Shader Availability Property

All shader effects expose a `shader_available` property:

```crystal
effect = PostProcessing.create("blur", radius: 5.0)
if effect && effect.shader_available
  # Shader compiled successfully
else
  # Shader failed to load or no GPU context
end
```

### Testing Without GPU

For headless testing environments (CI/CD):

```crystal
# Reset context check (useful in tests)
ShaderEffect.reset_context_check

# Run GPU-dependent tests with flag
# crystal spec -D with_graphics_tests
```

## Performance Considerations

1. **Shader Compilation**: Shaders are compiled at initialization only if GPU context is available
2. **Uniform Caching**: Uniform locations are cached to avoid lookups
3. **Render Textures**: Effects requiring multiple passes use render textures (created lazily)
4. **Quality Settings**: Many effects support quality levels (low/medium/high)
5. **Dynamic Texture Sizing**: HighlightShader creates render textures sized to sprite bounds

## Creating Custom Shaders

To create a new shader effect:

```crystal
class MyCustomShader < ShaderEffect
  def vertex_shader_source : String
    # Return GLSL vertex shader code
    default_vertex_shader  # Use default for 2D
  end
  
  def fragment_shader_source : String
    <<-SHADER
    #version 330 core
    in vec2 fragTexCoord;
    in vec4 fragColor;
    out vec4 finalColor;
    
    uniform sampler2D texture0;
    uniform float time;
    uniform float myParam;
    
    void main() {
        vec4 color = texture(texture0, fragTexCoord);
        // Your effect logic here
        finalColor = color;
    }
    SHADER
  end
  
  def apply(context : EffectContext)
    return unless shader = @shader
    
    update_common_uniforms(shader)
    set_shader_value("myParam", @my_param)
    
    context.active_shader = shader
  end
end
```

## Shader Library Functions

The ShaderLibrary provides reusable GLSL functions:

- **Noise Functions**: `rand()`, `noise()`, `fbm()`
- **Easing Functions**: `easeInOut()`, `smoothstep()`
- **Color Functions**: `rgbToHsv()`, `hsvToRgb()`, `getLuminance()`
- **Shape Functions**: `sdCircle()`, `sdBox()`, `sdHeart()`, `sdStar()`
- **Distortion Functions**: `wave()`, `ripple()`, `swirl()`

## Debugging

1. Check shader compilation errors in console output
2. Use `shader_effects_test.cr` example to test effects
3. Verify OpenGL version compatibility (requires 3.3+)
4. Monitor GPU performance with external tools

## Migration Notes

- All object effects now prefer shader implementations
- Scene effects are fully shader-based
- Camera effects remain CPU-based (no visual benefit from shaders)
- Legacy CPU effects still available as fallbacks
- Effect parameters remain consistent with old system