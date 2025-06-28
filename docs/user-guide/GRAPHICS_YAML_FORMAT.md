# Graphics YAML Format Extensions

This document describes the new graphics-related YAML format extensions for the Point & Click Engine v2.0. These extensions are designed to be backward compatible - existing games will continue to work without modification.

## Scene Graphics Configuration

Scenes can now define advanced graphics properties:

```yaml
scenes:
  - id: haunted_mansion
    background: mansion.png  # Still works (backward compatible)
    
    # New graphics configuration
    graphics:
      # Layer configuration
      layers:
        - name: far_background
          type: background
          texture: mountains.png
          parallax: 0.3
          tile_mode: stretch
          
        - name: clouds
          z_order: -500
          parallax: 0.5
          opacity: 0.7
          auto_scroll: [10, 0]  # Pixels per second [x, y]
          
        - name: background
          type: background
          texture: mansion_bg.png
          
        - name: foreground
          type: foreground
          parallax: 1.2  # Moves faster than camera
          
      # Ambient scene effects
      ambient_effects:
        - type: fog
          density: 0.3
          color: [200, 200, 220]
          speed: 5.0
          
        - type: rain
          intensity: 0.5
          wind: -10  # Negative = blowing left
          
        - type: darkness
          intensity: 0.7
          light_sources:
            - position: [512, 300]
              radius: 200
              color: [255, 200, 100]
              flicker: true
              
      # Camera configuration (extends existing)
      camera:
        bounds: [0, 0, 2048, 768]  # Existing
        smooth_follow: true         # New
        smooth_speed: 5.0          # New
        edge_scroll_enabled: false  # New
```

## Sprite and Animation Definitions

Sprites can now include effects and animation data:

```yaml
# In game_config.yaml or separate sprite_config.yaml
sprites:
  player:
    texture: hero_sheet.png
    frame_width: 64
    frame_height: 96
    
    # Animation definitions
    animations:
      - name: idle
        frames: [0, 1, 2, 1]
        duration: 0.3
        loop: true
        
      - name: walk
        frames: [4, 5, 6, 7, 8, 9, 10, 11]
        duration: 0.1
        loop: true
        
      - name: talk
        frames: [12, 13, 14, 13]
        duration: 0.15
        loop: true
        
      - name: use
        frames: [16, 17, 18, 19, 20]
        duration: 0.12
        loop: false
    
    # Default effects
    default_effects:
      - type: shadow
        offset: [0, 48]
        opacity: 0.5
        scale: [1.0, 0.3]
```

## Game Object Effects

Any game object (character, item, hotspot) can have effects:

```yaml
characters:
  - id: ghost
    name: "Ghostly Figure"
    position: [400, 300]
    sprite: ghost.png
    
    # Visual effects
    effects:
      - type: float
        amplitude: 10
        speed: 2.0
        
      - type: dissolve
        amount: 0.3
        
      - type: glow
        color: [100, 200, 255]
        radius: 20
        intensity: 0.8

items:
  - id: magic_key
    name: "Glowing Key"
    sprite: key.png
    position: [200, 400]
    
    effects:
      - type: pulse
        scale_amount: 0.1
        speed: 3.0
        
      - type: sparkle
        rate: 5  # Particles per second
        lifetime: 1.0
        
hotspots:
  - id: portal
    area: [500, 200, 100, 150]
    
    effects:
      - type: distortion
        amount: 0.2
        frequency: 5.0
```

## Transition Effects

Scene transitions now use the unified effects system:

```yaml
# In game_config.yaml
transitions:
  default: fade
  duration: 1.0
  
  # Custom transitions per scene
  custom:
    to_cave:
      effect: iris
      duration: 1.5
      center: [512, 384]  # Iris center point
      
    from_dream:
      effect: dissolve
      duration: 2.0
      pattern: noise  # or: blocks, spiral

# In scene files
scenes:
  - id: cave
    enter_transition:
      effect: curtain
      duration: 1.2
      direction: horizontal
      
    exit_transition:
      effect: slide
      direction: left
      duration: 0.8
```

## Effect Presets

Define reusable effect combinations:

```yaml
# In effects_presets.yaml
effect_presets:
  # Object presets
  magical_item:
    - type: glow
      color: [200, 100, 255]
      radius: 30
      intensity: 0.6
    - type: float
      amplitude: 5
      speed: 1.5
    - type: sparkle
      rate: 3
      
  highlighted:
    - type: outline
      color: [255, 255, 100]
      thickness: 2
    - type: pulse
      scale_amount: 0.05
      speed: 2.0
      
  # Scene presets  
  underwater_scene:
    - type: underwater
      wave_amplitude: 0.02
      wave_frequency: 3.0
    - type: bubbles
      count: 20
      rise_speed: 50
      
  spooky_scene:
    - type: darkness
      intensity: 0.5
    - type: fog
      density: 0.4
      speed: 3.0

# Usage in scenes/objects
items:
  - id: artifact
    effects_preset: magical_item
    
scenes:
  - id: underwater_cave
    graphics:
      ambient_effects_preset: underwater_scene
```

## Particle Effect Definitions

Define custom particle effects:

```yaml
# In particles.yaml
particle_effects:
  fire:
    texture: particle_flame.png
    emission_rate: 30
    lifetime: [0.5, 1.0]  # Random between min/max
    start_size: [8, 12]
    end_size: [2, 4]
    start_color: [255, 200, 0]
    end_color: [255, 50, 0]
    velocity: [0, -100, 20]  # [x, y, random_spread]
    gravity: -50
    blend_mode: additive
    
  magic_sparkle:
    texture: star.png
    emission_rate: 10
    lifetime: [1.0, 2.0]
    start_size: [4, 8]
    end_size: [0, 0]
    start_color: [255, 255, 255]
    end_color: [100, 100, 255]
    velocity: [0, 0, 50]  # Random in all directions
    rotation_speed: 180  # Degrees per second
    blend_mode: additive
```

## UI Graphics Configuration

Enhanced UI rendering options:

```yaml
ui_config:
  # Dialog box styling
  dialog_style:
    background: dialog_bg.9.png  # Nine-patch image
    padding: [20, 15, 20, 15]
    text_color: [255, 255, 255]
    shadow_color: [0, 0, 0]
    shadow_offset: [2, 2]
    typewriter_speed: 30  # Characters per second
    
  # Inventory rendering
  inventory_style:
    background: inventory_bg.png
    slot_size: [64, 64]
    slot_spacing: 10
    highlight_effect:
      type: glow
      color: [255, 255, 0]
      
  # Cursor effects
  cursor_effects:
    hover_hotspot:
      type: highlight
      color: [255, 255, 200]
    hover_item:
      type: pulse
      speed: 3.0
```

## Display Configuration

Enhanced display options:

```yaml
# In game_config.yaml
display:
  width: 1024
  height: 768
  fullscreen: false
  scaling_mode: fit_with_bars  # or: stretch, pixel_perfect
  
  # New options
  vsync: true
  target_fps: 60
  
  # Post-processing effects
  post_processing:
    - type: crt_scanlines
      intensity: 0.1
    - type: vignette
      radius: 0.8
      softness: 0.3
      
  # Retro options
  retro_mode:
    enabled: true
    pixelate: 2  # 2x pixel size
    palette_limit: 256
    dithering: true
```

## Shader Effects

Custom shader configurations:

```yaml
# In shaders.yaml
shaders:
  # Built-in shader configurations
  retro_crt:
    type: crt
    scanline_intensity: 0.15
    curvature: 0.1
    chromatic_aberration: 0.002
    
  dream_sequence:
    type: custom
    fragment_shader: shaders/dream.frag
    parameters:
      wave_amount: 0.01
      blur_amount: 0.3
      saturation: 0.5
```

## Backward Compatibility

All existing YAML files remain valid. The engine uses sensible defaults when new properties are omitted:

- Single background image → Automatically creates background layer
- No effects specified → Objects render normally
- No layer configuration → Default 4-layer setup
- Old transition names → Mapped to new effect system

## Performance Considerations

```yaml
# Performance hints in game_config.yaml
graphics:
  performance:
    effect_quality: medium  # low, medium, high
    max_particles: 1000
    enable_shadows: false
    texture_atlas: true  # Combine small textures
    
  # Mobile optimizations
  mobile:
    reduce_effects: true
    lower_resolution: true
    simplified_shaders: true
```

This extended format provides powerful graphics capabilities while maintaining the simplicity and clarity that YAML offers. Games can adopt these features incrementally without breaking existing functionality.