# Test script for shader-based effects
#
# This example demonstrates all the shader-based effects
# we've implemented in the new graphics system.

require "../src/point_click_engine"

# Initialize engine
engine = PointClickEngine::Core::Engine.new
engine.init("Shader Effects Test", 1280, 720)

# Create test sprite
sprite = PointClickEngine::Graphics::Sprites::Sprite.new
sprite.position = RL::Vector2.new(x: 640, y: 360)
sprite.size = RL::Vector2.new(x: 128, y: 128)
sprite.color = RL::WHITE

# Load a test texture if available
if File.exists?("assets/test_sprite.png")
  sprite.texture = RL.load_texture("assets/test_sprite.png")
else
  # Create a simple colored rectangle as fallback
  image = RL.gen_image_color(128, 128, RL::WHITE)
  RL.image_draw_rectangle(pointerof(image), 10, 10, 108, 108, RL::RED)
  sprite.texture = RL.load_texture_from_image(image)
  RL.unload_image(image)
end

# Test configurations
effects_to_test = [
  # Object effects
  {name: "Color Shift - Tint", effect: "tint", params: {color: "blue", duration: 2.0}},
  {name: "Color Shift - Rainbow", effect: "rainbow", params: {speed: 2.0}},
  {name: "Color Shift - Flash", effect: "flash", params: {color: "white", duration: 0.5}},
  {name: "Dissolve Out", effect: "dissolve", params: {mode: "out", duration: 2.0, edge_color: "orange"}},
  {name: "Dissolve In", effect: "dissolve", params: {mode: "in", duration: 2.0, edge_color: "green"}},
  {name: "Float Simple", effect: "float", params: {amplitude: 20.0, speed: 1.0}},
  {name: "Float Sway", effect: "float", params: {amplitude: 15.0, sway: true, sway_amplitude: 10.0}},
  {name: "Highlight Glow", effect: "highlight", params: {type: "glow", color: "yellow", intensity: 2.0}},
  {name: "Highlight Outline", effect: "highlight", params: {type: "outline", color: "red", thickness: 3.0}},
  {name: "Pulse Breathe", effect: "pulse", params: {scale_amount: 0.2, speed: 1.0}},
  {name: "Pulse Heartbeat", effect: "pulse", params: {mode: "heartbeat", scale_amount: 0.15}},
  {name: "Shake", effect: "shake", params: {amplitude: 10.0, frequency: 15.0, chromatic: 0.005}},
  
  # Post-processing effects (would be applied to whole scene)
  {name: "Gaussian Blur", effect: "gaussian_blur", params: {radius: 5.0, quality: 4}},
  {name: "Motion Blur", effect: "motion_blur", params: {angle: 0.785, strength: 0.03}},
  {name: "Heat Haze", effect: "heat_haze", params: {strength: 0.02, frequency: 8.0}},
  {name: "Shock Wave", effect: "shock_wave", params: {center: [640, 360], radius: 0.5, force: 0.1}},
  {name: "Glow", effect: "glow", params: {threshold: 0.7, intensity: 2.0, tint: "yellow"}},
]

current_effect_index = 0
current_effect : PointClickEngine::Graphics::Effects::Effect? = nil
effect_manager = PointClickEngine::Graphics::Effects::EffectManager.new

# Instructions text
instructions = [
  "Shader Effects Test",
  "Press SPACE to cycle through effects",
  "Press R to reset current effect",
  "Press ESC to exit",
  "",
  "Current Effect: None"
]

# Main loop
until RL.window_should_close?
  # Handle input
  if RL.is_key_pressed(RL::KeyboardKey::Space)
    # Move to next effect
    current_effect_index = (current_effect_index + 1) % effects_to_test.size
    effect_config = effects_to_test[current_effect_index]
    
    # Create new effect
    effect_name = effect_config[:effect]
    params = effect_config[:params]
    
    # Try object effect first
    current_effect = PointClickEngine::Graphics::Effects::ObjectEffects.create(effect_name, **params)
    
    # If not found, try post-processing
    current_effect ||= PointClickEngine::Graphics::Effects::PostProcessing.create(effect_name, **params)
    
    if current_effect
      # Remove all effects and add new one
      effect_manager.clear_effects(sprite)
      effect_manager.add_effect(sprite, current_effect)
      
      instructions[-1] = "Current Effect: #{effect_config[:name]}"
    else
      instructions[-1] = "Current Effect: Failed to create #{effect_config[:name]}"
    end
  elsif RL.is_key_pressed(RL::KeyboardKey::R) && current_effect
    # Reset current effect
    current_effect.reset
  end
  
  # Update
  dt = RL.get_frame_time
  effect_manager.update(dt)
  
  # Render
  RL.begin_drawing
  RL.clear_background(RL::DARK_GRAY)
  
  # Create effect context
  effect_context = PointClickEngine::Graphics::Effects::EffectContext.new(
    PointClickEngine::Graphics::Effects::EffectContext::TargetType::Sprite,
    nil,  # No renderer needed for this test
    dt
  )
  effect_context.sprite = sprite
  
  # Apply effects
  effect_manager.apply_effects(sprite, effect_context)
  
  # Draw sprite
  if texture = sprite.texture
    RL.draw_texture_pro(
      texture,
      RL::Rectangle.new(x: 0, y: 0, width: texture.width.to_f32, height: texture.height.to_f32),
      RL::Rectangle.new(
        x: sprite.position.x - sprite.size.x / 2,
        y: sprite.position.y - sprite.size.y / 2,
        width: sprite.size.x,
        height: sprite.size.y
      ),
      RL::Vector2.new(x: sprite.size.x / 2, y: sprite.size.y / 2),
      sprite.rotation,
      sprite.tint
    )
  end
  
  # Draw instructions
  y = 10
  instructions.each do |line|
    RL.draw_text(line, 10, y, 20, RL::WHITE)
    y += 25
  end
  
  # Draw FPS
  RL.draw_fps(1200, 10)
  
  RL.end_drawing
end

# Cleanup
if texture = sprite.texture
  RL.unload_texture(texture)
end

engine.cleanup