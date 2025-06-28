# Graphics Module Architecture

## Overview

The Point & Click Engine graphics module provides a comprehensive 2D rendering system designed specifically for retro adventure games. It features a modular effect system, layer-based rendering, and extensive support for classic adventure game visual effects.

## Core Architecture Principles

### 1. **Separation of Concerns**
- **Camera**: Manages world position and view transformation
- **Viewport**: Defines screen rendering region (usually fullscreen)
- **Effects**: Modular system applicable to objects, scenes, or cameras
- **Layers**: Z-ordered rendering with parallax support
- **Sprites**: Animated and static sprite rendering
- **UI**: Specialized rendering for interface elements

### 2. **Effect-Centric Design**
All visual enhancements are implemented as effects that can be:
- Applied to individual game objects (pulse, glow, dissolve)
- Applied to entire scenes (rain, fog, darkness)
- Applied to the camera/viewport (shake, zoom, transitions)
- Composed together for complex visual results

### 3. **Performance Considerations**
- Effect pooling to minimize allocations
- Sprite batching for efficient rendering
- Culling of off-screen objects
- Shader caching and reuse
- Layer-based rendering to minimize state changes

## Module Structure

```
graphics/
├── core/               # Foundation classes
├── sprites/            # Sprite rendering system
├── effects/            # Unified effects system
├── layers/             # Layer management
├── shaders/            # Shader effects
├── ui/                 # UI-specific rendering
└── utils/              # Graphics utilities
```

## Core Components

### Display Manager (`core/display.cr`)
Manages the game window and resolution scaling:
- Supports multiple scaling modes (fit, stretch, pixel-perfect)
- Handles letterboxing for aspect ratio preservation
- Manages fullscreen transitions
- Provides coordinate system transformations

### Renderer (`core/renderer.cr`)
The main rendering pipeline:
- Coordinates all rendering operations
- Manages render state
- Handles layer composition
- Integrates post-processing effects

### Camera (`core/camera.cr`)
2D world camera with:
- Position and bounds management
- World-to-screen coordinate transformation
- Scene boundary constraints
- Integration with camera effects

### Render Context (`core/render_context.cr`)
Drawing interface that:
- Provides camera-aware drawing methods
- Handles coordinate transformations automatically
- Supports both world and screen space rendering
- Manages current effect state

## Effects System

### Effect Types

#### Object Effects (`effects/object_effects/`)
Effects that apply to individual game objects:
- **Highlight**: Interactive object highlighting
- **Dissolve**: Fade in/out with particle effects
- **Shake**: Object vibration/trembling
- **Pulse**: Breathing/pulsing animation
- **Color Shift**: Tint, grayscale, color cycling
- **Float**: Gentle floating motion

#### Scene Effects (`effects/scene_effects/`)
Effects that apply to entire scenes:

**Transitions** (`transitions/`):
- Fade, Iris, Slide, Dissolve, Curtain
- Shader-based implementation
- Customizable timing and parameters

**Ambience** (`ambience/`):
- Rain, Fog, Darkness, Underwater, Heat Haze
- Layered rendering for depth
- Performance-optimized particle systems

**Camera Effects** (`camera_effects/`):
- Screen shake, smooth follow, pan, zoom, sway
- Stackable and combinable
- Smooth interpolation

#### Particle Effects (`effects/particles/`)
Lightweight particle system for:
- Sparkles, smoke, bubbles, dust
- Fire, magic effects
- Weather effects

### Effect Application

Effects can be applied at multiple levels:
```crystal
# Object level
item.add_effect(:glow, color: Color::YELLOW, intensity: 0.5)

# Scene level
scene.add_ambient_effect(:rain, intensity: 0.8)

# Camera level
camera.add_effect(:shake, intensity: 10.0, duration: 1.0)

# Global level (post-processing)
renderer.add_post_process(:crt_scanlines)
```

## Layer System

### Layer Types

1. **Background Layer**: Parallax scrolling backgrounds
2. **Scene Layer**: Main game objects and characters
3. **Foreground Layer**: Objects in front of characters
4. **UI Layer**: Interface elements (always on top)

### Layer Features
- Independent scrolling speeds (parallax)
- Per-layer effects and filters
- Dynamic layer switching for objects
- Efficient culling per layer

## Sprite System

### Enhanced Sprite Features
- Effect component integration
- Rotation and scaling with pivot point
- Color tinting and blend modes
- Sprite batching for performance
- Nine-patch support for UI elements

### Animation System
- YAML-defined animations
- State-based animation controller
- Animation blending
- Event triggers on specific frames

## Shader System

### Built-in Shaders
- **Retro Effects**: CRT, scanlines, pixelation
- **Color Effects**: Sepia, grayscale, palette swap
- **Distortion**: Wave, heat shimmer, underwater
- **Post-processing**: Bloom, vignette, chromatic aberration

### Shader Management
- Automatic compilation and caching
- Hot-reload in development
- Parameter animation support
- Fallback for unsupported hardware

## UI Rendering

### Specialized UI Components
- **Dialog Renderer**: Speech bubbles and dialog boxes
- **Inventory Renderer**: Grid-based item display
- **Text Renderer**: Bitmap font rendering with effects
- **Nine-patch**: Scalable UI borders and panels

## Integration Points

### With Game Objects
```crystal
class GameObject
  property effect_component : EffectComponent?
  property layer : Layer = Layer::Scene
  property sprite : Sprite?
end
```

### With Scenes
```crystal
class Scene
  property layers : LayerManager
  property ambient_effects : Array(SceneEffect)
  property camera : Camera
end
```

### With Engine Core
- Integrates with `RenderManager` for draw order
- Uses `AssetLoader` for texture management
- Coordinates with `InputManager` for hover effects
- Syncs with `AudioManager` for audio-reactive effects

## Performance Optimizations

1. **Effect Pooling**: Reuse effect instances
2. **Sprite Batching**: Minimize draw calls
3. **Texture Atlasing**: Reduce texture switches
4. **Culling**: Skip off-screen rendering
5. **Layer Caching**: Cache static layers
6. **Shader Warmup**: Pre-compile shaders

## Best Practices

1. **Effect Usage**
   - Use pooled effects for short-lived effects
   - Combine similar effects when possible
   - Remove effects when no longer needed

2. **Layer Management**
   - Keep layer count minimal
   - Use appropriate layer for each object type
   - Consider performance when using parallax

3. **Sprite Optimization**
   - Use texture atlases for related sprites
   - Keep sprite sheets power-of-two sized
   - Minimize transparent pixels

4. **Shader Guidelines**
   - Test fallbacks on older hardware
   - Keep shader complexity reasonable
   - Cache shader parameters

## Future Enhancements

1. **Lighting System**: 2D lighting with shadows
2. **Particle Editor**: Visual particle effect designer
3. **Effect Preview**: Real-time effect parameter editing
4. **Performance Profiler**: Built-in graphics profiling
5. **Texture Streaming**: Dynamic texture loading