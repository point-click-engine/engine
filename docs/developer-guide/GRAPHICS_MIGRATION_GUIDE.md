# Graphics Module Migration Guide

This guide helps you migrate from the old graphics system to the new modular graphics architecture in Point & Click Engine v2.0.

## Overview of Changes

### Old Structure
```
graphics/
├── display_manager.cr       # Monolithic display management
├── camera.cr               # Basic camera
├── cameras/                # Camera effects mixed with camera logic
├── sprites/animated.cr     # Animation without effects support
├── particles.cr            # Basic particle system
├── transitions.cr          # Separate transition system
└── shaders/                # Shader management
```

### New Structure
```
graphics/
├── core/                   # Core infrastructure
├── sprites/                # Enhanced sprite system
├── effects/                # Unified effects for everything
├── layers/                 # Layer-based rendering
├── ui/                     # UI-specific rendering
└── utils/                  # Graphics utilities
```

## Migration Steps

### 1. Update Imports

**Old:**
```crystal
require "../graphics/display_manager"
require "../graphics/camera"
require "../graphics/render_context"
```

**New:**
```crystal
require "../graphics/graphics"  # Main module includes everything

# Or specific imports:
require "../graphics/core/display"
require "../graphics/core/camera"
require "../graphics/core/renderer"
```

### 2. Display Management

**Old:**
```crystal
# In Engine
@display_manager = Graphics::DisplayManager.new(width, height)
@display_manager.calculate_scaling
```

**New:**
```crystal
# In Engine
@display = Graphics::Core::Display.new(width, height)
# Scaling is automatic
```

**Key Changes:**
- `DisplayManager` → `Core::Display`
- Removed render texture management (now in Renderer)
- Removed shader system integration (now separate)
- Cleaner API focused only on display/scaling

### 3. Camera System

**Old:**
```crystal
# Basic camera
@camera = Graphics::Camera.new(viewport_width, viewport_height)
@camera.follow(character)

# Camera manager for effects
@camera_manager = Graphics::Cameras::CameraManager.new(width, height)
@camera_manager.apply_effect(:shake, intensity: 10.0)
```

**New:**
```crystal
# Camera is simpler, effects are separate
@camera = Graphics::Core::Camera.new
@camera.set_bounds(scene_width, scene_height)

# Effects applied through effect system
@effect_manager.apply_camera_effect(:shake, intensity: 10.0)
```

**Key Changes:**
- Camera is just about position/bounds
- Effects moved to unified effect system
- No more camera manager complexity

### 4. Rendering

**Old:**
```crystal
# Scattered rendering logic
@display_manager.begin_game_rendering
# Draw objects
@display_manager.end_game_rendering
@display_manager.draw_to_screen
```

**New:**
```crystal
# Centralized renderer
@renderer = Graphics::Core::Renderer.new(@display)
@renderer.render do |context|
  # All drawing through context
  context.draw_sprite(sprite, position)
end
```

**Key Changes:**
- Centralized rendering pipeline
- Render context for all drawing
- Automatic culling and optimization

### 5. Sprites and Animation

**Old:**
```crystal
sprite = Graphics::Sprites::Animated.new(pos, fw, fh, frame_count)
sprite.load_texture("hero.png")
sprite.play
```

**New:**
```crystal
# Same API, but with effects support
sprite = Graphics::Sprites::AnimatedSprite.new("hero.png", fw, fh, frame_count)
sprite.play

# Can add effects
sprite.add_effect(:glow, color: RL::YELLOW)
```

**Key Changes:**
- Better constructor options
- Built-in effect support
- Named animations support

### 6. Transitions

**Old:**
```crystal
# Separate transition system
@transition_manager = Graphics::TransitionManager.new(width, height)
@transition_manager.start_transition(:fade, 1.0) do
  change_scene
end
```

**New:**
```crystal
# Transitions are scene effects
@scene.add_transition_effect(:fade, duration: 1.0) do
  change_scene
end
```

**Key Changes:**
- Transitions are just another effect type
- Unified with effect system
- Applied at scene level

### 7. Layer Management

**New Feature - No Direct Migration:**
```crystal
# Add layer support
@layers = Graphics::Layers::LayerManager.new
@layers.add_default_layers

# Assign objects to layers
game_object.layer = :foreground

# Render with layers
@layers.render(@camera, @renderer) do |layer|
  render_objects_in_layer(layer)
end
```

### 8. Effect System

**New Feature - Replaces Various Systems:**
```crystal
# Object effects (replaces hardcoded behaviors)
item.add_effect(:pulse, speed: 2.0)
character.add_effect(:dissolve, amount: 0.5)

# Scene effects (replaces separate systems)
scene.add_ambient_effect(:rain, intensity: 0.8)
scene.add_ambient_effect(:fog, density: 0.3)

# Camera effects (replaces camera manager effects)
camera.add_effect(:shake, intensity: 10.0, duration: 1.0)
```

## Common Patterns

### Initialization

**Old:**
```crystal
class Engine
  def initialize_graphics
    @display_manager = Graphics::DisplayManager.new(WIDTH, HEIGHT)
    @camera = Graphics::Camera.new(WIDTH, HEIGHT)
    @render_context = Graphics::RenderContext.new(@camera)
    @transition_manager = Graphics::TransitionManager.new(WIDTH, HEIGHT)
  end
end
```

**New:**
```crystal
class Engine
  def initialize_graphics
    @display = Graphics::Display.new(WIDTH, HEIGHT)
    @renderer = Graphics::Renderer.new(@display)
    @layers = Graphics::LayerManager.new
    @layers.add_default_layers
    # Camera is in renderer
  end
end
```

### Rendering Loop

**Old:**
```crystal
def render
  @display_manager.begin_game_rendering
  
  # Render background
  @render_context.draw_texture(@background, RL::Vector2.new(x: 0, y: 0))
  
  # Render objects
  @objects.each do |obj|
    obj.draw(@render_context)
  end
  
  @display_manager.end_game_rendering
  @display_manager.draw_to_screen
  
  # UI on top
  draw_ui
end
```

**New:**
```crystal
def render
  @renderer.render do |context|
    @layers.render(@camera, @renderer) do |layer|
      case layer.name
      when "background"
        # Background renders itself
      when "scene"
        @objects.select { |o| o.layer == :scene }.each do |obj|
          obj.draw_with_context(context)
        end
      when "ui"
        draw_ui_with_context(context)
      end
    end
  end
end
```

## Gradual Migration Strategy

You don't need to migrate everything at once:

### Phase 1: Core Systems (Required)
1. Update Display/Renderer initialization
2. Update main render loop
3. Update camera creation

### Phase 2: Enhanced Features (Optional)
1. Add layer support
2. Integrate effects system
3. Update sprites to use effects

### Phase 3: Advanced Features (As Needed)
1. Custom effects
2. Post-processing
3. Advanced UI rendering

## Backward Compatibility Helpers

For gradual migration, you can create compatibility wrappers:

```crystal
# Compatibility wrapper for old DisplayManager API
class DisplayManagerCompat
  def initialize(width, height)
    @display = Graphics::Display.new(width, height)
    @renderer = Graphics::Renderer.new(@display)
  end
  
  def begin_game_rendering
    # No-op, renderer handles this
  end
  
  def end_game_rendering
    # No-op
  end
  
  def draw_to_screen(&block)
    @renderer.render do |context|
      yield context
    end
  end
end
```

## Benefits After Migration

1. **Cleaner Architecture** - Each module has a single responsibility
2. **Unified Effects** - One system for all visual effects
3. **Better Performance** - Automatic culling, batching, and optimization
4. **More Features** - Layers, advanced effects, better animation support
5. **Easier Maintenance** - Modular design is easier to extend and debug

## Need Help?

- Check the [Graphics Module Architecture](GRAPHICS_MODULE_ARCHITECTURE.md) for detailed API docs
- See [example implementations](../examples/graphics/) for working code
- Post questions in the [discussions forum](https://github.com/point-click-engine/discussions)

Remember: The new system is designed to be more powerful while being easier to use. Take time to understand the new architecture - it will pay off in cleaner, more maintainable code.