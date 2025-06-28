# Graphics Effects System

This directory contains the shader-based effects system for the Point & Click Engine.

## Directory Structure

```
effects/
├── effect.cr                    # Base Effect class
├── effect_manager.cr            # Manages and applies effects
├── shader_effect.cr             # Base class for GPU shader effects
├── shader_library.cr            # Reusable GLSL code library
├── effect_context.cr            # Context passed to effects
│
├── object_effects/              # Effects for individual objects
│   ├── shader/                  # GPU-based implementations
│   │   ├── color_shift_shader.cr
│   │   ├── dissolve_shader.cr
│   │   ├── float_shader.cr
│   │   ├── highlight_shader.cr
│   │   ├── pulse_shader.cr
│   │   └── shake_shader.cr
│   └── *.cr                     # CPU-based fallbacks
│
├── scene_effects/               # Effects for entire scenes
│   ├── shader/                  # GPU-based implementations
│   │   ├── fog_shader.cr
│   │   ├── rain_shader.cr
│   │   ├── darkness_shader.cr
│   │   └── underwater_shader.cr
│   ├── transition_effect.cr     # Scene transitions
│   └── base_scene_effect.cr     # Base class
│
├── post_processing/             # Screen-space effects
│   ├── blur_shader.cr           # Various blur algorithms
│   ├── distortion_shader.cr     # Heat haze, shock waves, etc.
│   └── glow_shader.cr           # Bloom and glow effects
│
└── camera_effects/              # Camera transformations (CPU-based)
    ├── movement_effects.cr      # Pan, zoom, follow
    └── base_camera_effect.cr    # Base class
```

## Usage

### Creating Effects

```crystal
# Object effect
glow = ObjectEffects.create("highlight", type: "glow", color: "yellow")

# Scene effect  
fog = SceneEffectFactory.create("fog", type: "linear", density: 0.02)

# Post-processing
blur = PostProcessing.create("gaussian_blur", radius: 5.0)
```

### Applying Effects

```crystal
# Create effect manager
manager = EffectManager.new

# Add to sprite
manager.add_effect(sprite, glow)

# Add to scene
manager.add_scene_effect("main_layer", fog)

# Update and apply
manager.update(dt)
manager.apply_effects(sprite, context)
```

## Shader System

All GPU effects inherit from `ShaderEffect` and use GLSL shaders. The `ShaderLibrary` provides common functions for noise, easing, color manipulation, and shape generation.

### Performance

- Shaders compiled once at initialization
- Uniform locations cached
- Multiple quality levels available
- Automatic fallback to CPU versions if shaders fail

## Creating Custom Effects

1. Inherit from `ShaderEffect` for GPU effects
2. Implement `vertex_shader_source` and `fragment_shader_source`
3. Override `apply()` to set uniforms
4. Add to appropriate factory

See existing effects for examples.