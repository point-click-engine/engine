# Scene Effects Demo - Shows how object effects can be reused for scenes

require "raylib-cr"
require "../src/graphics/graphics"

class SceneEffectsDemo
  @display : PointClickEngine::Graphics::Display
  @renderer : PointClickEngine::Graphics::Renderer
  @layers : PointClickEngine::Graphics::LayerManager
  @effect_manager : PointClickEngine::Graphics::Effects::EffectManager

  @sprites : Array(PointClickEngine::Graphics::Sprite)
  @demo_time : Float32 = 0.0f32

  def initialize
    RL.init_window(1280, 720, "Scene Effects Demo - Object Effects Reused")
    RL.set_target_fps(60)

    @display = PointClickEngine::Graphics::Display.new(1280, 720)
    @renderer = PointClickEngine::Graphics::Renderer.new(@display)
    @layers = PointClickEngine::Graphics::LayerManager.new
    @layers.add_default_layers
    @effect_manager = PointClickEngine::Graphics::Effects::EffectManager.new

    # Create some test sprites
    @sprites = create_test_sprites

    # Set up initial scene effects
    setup_scene_effects
  end

  def run
    until RL.close_window?
      update
      draw
    end

    cleanup
  end

  private def create_test_sprites : Array(PointClickEngine::Graphics::Sprite)
    sprites = [] of PointClickEngine::Graphics::Sprite

    # Create a grid of colored squares
    colors = [RL::RED, RL::GREEN, RL::BLUE, RL::YELLOW, RL::PURPLE, RL::ORANGE]

    6.times do |i|
      4.times do |j|
        sprite = create_colored_sprite(colors[i % colors.size], 48)
        sprite.position = RL::Vector2.new(
          x: 200 + i * 120,
          y: 150 + j * 120
        )
        sprites << sprite
      end
    end

    sprites
  end

  private def create_colored_sprite(color : RL::Color, size : Int32) : PointClickEngine::Graphics::Sprite
    sprite = PointClickEngine::Graphics::Sprite.new
    sprite.tint = color
    sprite.scale = size / 64.0f32 # Assuming 64x64 base size
    sprite.center_origin
    sprite
  end

  private def setup_scene_effects
    # Start with fog effect
    @effect_manager.add_scene_effect("fog", density: 0.3, speed: 15.0)
  end

  private def update
    dt = RL.get_frame_time
    @demo_time += dt

    # Update effects
    @effect_manager.update(dt)

    # Update sprites
    @sprites.each(&.update(dt))

    # Handle input for effect demos
    handle_input

    # Cycle through effects automatically
    cycle_effects if (@demo_time % 10).to_i == 0 && @demo_time - @demo_time.to_i < dt
  end

  private def handle_input
    # Number keys to trigger different effects
    if RL.key_pressed?(RL::KeyboardKey::One)
      apply_scene_shake
    elsif RL.key_pressed?(RL::KeyboardKey::Two)
      apply_scene_color_shift
    elsif RL.key_pressed?(RL::KeyboardKey::Three)
      apply_fog_effect
    elsif RL.key_pressed?(RL::KeyboardKey::Four)
      apply_rain_effect
    elsif RL.key_pressed?(RL::KeyboardKey::Five)
      apply_darkness_effect
    elsif RL.key_pressed?(RL::KeyboardKey::Six)
      apply_underwater_effect
    elsif RL.key_pressed?(RL::KeyboardKey::Seven)
      apply_combined_effects
    elsif RL.key_pressed?(RL::KeyboardKey::Zero)
      clear_all_effects
    end

    # Apply object effects to individual sprites
    if RL.key_pressed?(RL::KeyboardKey::Q)
      @sprites.sample(3).each do |sprite|
        sprite.add_effect("pulse", scale_amount: 0.3, speed: 2.0)
      end
    elsif RL.key_pressed?(RL::KeyboardKey::W)
      @sprites.sample(3).each do |sprite|
        sprite.add_effect("float", amplitude: 20, speed: 1.5)
      end
    end
  end

  private def apply_scene_shake
    clear_scene_effects
    @effect_manager.add_scene_effect("shake", amplitude: 15, frequency: 10, duration: 1.0)
  end

  private def apply_scene_color_shift
    clear_scene_effects
    @effect_manager.add_scene_effect("tint",
      mode: "sepia",
      duration: 0.0, # Permanent
      layers: ["scene", "background"]
    )
  end

  private def apply_fog_effect
    clear_scene_effects
    @effect_manager.add_scene_effect("fog",
      density: 0.5,
      speed: 20.0,
      color: [180, 180, 200]
    )
  end

  private def apply_rain_effect
    clear_scene_effects
    @effect_manager.add_scene_effect("rain",
      intensity: 0.7,
      wind_speed: -30.0
    )
  end

  private def apply_darkness_effect
    clear_scene_effects
    darkness = @effect_manager.add_scene_effect("darkness", intensity: 0.8)

    # Add some light sources
    if darkness && darkness.is_a?(PointClickEngine::Graphics::Effects::SceneEffects::DarknessEffect)
      darkness.add_light(RL::Vector2.new(x: 300, y: 300), 150, RL::YELLOW, true)
      darkness.add_light(RL::Vector2.new(x: 700, y: 400), 100, RL::ORANGE, false)
    end
  end

  private def apply_underwater_effect
    clear_scene_effects
    @effect_manager.add_scene_effect("underwater",
      wave_amplitude: 0.03,
      bubble_count: 30
    )
  end

  private def apply_combined_effects
    clear_scene_effects
    # Combine multiple effects
    @effect_manager.add_scene_effect("fog", density: 0.2)
    @effect_manager.add_scene_effect("color", mode: "tint", color: [100, 150, 200])

    # Also add some object effects
    @sprites.each_with_index do |sprite, i|
      sprite.add_effect("float",
        amplitude: 10 + i * 2,
        speed: 0.5 + i * 0.1,
        phase: i * 0.2
      )
    end
  end

  private def clear_scene_effects
    @effect_manager.clear_all
  end

  private def clear_all_effects
    clear_scene_effects
    @sprites.each(&.clear_effects)
  end

  private def cycle_effects
    effects = ["fog", "rain", "darkness", "underwater", "shake", "color"]
    index = (@demo_time.to_i / 10) % effects.size

    case effects[index]
    when "fog"        then apply_fog_effect
    when "rain"       then apply_rain_effect
    when "darkness"   then apply_darkness_effect
    when "underwater" then apply_underwater_effect
    when "shake"      then apply_scene_shake
    when "color"      then apply_scene_color_shift
    end
  end

  private def draw
    RL.begin_drawing
    RL.clear_background(RL::BLACK)

    @display.clear_screen

    # Apply scene effects to layers before rendering
    @effect_manager.apply_scene_effects(@renderer, @layers, RL.get_frame_time)

    @renderer.render do |context|
      @layers.render(@renderer.camera, @renderer) do |layer|
        case layer.name
        when "background"
          draw_background(context)
        when "scene"
          draw_sprites(context)
        when "ui"
          draw_ui
        end
      end

      # Draw scene effect overlays
      @effect_manager.draw_scene_overlays(@renderer)
    end

    draw_info

    RL.end_drawing
  end

  private def draw_background(context : PointClickEngine::Graphics::Core::RenderContext)
    # Simple grid background
    (0..20).each do |x|
      context.draw_line(
        RL::Vector2.new(x: x * 50, y: 0),
        RL::Vector2.new(x: x * 50, y: 768),
        RL::DARKGRAY
      )
    end

    (0..15).each do |y|
      context.draw_line(
        RL::Vector2.new(x: 0, y: y * 50),
        RL::Vector2.new(x: 1024, y: y * 50),
        RL::DARKGRAY
      )
    end
  end

  private def draw_sprites(context : PointClickEngine::Graphics::Core::RenderContext)
    @sprites.each do |sprite|
      # Apply object effects through effect manager
      @effect_manager.apply_to_sprite(sprite.id, sprite, @renderer, RL.get_frame_time)
    end
  end

  private def draw_ui
    # UI is not affected by scene effects
  end

  private def draw_info
    y = 10
    RL.draw_text("Scene Effects Demo - Object Effects Reused", 10, y, 24, RL::WHITE)
    y += 30

    RL.draw_text("Scene Effects:", 10, y, 20, RL::YELLOW)
    y += 25
    RL.draw_text("1 - Scene Shake", 10, y, 16, RL::GRAY)
    y += 20
    RL.draw_text("2 - Scene Color (Sepia)", 10, y, 16, RL::GRAY)
    y += 20
    RL.draw_text("3 - Fog", 10, y, 16, RL::GRAY)
    y += 20
    RL.draw_text("4 - Rain", 10, y, 16, RL::GRAY)
    y += 20
    RL.draw_text("5 - Darkness with Lights", 10, y, 16, RL::GRAY)
    y += 20
    RL.draw_text("6 - Underwater", 10, y, 16, RL::GRAY)
    y += 20
    RL.draw_text("7 - Combined Effects", 10, y, 16, RL::GRAY)
    y += 20
    RL.draw_text("0 - Clear All", 10, y, 16, RL::GRAY)

    y += 30
    RL.draw_text("Object Effects:", 10, y, 20, RL::YELLOW)
    y += 25
    RL.draw_text("Q - Random Pulse", 10, y, 16, RL::GRAY)
    y += 20
    RL.draw_text("W - Random Float", 10, y, 16, RL::GRAY)

    # Stats
    stats = @effect_manager.stats
    y = 400
    RL.draw_text("Active Effects:", 10, y, 18, RL::GREEN)
    y += 25
    RL.draw_text("Scene: #{stats[:scene_effects]}", 10, y, 16, RL::GRAY)
    y += 20
    RL.draw_text("Objects: #{stats[:total_object_effects]} (#{stats[:objects_with_effects]} objects)", 10, y, 16, RL::GRAY)

    RL.draw_fps(1200, 10)
  end

  private def cleanup
    @renderer.cleanup
    RL.close_window
  end
end

# Run the demo
demo = SceneEffectsDemo.new
demo.run
