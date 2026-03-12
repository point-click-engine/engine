# Camera Effects Demo - Shows various camera effects

require "raylib-cr"
require "../src/graphics/graphics"

class CameraEffectsDemo
  @display : PointClickEngine::Graphics::Display
  @renderer : PointClickEngine::Graphics::Renderer
  @layers : PointClickEngine::Graphics::LayerManager
  @effect_manager : PointClickEngine::Graphics::Effects::EffectManager

  @sprites : Array(PointClickEngine::Graphics::Sprite)
  @world_bounds : RL::Rectangle
  @hero : PointClickEngine::Graphics::Sprite

  def initialize
    RL.init_window(1280, 720, "Camera Effects Demo")
    RL.set_target_fps(60)

    @display = PointClickEngine::Graphics::Display.new(1280, 720)
    @renderer = PointClickEngine::Graphics::Renderer.new(@display)
    @layers = PointClickEngine::Graphics::LayerManager.new
    @layers.add_default_layers
    @effect_manager = PointClickEngine::Graphics::Effects::EffectManager.new

    # Set up a larger world
    @world_bounds = RL::Rectangle.new(x: 0, y: 0, width: 2000, height: 1500)

    # Create test scene
    @sprites = create_test_scene
    @hero = create_hero

    # Set camera bounds
    @renderer.camera.set_bounds(@world_bounds)

    # Start with follow effect on hero
    setup_initial_camera
  end

  def run
    until RL.close_window?
      update
      draw
    end

    cleanup
  end

  private def create_test_scene : Array(PointClickEngine::Graphics::Sprite)
    sprites = [] of PointClickEngine::Graphics::Sprite

    # Create a grid of objects across the world
    colors = [RL::RED, RL::GREEN, RL::BLUE, RL::YELLOW, RL::PURPLE, RL::ORANGE]

    10.times do |x|
      8.times do |y|
        sprite = create_colored_sprite(colors[(x + y) % colors.size], 40)
        sprite.position = RL::Vector2.new(
          x: 100 + x * 180,
          y: 100 + y * 160
        )
        sprites << sprite
      end
    end

    # Add some decorative elements
    20.times do
      decoration = create_colored_sprite(RL::DARKGRAY, Random.rand(20..60))
      decoration.position = RL::Vector2.new(
        x: Random.rand(0..@world_bounds.width.to_i),
        y: Random.rand(0..@world_bounds.height.to_i)
      )
      decoration.opacity = 0.5f32
      sprites << decoration
    end

    sprites
  end

  private def create_hero : PointClickEngine::Graphics::Sprite
    hero = PointClickEngine::Graphics::Sprite.new
    hero.tint = RL::WHITE
    hero.scale = 1.5f32
    hero.position = RL::Vector2.new(x: 640, y: 360)
    hero.center_origin
    hero
  end

  private def create_colored_sprite(color : RL::Color, size : Int32) : PointClickEngine::Graphics::Sprite
    sprite = PointClickEngine::Graphics::Sprite.new
    sprite.tint = color
    sprite.scale = size / 64.0f32 # Assuming 64x64 base size
    sprite.center_origin
    sprite
  end

  private def setup_initial_camera
    # Start with camera following the hero
    @effect_manager.add_camera_effect("follow",
      target: [@hero.position.x, @hero.position.y],
      deadzone_width: 200,
      deadzone_height: 150,
      follow_speed: 5.0
    )

    # Add subtle sway
    @effect_manager.add_camera_effect("sway",
      amplitude_x: 3,
      amplitude_y: 2,
      frequency_x: 0.3,
      frequency_y: 0.2
    )
  end

  private def update
    dt = RL.get_frame_time

    # Update hero movement
    update_hero_movement(dt)

    # Update effects
    @effect_manager.update(dt)

    # Apply camera effects
    @effect_manager.apply_to_renderer(@renderer, dt)

    # Update sprites
    @sprites.each(&.update(dt))
    @hero.update(dt)

    # Handle input for camera effect demos
    handle_input
  end

  private def update_hero_movement(dt : Float32)
    speed = 300.0f32

    # WASD movement
    if RL.key_down?(RL::KeyboardKey::W)
      @hero.position.y -= speed * dt
    end
    if RL.key_down?(RL::KeyboardKey::S)
      @hero.position.y += speed * dt
    end
    if RL.key_down?(RL::KeyboardKey::A)
      @hero.position.x -= speed * dt
    end
    if RL.key_down?(RL::KeyboardKey::D)
      @hero.position.x += speed * dt
    end

    # Keep hero in bounds
    @hero.position.x = @hero.position.x.clamp(50, @world_bounds.width - 50)
    @hero.position.y = @hero.position.y.clamp(50, @world_bounds.height - 50)

    # Update follow target
    if follow = @effect_manager.@camera_effects.active_effects.find { |e| e.is_a?(PointClickEngine::Graphics::Effects::CameraEffects::FollowEffect) }
      follow = follow.as(PointClickEngine::Graphics::Effects::CameraEffects::FollowEffect)
      follow.target = @hero.position
    end
  end

  private def handle_input
    # Number keys for different camera effects
    if RL.key_pressed?(RL::KeyboardKey::One)
      apply_camera_shake
    elsif RL.key_pressed?(RL::KeyboardKey::Two)
      apply_camera_pan
    elsif RL.key_pressed?(RL::KeyboardKey::Three)
      apply_camera_zoom_in
    elsif RL.key_pressed?(RL::KeyboardKey::Four)
      apply_camera_zoom_out
    elsif RL.key_pressed?(RL::KeyboardKey::Five)
      apply_camera_float
    elsif RL.key_pressed?(RL::KeyboardKey::Six)
      apply_camera_pulse
    elsif RL.key_pressed?(RL::KeyboardKey::Seven)
      toggle_follow_mode
    elsif RL.key_pressed?(RL::KeyboardKey::Eight)
      apply_dramatic_zoom
    elsif RL.key_pressed?(RL::KeyboardKey::Zero)
      reset_camera
    end
  end

  private def apply_camera_shake
    @effect_manager.add_camera_effect("shake",
      amplitude: 20,
      frequency: 15,
      duration: 0.5
    )
  end

  private def apply_camera_pan
    # Pan to a random object
    if target = @sprites.sample
      @effect_manager.add_camera_effect("pan",
        target: [target.position.x - 640, target.position.y - 360], # Adjust for center
        duration: 2.0,
        easing: "ease_in_out_cubic"
      )
    end
  end

  private def apply_camera_zoom_in
    current_zoom = @renderer.camera.zoom
    @effect_manager.add_camera_effect("zoom",
      target: current_zoom * 1.5,
      duration: 1.0,
      center: [@hero.position.x, @hero.position.y]
    )
  end

  private def apply_camera_zoom_out
    current_zoom = @renderer.camera.zoom
    @effect_manager.add_camera_effect("zoom",
      target: (current_zoom * 0.7).clamp(0.5, 2.0),
      duration: 1.0
    )
  end

  private def apply_camera_float
    @effect_manager.add_camera_effect("float",
      amplitude: 30,
      speed: 0.5,
      duration: 5.0
    )
  end

  private def apply_camera_pulse
    @effect_manager.add_camera_effect("pulse",
      zoom_amount: 0.05,
      speed: 2.0,
      duration: 3.0
    )
  end

  private def toggle_follow_mode
    # Clear all camera effects
    @effect_manager.@camera_effects.clear_effects

    # Toggle between follow and free camera
    if @renderer.camera.position.x.abs < 10 # Assume we're in follow mode
      # Switch to free camera
      @effect_manager.add_camera_effect("sway",
        amplitude_x: 5,
        amplitude_y: 3,
        frequency_x: 0.2,
        frequency_y: 0.15
      )
    else
      # Switch back to follow
      setup_initial_camera
    end
  end

  private def apply_dramatic_zoom
    # Combine multiple effects for dramatic moment
    @effect_manager.add_camera_effect("zoom",
      target: 1.8,
      duration: 0.5,
      center: [@hero.position.x, @hero.position.y],
      easing: "ease_out_cubic"
    )

    @effect_manager.add_camera_effect("shake",
      amplitude: 5,
      frequency: 20,
      duration: 0.3
    )
  end

  private def reset_camera
    @effect_manager.@camera_effects.clear_effects
    @renderer.camera.zoom = 1.0f32
    setup_initial_camera
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
        when "ui"
          draw_ui
        end
      end
    end

    draw_info

    RL.end_drawing
  end

  private def draw_background(context : PointClickEngine::Graphics::Core::RenderContext)
    # Draw world bounds
    context.draw_rectangle_lines(
      @world_bounds.x.to_i,
      @world_bounds.y.to_i,
      @world_bounds.width.to_i,
      @world_bounds.height.to_i,
      RL::DARKGREEN
    )

    # Grid
    grid_size = 100
    (@world_bounds.width / grid_size).to_i.times do |x|
      context.draw_line(
        RL::Vector2.new(x: x * grid_size, y: 0),
        RL::Vector2.new(x: x * grid_size, y: @world_bounds.height),
        RL::Color.new(r: 40, g: 40, b: 40, a: 255)
      )
    end

    (@world_bounds.height / grid_size).to_i.times do |y|
      context.draw_line(
        RL::Vector2.new(x: 0, y: y * grid_size),
        RL::Vector2.new(x: @world_bounds.width, y: y * grid_size),
        RL::Color.new(r: 40, g: 40, b: 40, a: 255)
      )
    end
  end

  private def draw_scene(context : PointClickEngine::Graphics::Core::RenderContext)
    # Draw all sprites
    @sprites.each do |sprite|
      sprite.draw_with_context(context)
    end

    # Draw hero with a marker
    @hero.draw_with_context(context)

    # Draw hero marker
    context.draw_circle_lines(
      @hero.position.x.to_i,
      @hero.position.y.to_i,
      50,
      RL::YELLOW
    )
  end

  private def draw_ui
    # UI is in screen space, not affected by camera
  end

  private def draw_info
    y = 10
    RL.draw_text("Camera Effects Demo", 10, y, 24, RL::WHITE)
    y += 30

    RL.draw_text("Movement: WASD", 10, y, 18, RL::YELLOW)
    y += 25

    RL.draw_text("Camera Effects:", 10, y, 20, RL::YELLOW)
    y += 25
    RL.draw_text("1 - Shake", 10, y, 16, RL::GRAY)
    y += 20
    RL.draw_text("2 - Pan to Random Object", 10, y, 16, RL::GRAY)
    y += 20
    RL.draw_text("3 - Zoom In (at hero)", 10, y, 16, RL::GRAY)
    y += 20
    RL.draw_text("4 - Zoom Out", 10, y, 16, RL::GRAY)
    y += 20
    RL.draw_text("5 - Float", 10, y, 16, RL::GRAY)
    y += 20
    RL.draw_text("6 - Pulse", 10, y, 16, RL::GRAY)
    y += 20
    RL.draw_text("7 - Toggle Follow Mode", 10, y, 16, RL::GRAY)
    y += 20
    RL.draw_text("8 - Dramatic Zoom", 10, y, 16, RL::GRAY)
    y += 20
    RL.draw_text("0 - Reset Camera", 10, y, 16, RL::GRAY)

    # Camera info
    y = 400
    RL.draw_text("Camera Info:", 10, y, 18, RL::GREEN)
    y += 25
    cam = @renderer.camera
    RL.draw_text("Position: #{cam.position.x.to_i}, #{cam.position.y.to_i}", 10, y, 16, RL::GRAY)
    y += 20
    RL.draw_text("Zoom: #{cam.zoom.round(2)}", 10, y, 16, RL::GRAY)
    y += 20

    # Active effects
    stats = @effect_manager.stats
    RL.draw_text("Camera Effects: #{stats[:camera_effects]}", 10, y, 16, RL::GRAY)

    # Hero position
    y += 30
    RL.draw_text("Hero: #{@hero.position.x.to_i}, #{@hero.position.y.to_i}", 10, y, 16, RL::YELLOW)

    RL.draw_fps(1200, 10)
  end

  private def cleanup
    @renderer.cleanup
    RL.close_window
  end
end

# Run the demo
demo = CameraEffectsDemo.new
demo.run
