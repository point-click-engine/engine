# Particle Effects Demo - Shows particle system integrated with effects

require "raylib-cr"
require "../src/graphics/graphics"

class ParticleEffectsDemo
  @display : PointClickEngine::Graphics::Display
  @renderer : PointClickEngine::Graphics::Renderer
  @layers : PointClickEngine::Graphics::LayerManager
  @effect_manager : PointClickEngine::Graphics::Effects::EffectManager

  @sprites : Array(PointClickEngine::Graphics::Sprite)
  @hero : PointClickEngine::Graphics::Sprite
  @active_emitters : Array(PointClickEngine::Graphics::Particles::Emitter)
  @last_click_pos : RL::Vector2 = RL::Vector2.new(x: 0, y: 0)

  def initialize
    RL.init_window(1280, 720, "Particle Effects Demo")
    RL.set_target_fps(60)

    @display = PointClickEngine::Graphics::Display.new(1280, 720)
    @renderer = PointClickEngine::Graphics::Renderer.new(@display)
    @layers = PointClickEngine::Graphics::LayerManager.new
    @layers.add_default_layers
    @effect_manager = PointClickEngine::Graphics::Effects::EffectManager.new

    # Create scene
    @sprites = create_scene_objects
    @hero = create_hero
    @active_emitters = [] of PointClickEngine::Graphics::Particles::Emitter

    # Start with some ambient effects
    setup_ambient_particles
  end

  def run
    until RL.close_window?
      update
      draw
    end

    cleanup
  end

  private def create_scene_objects : Array(PointClickEngine::Graphics::Sprite)
    sprites = [] of PointClickEngine::Graphics::Sprite

    # Create some interactive objects
    # Campfire
    campfire = create_colored_sprite(RL::DARKBROWN, 40)
    campfire.position = RL::Vector2.new(x: 300, y: 500)
    campfire.add_effect("particle", type: "fire", follow: true, offset: [0, -20])
    sprites << campfire

    # Chimney
    chimney = create_colored_sprite(RL::GRAY, 60)
    chimney.position = RL::Vector2.new(x: 800, y: 200)
    chimney.add_effect("particle", type: "smoke", follow: true, offset: [0, -40])
    sprites << chimney

    # Magic crystal
    crystal = create_colored_sprite(RL::PURPLE, 30)
    crystal.position = RL::Vector2.new(x: 600, y: 400)
    crystal.add_effect("particle", type: "sparkles", follow: true)
    crystal.add_effect("float", amplitude: 20, speed: 0.5)
    crystal.add_effect("glow", color: [200, 100, 255])
    sprites << crystal

    # Bubbling pot
    pot = create_colored_sprite(RL::DARKGREEN, 50)
    pot.position = RL::Vector2.new(x: 1000, y: 500)
    pot.add_effect("particle", type: "bubbles", follow: true, offset: [0, -25])
    sprites << pot

    sprites
  end

  private def create_hero : PointClickEngine::Graphics::Sprite
    hero = PointClickEngine::Graphics::Sprite.new
    hero.tint = RL::WHITE
    hero.scale = 1.2f32
    hero.position = RL::Vector2.new(x: 640, y: 360)
    hero.center_origin

    # Add trail effect to hero
    hero.add_effect("particle", type: "trail", follow: true, intensity: 0.5)

    hero
  end

  private def create_colored_sprite(color : RL::Color, size : Int32) : PointClickEngine::Graphics::Sprite
    sprite = PointClickEngine::Graphics::Sprite.new
    sprite.tint = color
    sprite.scale = size / 64.0f32
    sprite.center_origin
    sprite
  end

  private def setup_ambient_particles
    # Add rain effect
    rain = PointClickEngine::Graphics::Particles.rain(
      RL::Vector2.new(x: 640, y: -50),
      1280.0f32,
      0.3f32
    )
    @active_emitters << rain
  end

  private def update
    dt = RL.get_frame_time

    # Update hero movement
    update_hero_movement(dt)

    # Update effects
    @effect_manager.update(dt)

    # Update sprites
    @sprites.each(&.update(dt))
    @hero.update(dt)

    # Update standalone emitters
    @active_emitters.each(&.update(dt))
    @active_emitters.reject! { |e| !e.active && !e.has_particles? }

    # Handle input
    handle_input
  end

  private def update_hero_movement(dt : Float32)
    speed = 300.0f32

    # WASD movement
    moving = false
    if RL.key_down?(RL::KeyboardKey::W)
      @hero.position.y -= speed * dt
      moving = true
    end
    if RL.key_down?(RL::KeyboardKey::S)
      @hero.position.y += speed * dt
      moving = true
    end
    if RL.key_down?(RL::KeyboardKey::A)
      @hero.position.x -= speed * dt
      moving = true
    end
    if RL.key_down?(RL::KeyboardKey::D)
      @hero.position.x += speed * dt
      moving = true
    end

    # Keep hero in bounds
    @hero.position.x = @hero.position.x.clamp(50, 1230)
    @hero.position.y = @hero.position.y.clamp(50, 670)

    # Add dust when moving
    if moving && Random.rand < 0.1
      dust = PointClickEngine::Graphics::Particles.dust(@hero.position, 20.0f32)
      @active_emitters << dust
    end
  end

  private def handle_input
    # Number keys for preset effects
    if RL.key_pressed?(RL::KeyboardKey::One)
      create_explosion_at_cursor
    elsif RL.key_pressed?(RL::KeyboardKey::Two)
      toggle_fire_effect
    elsif RL.key_pressed?(RL::KeyboardKey::Three)
      create_hit_spark_at_cursor
    elsif RL.key_pressed?(RL::KeyboardKey::Four)
      toggle_snow_effect
    elsif RL.key_pressed?(RL::KeyboardKey::Five)
      create_magic_burst
    elsif RL.key_pressed?(RL::KeyboardKey::Six)
      toggle_object_particles
    elsif RL.key_pressed?(RL::KeyboardKey::Zero)
      clear_all_particles
    end

    # Mouse click for effects at position
    if RL.mouse_button_pressed?(RL::MouseButton::Left)
      @last_click_pos = @display.screen_to_game(
        RL.get_mouse_x,
        RL.get_mouse_y
      )
      create_click_effect(@last_click_pos)
    end

    # Right click for continuous effect
    if RL.is_mouse_button_down(RL::MouseButton::Right)
      mouse_pos = @display.screen_to_game(
        RL.get_mouse_x,
        RL.get_mouse_y
      )
      if Random.rand < 0.3
        sparkle = PointClickEngine::Graphics::Particles.sparkles(mouse_pos, 10.0f32)
        sparkle.config.emission_rate = 5.0f32
        @active_emitters << sparkle
      end
    end
  end

  private def create_explosion_at_cursor
    pos = @display.screen_to_game(RL.get_mouse_x, RL.get_mouse_y)
    explosion = PointClickEngine::Graphics::Particles.explosion(pos, 1.5f32)
    @active_emitters << explosion

    # Add screen shake
    @effect_manager.add_camera_effect("shake", amplitude: 15, frequency: 20, duration: 0.3)
  end

  private def toggle_fire_effect
    # Find existing fire or create new one
    fire_emitter = @active_emitters.find { |e| e.config.start_color.r > 200 && e.config.gravity.y < 0 }

    if fire_emitter
      @active_emitters.delete(fire_emitter)
    else
      pos = @display.screen_to_game(RL.get_mouse_x, RL.get_mouse_y)
      fire = PointClickEngine::Graphics::Particles.fire(pos, 2.0f32)
      @active_emitters << fire
    end
  end

  private def create_hit_spark_at_cursor
    pos = @display.screen_to_game(RL.get_mouse_x, RL.get_mouse_y)

    # Calculate direction from hero to click
    direction = RL::Vector2.new(
      x: pos.x - @hero.position.x,
      y: pos.y - @hero.position.y
    )

    # Normalize
    length = Math.sqrt(direction.x * direction.x + direction.y * direction.y)
    if length > 0
      direction.x /= length
      direction.y /= length
    end

    spark = PointClickEngine::Graphics::Particles.hit_spark(pos, direction)
    @active_emitters << spark
  end

  private def toggle_snow_effect
    # Toggle between rain and snow
    weather = @active_emitters.find { |e| e.config.emission_shape == PointClickEngine::Graphics::Particles::EmissionShape::Line }

    if weather
      @active_emitters.delete(weather)
      if weather.config.gravity.y > 100 # Was rain
        snow = PointClickEngine::Graphics::Particles.snow(
          RL::Vector2.new(x: 640, y: -50),
          1280.0f32,
          0.5f32
        )
        @active_emitters << snow
      end
    else
      rain = PointClickEngine::Graphics::Particles.rain(
        RL::Vector2.new(x: 640, y: -50),
        1280.0f32,
        0.5f32
      )
      @active_emitters << rain
    end
  end

  private def create_magic_burst
    # Create a burst of magical particles at hero position
    colors = [
      RL::Color.new(r: 255, g: 100, b: 255, a: 255), # Pink
      RL::Color.new(r: 100, g: 255, b: 255, a: 255), # Cyan
      RL::Color.new(r: 255, g: 255, b: 100, a: 255), # Yellow
    ]

    3.times do |i|
      config = PointClickEngine::Graphics::Particles::EmitterConfig.new
      config.emission_rate = 0.0f32
      config.burst_count = 20
      config.emission_shape = PointClickEngine::Graphics::Particles::EmissionShape::Circle
      config.emission_radius = 5.0f32

      config.lifetime_min = 1.0f32
      config.lifetime_max = 2.0f32
      config.speed_min = 100.0f32
      config.speed_max = 200.0f32
      config.size_min = 2.0f32
      config.size_max = 4.0f32
      config.size_over_lifetime = true
      config.end_size_multiplier = 0.0f32

      config.direction = RL::Vector2.new(x: 0, y: 0)
      config.spread = 360.0f32
      config.gravity = RL::Vector2.new(x: 0, y: -50)

      config.rotation_speed_min = -360.0f32
      config.rotation_speed_max = 360.0f32

      config.start_color = colors[i]
      config.end_color = RL::Color.new(r: colors[i].r, g: colors[i].g, b: colors[i].b, a: 0)
      config.fade_out_time = 0.5f32

      emitter = PointClickEngine::Graphics::Particles::Emitter.new(@hero.position, config)
      emitter.burst
      emitter.stop
      @active_emitters << emitter
    end

    # Add pulse effect to hero
    @hero.add_effect("pulse", scale_amount: 0.3, speed: 5.0, duration: 0.5)
  end

  private def toggle_object_particles
    # Toggle particle effects on objects
    @sprites.each do |sprite|
      if sprite.effects.any? { |e| e.is_a?(PointClickEngine::Graphics::Effects::ParticleEffect) }
        sprite.clear_effects
      else
        case sprite.tint
        when RL::DARKBROWN
          sprite.add_effect("particle", type: "fire", follow: true, offset: [0, -20])
        when RL::GRAY
          sprite.add_effect("particle", type: "smoke", follow: true, offset: [0, -40])
        when RL::PURPLE
          sprite.add_effect("particle", type: "sparkles", follow: true)
        when RL::DARKGREEN
          sprite.add_effect("particle", type: "bubbles", follow: true, offset: [0, -25])
        end
      end
    end
  end

  private def create_click_effect(pos : RL::Vector2)
    # Create a random effect at click position
    effects = ["dust", "sparkles", "explosion", "bubbles"]
    effect_type = effects.sample

    emitter = case effect_type
              when "dust"
                PointClickEngine::Graphics::Particles.dust(pos)
              when "sparkles"
                PointClickEngine::Graphics::Particles.sparkles(pos, 30.0f32)
              when "explosion"
                PointClickEngine::Graphics::Particles.explosion(pos, 0.5f32)
              when "bubbles"
                PointClickEngine::Graphics::Particles.bubbles(pos, 20.0f32)
              else
                PointClickEngine::Graphics::Particles.sparkles(pos)
              end

    @active_emitters << emitter if emitter
  end

  private def clear_all_particles
    @active_emitters.clear
    @sprites.each(&.clear_effects)
    @hero.clear_effects
  end

  private def draw
    RL.begin_drawing
    RL.clear_background(RL::BLACK)

    @display.clear_screen

    @renderer.render do |context|
      @layers.render(@renderer.camera, @renderer) do |layer|
        case layer.name
        when "background"
          draw_background(context)
        when "scene"
          draw_scene(context)
          draw_particles(context)
        when "ui"
          draw_ui
        end
      end
    end

    draw_info

    RL.end_drawing
  end

  private def draw_background(context : PointClickEngine::Graphics::Core::RenderContext)
    # Dark gradient background
    RL.draw_rectangle_gradient_v(
      0, 0,
      PointClickEngine::Graphics::Display::REFERENCE_WIDTH,
      PointClickEngine::Graphics::Display::REFERENCE_HEIGHT,
      RL::Color.new(r: 10, g: 10, b: 30, a: 255),
      RL::Color.new(r: 30, g: 30, b: 50, a: 255)
    )

    # Ground
    context.draw_rectangle(0, 550, 1280, 170, RL::Color.new(r: 40, g: 30, b: 20, a: 255))
  end

  private def draw_scene(context : PointClickEngine::Graphics::Core::RenderContext)
    # Draw sprites with their particle effects
    @sprites.each do |sprite|
      sprite.draw_with_context(context)
      @effect_manager.apply_to_sprite(sprite.id, sprite, @renderer, RL.get_frame_time)
    end

    # Draw hero
    @hero.draw_with_context(context)
    @effect_manager.apply_to_sprite(@hero.id, @hero, @renderer, RL.get_frame_time)
  end

  private def draw_particles(context : PointClickEngine::Graphics::Core::RenderContext)
    # Draw standalone particle emitters
    @active_emitters.each { |e| e.draw_with_context(context) }
  end

  private def draw_ui
    # UI elements not affected by camera
  end

  private def draw_info
    y = 10
    RL.draw_text("Particle Effects Demo", 10, y, 24, RL::WHITE)
    y += 30

    RL.draw_text("Controls:", 10, y, 20, RL::YELLOW)
    y += 25
    RL.draw_text("WASD - Move hero", 10, y, 16, RL::GRAY)
    y += 20
    RL.draw_text("Left Click - Random effect", 10, y, 16, RL::GRAY)
    y += 20
    RL.draw_text("Right Click - Sparkle trail", 10, y, 16, RL::GRAY)
    y += 25

    RL.draw_text("Effects:", 10, y, 20, RL::YELLOW)
    y += 25
    RL.draw_text("1 - Explosion", 10, y, 16, RL::GRAY)
    y += 20
    RL.draw_text("2 - Toggle Fire", 10, y, 16, RL::GRAY)
    y += 20
    RL.draw_text("3 - Hit Spark", 10, y, 16, RL::GRAY)
    y += 20
    RL.draw_text("4 - Toggle Weather", 10, y, 16, RL::GRAY)
    y += 20
    RL.draw_text("5 - Magic Burst", 10, y, 16, RL::GRAY)
    y += 20
    RL.draw_text("6 - Toggle Object Effects", 10, y, 16, RL::GRAY)
    y += 20
    RL.draw_text("0 - Clear All", 10, y, 16, RL::GRAY)

    # Stats
    y = 400
    RL.draw_text("Active Emitters: #{@active_emitters.size}", 10, y, 18, RL::GREEN)
    y += 25

    particle_count = @active_emitters.sum(&.particle_count)
    particle_count += @sprites.sum do |sprite|
      sprite.effects.count { |e| e.is_a?(PointClickEngine::Graphics::Effects::ParticleEffect) }
    end

    RL.draw_text("Total Particles: ~#{particle_count}", 10, y, 16, RL::GRAY)
    y += 20

    stats = @effect_manager.stats
    RL.draw_text("Object Effects: #{stats[:total_object_effects]}", 10, y, 16, RL::GRAY)

    RL.draw_fps(1200, 10)
  end

  private def cleanup
    @renderer.cleanup
    RL.close_window
  end
end

# Run the demo
demo = ParticleEffectsDemo.new
demo.run
