# Graphics Module

The Point & Click Engine v2.0 graphics module provides a comprehensive, modular system for 2D rendering with special effects, designed specifically for retro point & click adventure games.

## Overview

The graphics module features:
- **Layer-based rendering** with z-ordering and parallax
- **Advanced sprite system** with animation and effects
- **Comprehensive effects** for objects, scenes, and cameras
- **Particle system** with presets
- **UI rendering components** with nine-patch support
- **Shader post-processing** with retro effects
- **Utility functions** for colors, fonts, palettes, and screenshots

## Quick Start

```crystal
require "graphics/graphics"

# Initialize display and renderer
display = Graphics::Display.new(1280, 720)
renderer = Graphics::Renderer.new(display)

# Create layer manager
layers = Graphics::LayerManager.new
layers.add_default_layers

# Create and position a sprite
sprite = Graphics::Sprite.new("hero.png")
sprite.position = RL::Vector2.new(x: 100, y: 200)

# Add effects
sprite.add_effect("glow", color: [255, 255, 0])
sprite.add_effect("float", amplitude: 10)

# Create post-processor for retro effects
post_processor = Graphics::Shaders::PostProcessor.new(1280, 720)
Graphics::Shaders::PostProcessPresets.crt(post_processor)

# Render loop
post_processor.begin_capture
renderer.render do |context|
  layers.render(camera, renderer) do |layer|
    sprite.draw_with_context(context)
  end
end
post_processor.end_capture
post_processor.render(delta_time)
```

## Module Structure

```
graphics/
├── core/               # Core rendering infrastructure
│   ├── display.cr      # Window and resolution management
│   ├── renderer.cr     # Main rendering pipeline
│   ├── camera.cr       # 2D camera system
│   └── viewport.cr     # Multiple viewport support
├── sprites/            # Sprite rendering
│   ├── sprite.cr       # Base sprite with effects
│   └── animated_sprite.cr  # Frame-based animation
├── effects/            # Visual effects system
│   ├── object_effects/ # Effects for game objects
│   ├── scene_effects/  # Full-scene effects
│   └── camera_effects/ # Camera movement effects
├── layers/             # Layer management
│   ├── layer.cr        # Base layer class
│   └── layer_manager.cr # Z-ordered layer system
├── particles/          # Particle system
│   ├── particle.cr     # Individual particles
│   └── emitter.cr      # Particle emitters
├── ui/                 # UI rendering
│   ├── nine_patch.cr   # Scalable borders
│   ├── text_renderer.cr # Advanced text rendering
│   └── dialog_renderer.cr # Dialog boxes
├── shaders/            # Post-processing
│   ├── post_processor.cr # Effect pipeline
│   └── retro/          # Retro shader effects
└── utils/              # Utility functions
    ├── color.cr        # Color manipulation
    ├── bitmap_font.cr  # Bitmap font loading
    ├── palette.cr      # Palette management
    └── screenshot.cr   # Screenshot capture
```

## Key Features

### Layer System
- Background, scene, foreground, and UI layers
- Parallax scrolling support
- Per-layer opacity and tinting
- Automatic depth sorting

### Effects System
- **Object Effects**: Highlight, dissolve, shake, pulse, color shift, float
- **Scene Effects**: Fog, rain, darkness, underwater
- **Camera Effects**: Follow, pan, zoom, sway
- **Transitions**: Integration with existing shader transitions
- Effect stacking and combining

### Particle System
- Configurable emitters with shape support
- Preset effects (fire, smoke, rain, snow, etc.)
- Particle pooling for performance
- Texture support

### UI Components
- Nine-patch rendering for scalable UI
- Advanced text with effects (wave, shake, gradient)
- Dialog boxes with typewriter effect
- Grid-based inventory display

### Post-Processing
- CRT monitor effect
- LCD/Game Boy effect
- VHS distortion
- Pixelation
- Film grain
- Chromatic aberration
- Custom effect chains

## Examples

See the `examples/` directory for demonstrations:
- `graphics_showcase.cr` - General features
- `scene_effects_demo.cr` - Atmospheric effects
- `camera_effects_demo.cr` - Camera movements
- `particle_effects_demo.cr` - Particle system
- `ui_rendering_demo.cr` - UI components
- `utilities_demo.cr` - Color, fonts, palettes
- `shader_effects_demo.cr` - Post-processing

## Integration

To integrate with the main engine:

1. Update GameObject to use the new sprite system
2. Replace Scene rendering with layer-based approach
3. Load effects from YAML configuration
4. Use post-processor for retro visual style

## Performance

- Automatic culling in RenderContext
- Particle pooling to reduce allocations
- Efficient layer rendering
- Shader caching in ShaderManager

## Future Enhancements

- Sprite batching for better performance
- Texture atlasing support
- Visual effect editor
- More shader effects
- Advanced text layout