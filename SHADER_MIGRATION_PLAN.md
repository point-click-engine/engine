# Shader-Based Effects Migration Plan

## Overview
Migrating all effects in the Point & Click Engine from CPU-based drawing to GPU shader-based rendering for better performance and visual quality.

## Phase 1: Core Infrastructure ✅
- [x] Create `ShaderEffect` base class
- [x] Create `ShaderLibrary` with common GLSL functions
  - Noise functions (rand, noise, fbm)
  - Easing functions (linear, quad, cubic, sine, elastic, bounce)
  - Color functions (RGB/HSV conversion, grayscale, sepia, contrast, brightness)
  - Shape functions (circle, box, heart, star, hexagon SDFs)
  - Distortion functions (wave, ripple, swirl, lens, pixelate)

## Phase 2: Object Effects Migration
Convert all object-level effects to shader-based implementations:

### 1. **ColorShift Effect**
- Current: CPU-based color manipulation
- Shader: Fragment shader with color transformation matrices
- Features: Tint, grayscale, sepia, rainbow, flash modes

### 2. **Dissolve Effect**
- Current: Simple opacity fade
- Shader: Noise-based dissolve with threshold
- Features: Multiple dissolve patterns (noise, circular, linear)

### 3. **Float Effect**
- Current: CPU position calculation
- Shader: Vertex shader with sine wave offset
- Features: Configurable amplitude, frequency, phase

### 4. **Highlight Effect**
- Current: Drawing colored rectangles
- Shader: Outline/glow effect using distance fields
- Features: Configurable thickness, color, glow intensity

### 5. **Pulse Effect**
- Current: CPU scale calculation
- Shader: Vertex shader with scale modulation
- Features: Breathing effect, heartbeat pattern

### 6. **Shake Effect**
- Current: Random position offset
- Shader: Vertex shader with noise-based displacement
- Features: Configurable intensity, frequency, decay

## Phase 3: Scene Effects Migration
Convert scene-wide effects:

### 1. **Ambient Effects**
- **Fog**: Distance-based fog with color gradients
- **Rain**: Particle system with proper depth sorting
- **Snow**: Particle system with wind simulation
- **Darkness**: Vignette overlay with light sources

### 2. **Environment Effects**
- **Underwater**: Wave distortion + caustics + color tint
- **Heat Haze**: Shimmer distortion effect
- **Wind**: Directional particle effects

### 3. **Transition Effects** ✅
- Already implemented: Swirl, Heart Wipe, Star Wipe, Curtain
- To add: All remaining transitions from old system

## Phase 4: Camera Effects Migration
Convert camera manipulation effects:

### 1. **Movement Effects**
- **Shake**: Screen-space vertex displacement
- **Sway**: Sine-based rotation (boat/drunk effect)
- **Bounce**: Spring physics simulation

### 2. **View Effects**  
- **Zoom**: Smooth scale with focal point
- **Rotation**: Transform matrix manipulation
- **Follow**: Smooth target tracking with lag

### 3. **Post-Processing**
- **Blur**: Gaussian blur passes
- **Chromatic Aberration**: RGB channel separation
- **Scan Lines**: CRT monitor effect

## Phase 5: Advanced Effects
Port advanced effects from old system:

### 1. **Cinematic Effects**
- **Letter Box**: Aspect ratio bars
- **Film Grain**: Noise overlay
- **Old Film**: Scratches, dust, sepia
- **Matrix Rain**: Digital rain effect

### 2. **Artistic Effects**
- **Pixelate**: Mosaic effect
- **Oil Painting**: Kuwahara filter
- **Sketch**: Edge detection + hatching
- **Watercolor**: Fluid simulation

### 3. **Glitch Effects**
- **Digital Glitch**: RGB shift + scan lines
- **Data Moshing**: Frame blending artifacts
- **Signal Loss**: Static + distortion

## Phase 6: Optimization & Polish
- Implement shader caching system
- Add shader hot-reloading for development
- Create shader preset system
- Optimize uniform updates
- Add quality settings (low/medium/high)
- Implement fallback system for older GPUs

## Technical Considerations

### Shader Management
- All shaders compiled at startup
- Cached by effect type
- Uniform locations cached
- Hot reload in debug mode

### Performance
- Batch similar effects
- Minimize state changes
- Use texture atlases
- Implement LOD system

### Compatibility
- Require OpenGL 3.3 / OpenGL ES 3.0
- Detect shader compilation errors
- Provide graceful degradation

## Benefits
1. **Performance**: 10-100x faster than CPU rendering
2. **Quality**: Smooth gradients, perfect anti-aliasing
3. **Complexity**: Effects impossible with CPU (swirl, ripple)
4. **Consistency**: All effects use same pipeline
5. **Extensibility**: Easy to add new effects

## Timeline
- Phase 1: ✅ Complete
- Phase 2: In Progress (Object Effects)
- Phase 3: 2 days
- Phase 4: 2 days  
- Phase 5: 3 days
- Phase 6: 2 days

Total estimated time: ~9 days for full migration