# Shader Effects Demo

require "raylib-cr"
require "../src/graphics/graphics"

class ShaderEffectsDemo
  @display : PointClickEngine::Graphics::Display
  @renderer : PointClickEngine::Graphics::Renderer
  @layers : PointClickEngine::Graphics::LayerManager
  @post_processor : PointClickEngine::Graphics::Shaders::PostProcessor

  # Demo content
  @sprites : Array(PointClickEngine::Graphics::Sprite)
  @particles : PointClickEngine::Graphics::Particles::Emitter
  @time : Float32 = 0.0f32

  # Effects
  @current_preset : Int32 = 0
  @preset_names = ["None", "CRT", "Game Boy", "VHS", "Arcade", "Custom Mix"]

  # Individual effects for custom mix
  @crt_effect : PointClickEngine::Graphics::Shaders::Retro::CRTEffect
  @pixelate_effect : PointClickEngine::Graphics::Shaders::Retro::PixelateEffect
  @lcd_effect : PointClickEngine::Graphics::Shaders::Retro::LCDEffect
  @vhs_effect : PointClickEngine::Graphics::Shaders::Retro::VHSEffect
  @bloom_effect : PointClickEngine::Graphics::Shaders::Effects::BloomEffect
  @chromatic_effect : PointClickEngine::Graphics::Shaders::Effects::ChromaticAberrationEffect
  @grain_effect : PointClickEngine::Graphics::Shaders::Effects::FilmGrainEffect

  def initialize
    RL.init_window(1280, 720, "Shader Effects Demo")
    RL.set_target_fps(60)

    @display = PointClickEngine::Graphics::Display.new(1280, 720)
    @renderer = PointClickEngine::Graphics::Renderer.new(@display)
    @layers = PointClickEngine::Graphics::LayerManager.new
    @layers.add_default_layers

    # Create post-processor
    @post_processor = PointClickEngine::Graphics::Shaders::PostProcessor.new(1280, 720)

    # Create effects
    @crt_effect = PointClickEngine::Graphics::Shaders::Retro::CRTEffect.create
    @pixelate_effect = PointClickEngine::Graphics::Shaders::Retro::PixelateEffect.create
    @lcd_effect = PointClickEngine::Graphics::Shaders::Retro::LCDEffect.create
    @vhs_effect = PointClickEngine::Graphics::Shaders::Retro::VHSEffect.create
    @bloom_effect = PointClickEngine::Graphics::Shaders::Effects::BloomEffect.create
    @chromatic_effect = PointClickEngine::Graphics::Shaders::Effects::ChromaticAberrationEffect.create
    @grain_effect = PointClickEngine::Graphics::Shaders::Effects::FilmGrainEffect.create

    setup_demo_content
  end

  def run
    until RL.close_window?
      update
      draw
    end

    cleanup
  end

  private def setup_demo_content
    @sprites = [] of PointClickEngine::Graphics::Sprite

    # Create colorful sprites
    colors = [RL::RED, RL::GREEN, RL::BLUE, RL::YELLOW, RL::PURPLE, RL::ORANGE]

    6.times do |i|
      sprite = create_sprite(colors[i], 64)
      sprite.position = RL::Vector2.new(
        x: 200 + i * 150,
        y: 360
      )
      @sprites << sprite
    end

    # Create particle emitter
    config = PointClickEngine::Graphics::Particles::EmitterConfig.new
    config.emission_rate = 50.0f32
    config.lifetime_min = 1.0f32
    config.lifetime_max = 3.0f32
    config.speed_min = 50.0f32
    config.speed_max = 150.0f32
    config.start_color = RL::YELLOW
    config.end_color = RL::Color.new(r: 255, g: 100, b: 0, a: 0)
    config.start_size = 8.0f32
    config.end_size = 2.0f32

    @particles = PointClickEngine::Graphics::Particles::Emitter.new(config)
    @particles.position = RL::Vector2.new(x: 640, y: 200)
    @particles.start
  end

  private def create_sprite(color : RL::Color, size : Int32) : PointClickEngine::Graphics::Sprite
    image = RL.gen_image_color(size, size, color)

    # Add some detail
    RL.image_draw_circle(image, size // 2, size // 2, size // 3, RL::WHITE)
    RL.image_draw_circle(image, size // 2, size // 2, size // 4, color)

    texture = RL.load_texture_from_image(image)
    RL.unload_image(image)

    sprite = PointClickEngine::Graphics::Sprite.new
    sprite.texture = texture
    sprite.center_origin
    sprite
  end

  private def update
    dt = RL.get_frame_time
    @time += dt

    # Update particles
    @particles.update(dt)

    # Animate sprites
    @sprites.each_with_index do |sprite, i|
      sprite.rotation = @time * 30 * (i + 1)
      sprite.position.y = 360 + Math.sin(@time * 2 + i) * 50
    end

    # Handle input
    if RL.key_pressed?(RL::KeyboardKey::Left)
      @current_preset = (@current_preset - 1) % @preset_names.size
      apply_preset
    elsif RL.key_pressed?(RL::KeyboardKey::Right)
      @current_preset = (@current_preset + 1) % @preset_names.size
      apply_preset
    end

    # Custom mix controls
    if @current_preset == 5 # Custom Mix
      handle_custom_controls
    end
  end

  private def apply_preset
    case @current_preset
    when 0 # None
      @post_processor.clear_effects
    when 1 # CRT
      PointClickEngine::Graphics::Shaders::PostProcessPresets.crt(@post_processor)
    when 2 # Game Boy
      PointClickEngine::Graphics::Shaders::PostProcessPresets.gameboy(@post_processor)
    when 3 # VHS
      PointClickEngine::Graphics::Shaders::PostProcessPresets.vhs(@post_processor)
    when 4 # Arcade
      PointClickEngine::Graphics::Shaders::PostProcessPresets.arcade(@post_processor)
    when 5 # Custom Mix
      setup_custom_mix
    end
  end

  private def setup_custom_mix
    @post_processor.clear_effects
    @post_processor.add_effect(@chromatic_effect, true)
    @post_processor.add_effect(@grain_effect, true)
    @post_processor.add_effect(@bloom_effect, false)
    @post_processor.add_effect(@pixelate_effect, false)
  end

  private def handle_custom_controls
    # Toggle effects with number keys
    if RL.key_pressed?(RL::KeyboardKey::One)
      toggle_effect(@chromatic_effect)
    elsif RL.key_pressed?(RL::KeyboardKey::Two)
      toggle_effect(@grain_effect)
    elsif RL.key_pressed?(RL::KeyboardKey::Three)
      toggle_effect(@bloom_effect)
    elsif RL.key_pressed?(RL::KeyboardKey::Four)
      toggle_effect(@pixelate_effect)
    end

    # Adjust intensity with +/-
    if RL.key_down?(RL::KeyboardKey::Equal) || RL.key_down?(RL::KeyboardKey::KpAdd)
      adjust_intensity(0.01f32)
    elsif RL.key_down?(RL::KeyboardKey::Minus) || RL.key_down?(RL::KeyboardKey::KpSubtract)
      adjust_intensity(-0.01f32)
    end
  end

  private def toggle_effect(effect : PointClickEngine::Graphics::Shaders::ShaderEffect)
    enabled = !effect.enabled
    @post_processor.set_effect_enabled(effect, enabled)
  end

  private def adjust_intensity(delta : Float32)
    @post_processor.effects.each do |entry|
      if entry.enabled
        entry.effect.intensity = (entry.effect.intensity + delta).clamp(0.0f32, 2.0f32)
      end
    end
  end

  private def draw
    # Begin post-processing capture
    @post_processor.begin_capture

    # Clear and draw scene
    RL.clear_background(RL::Color.new(r: 20, g: 20, b: 30, a: 255))

    # Draw background pattern
    draw_background

    # Draw sprites
    @sprites.each do |sprite|
      sprite.draw
    end

    # Draw particles
    @particles.draw

    # Draw UI (before post-processing)
    draw_ui_background

    # End capture
    @post_processor.end_capture

    # Apply post-processing and render
    RL.begin_drawing
    @post_processor.render(RL.get_frame_time)

    # Draw UI overlay (after post-processing)
    draw_ui_overlay

    RL.end_drawing
  end

  private def draw_background
    # Draw grid pattern
    grid_size = 32
    color = RL::Color.new(r: 40, g: 40, b: 50, a: 255)

    (1280 // grid_size).times do |x|
      RL.draw_line(x * grid_size, 0, x * grid_size, 720, color)
    end

    (720 // grid_size).times do |y|
      RL.draw_line(0, y * grid_size, 1280, y * grid_size, color)
    end
  end

  private def draw_ui_background
    # Title in the scene
    RL.draw_text("SHADER EFFECTS", 640 - 100, 100, 32, RL::WHITE)
  end

  private def draw_ui_overlay
    # Header
    RL.draw_rectangle(0, 0, 1280, 80, RL::Color.new(r: 0, g: 0, b: 0, a: 180))
    RL.draw_text("Shader Effects Demo", 10, 10, 24, RL::WHITE)
    RL.draw_text("Current: #{@preset_names[@current_preset]}", 10, 40, 20, RL::YELLOW)
    RL.draw_text("Use LEFT/RIGHT arrows to switch presets", 10, 60, 14, RL::GRAY)

    # Custom mix controls
    if @current_preset == 5
      draw_custom_controls
    end

    # FPS
    RL.draw_fps(1200, 10)
  end

  private def draw_custom_controls
    y = 600
    bg_height = 110
    RL.draw_rectangle(0, y - 10, 1280, bg_height, RL::Color.new(r: 0, g: 0, b: 0, a: 180))

    RL.draw_text("Custom Mix Controls:", 10, y, 16, RL::WHITE)
    y += 25

    effects = [
      {"1: Chromatic Aberration", @chromatic_effect},
      {"2: Film Grain", @grain_effect},
      {"3: Bloom", @bloom_effect},
      {"4: Pixelate", @pixelate_effect},
    ]

    effects.each do |name, effect|
      color = effect.enabled ? RL::GREEN : RL::RED
      status = effect.enabled ? "ON" : "OFF"
      intensity = effect.enabled ? " (#{(effect.intensity * 100).to_i}%)" : ""

      RL.draw_text("#{name}: #{status}#{intensity}", 10, y, 14, color)
      y += 18
    end

    RL.draw_text("Press +/- to adjust intensity", 400, y - 36, 14, RL::GRAY)
  end

  private def cleanup
    @renderer.cleanup
    @post_processor.cleanup

    @sprites.each do |sprite|
      RL.unload_texture(sprite.texture.not_nil!) if sprite.texture
    end

    RL.close_window
  end
end

# Extension for direct texture access
class PointClickEngine::Graphics::Sprites::Sprite
  property texture : RL::Texture2D?

  def draw
    return unless tex = @texture

    RL.draw_texture_pro(
      tex,
      RL::Rectangle.new(0, 0, tex.width, tex.height),
      RL::Rectangle.new(@position.x, @position.y, tex.width * @scale.x, tex.height * @scale.y),
      RL::Vector2.new(@origin.x * @scale.x, @origin.y * @scale.y),
      @rotation,
      @tint
    )
  end
end

# Run the demo
demo = ShaderEffectsDemo.new
demo.run
