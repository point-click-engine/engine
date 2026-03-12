# Transition Effects Demo - Shows scene transitions integrated with effects system

require "raylib-cr"
require "../src/graphics/graphics"

class TransitionEffectsDemo
  @display : PointClickEngine::Graphics::Display
  @renderer : PointClickEngine::Graphics::Renderer
  @layers : PointClickEngine::Graphics::LayerManager
  @effect_manager : PointClickEngine::Graphics::Effects::EffectManager
  
  @scene_sprites : Array(PointClickEngine::Graphics::Sprite)
  @current_scene : Int32 = 0
  @transitioning : Bool = false
  
  # Available transitions
  TRANSITIONS = [
    "fade", "dissolve", "slide_left", "slide_right", "slide_up", "slide_down",
    "iris", "pixelate", "swirl", "checkerboard", "star_wipe", "curtain",
    "ripple", "warp", "wave", "cross_fade"
  ]
  
  def initialize
    RL.init_window(1280, 720, "Transition Effects Demo")
    RL.set_target_fps(60)
    
    @display = PointClickEngine::Graphics::Display.new(1280, 720)
    @renderer = PointClickEngine::Graphics::Renderer.new(@display)
    @layers = PointClickEngine::Graphics::LayerManager.new
    @layers.add_default_layers
    @effect_manager = PointClickEngine::Graphics::Effects::EffectManager.new
    
    # Create initial scene
    @scene_sprites = create_scene(@current_scene)
  end
  
  def run
    until RL.close_window?
      update
      draw
    end
    
    cleanup
  end
  
  private def create_scene(scene_number : Int32) : Array(PointClickEngine::Graphics::Sprite)
    sprites = [] of PointClickEngine::Graphics::Sprite
    
    case scene_number % 3
    when 0
      # Scene 1: Colorful circles
      create_circle_scene(sprites)
    when 1
      # Scene 2: Grid pattern
      create_grid_scene(sprites)
    when 2
      # Scene 3: Random shapes
      create_shapes_scene(sprites)
    end
    
    sprites
  end
  
  private def create_circle_scene(sprites : Array(PointClickEngine::Graphics::Sprite))
    colors = [RL::RED, RL::GREEN, RL::BLUE, RL::YELLOW, RL::PURPLE, RL::ORANGE]
    
    # Create concentric circles
    5.times do |ring|
      circle_count = 6 + ring * 3
      circle_count.times do |i|
        angle = (i.to_f / circle_count) * Math::PI * 2
        radius = 100 + ring * 60
        
        sprite = create_colored_sprite(colors[ring % colors.size], 40 - ring * 5)
        sprite.position = RL::Vector2.new(
          x: 640 + Math.cos(angle).to_f32 * radius,
          y: 360 + Math.sin(angle).to_f32 * radius
        )
        
        # Add floating effect
        sprite.add_effect("float", amplitude: 10, speed: 0.5 + i * 0.1, phase: angle)
        
        sprites << sprite
      end
    end
  end
  
  private def create_grid_scene(sprites : Array(PointClickEngine::Graphics::Sprite))
    colors = [RL::DARKGREEN, RL::DARKBLUE, RL::DARKPURPLE, RL::MAROON]
    
    # Create grid
    8.times do |x|
      6.times do |y|
        color_index = (x + y) % colors.size
        sprite = create_colored_sprite(colors[color_index], 60)
        sprite.position = RL::Vector2.new(
          x: 200 + x * 100,
          y: 120 + y * 80
        )
        
        # Add pulse effect
        sprite.add_effect("pulse", scale_amount: 0.1, speed: 1.0, phase: (x + y) * 0.2)
        
        sprites << sprite
      end
    end
  end
  
  private def create_shapes_scene(sprites : Array(PointClickEngine::Graphics::Sprite))
    colors = [RL::GOLD, RL::SKYBLUE, RL::PINK, RL::LIME, RL::VIOLET]
    
    # Create random positioned shapes
    30.times do |i|
      sprite = create_colored_sprite(colors[i % colors.size], Random.rand(30..80))
      sprite.position = RL::Vector2.new(
        x: Random.rand(100..1180),
        y: Random.rand(100..620)
      )
      sprite.rotation = Random.rand(0..360).to_f32
      
      # Random effect
      case Random.rand(3)
      when 0
        sprite.add_effect("highlight", mode: "glow", color: [255, 255, 255])
      when 1
        sprite.add_effect("color", mode: "rainbow", speed: 2.0)
      when 2
        sprite.add_effect("shake", amplitude: 3, frequency: 10)
      end
      
      sprites << sprite
    end
  end
  
  private def create_colored_sprite(color : RL::Color, size : Int32) : PointClickEngine::Graphics::Sprite
    sprite = PointClickEngine::Graphics::Sprite.new
    sprite.tint = color
    sprite.scale = size / 64.0f32  # Assuming 64x64 base size
    sprite.center_origin
    sprite
  end
  
  private def update
    dt = RL.get_frame_time
    
    # Update effects
    @effect_manager.update(dt)
    
    # Update sprites
    @scene_sprites.each(&.update(dt))
    
    # Handle input
    handle_input
  end
  
  private def handle_input
    return if @transitioning
    
    # Number keys for specific transitions
    if RL.key_pressed?(RL::KeyboardKey::One)
      start_transition("fade")
    elsif RL.key_pressed?(RL::KeyboardKey::Two)
      start_transition("dissolve")
    elsif RL.key_pressed?(RL::KeyboardKey::Three)
      start_transition("slide_left")
    elsif RL.key_pressed?(RL::KeyboardKey::Four)
      start_transition("iris")
    elsif RL.key_pressed?(RL::KeyboardKey::Five)
      start_transition("pixelate")
    elsif RL.key_pressed?(RL::KeyboardKey::Six)
      start_transition("swirl")
    elsif RL.key_pressed?(RL::KeyboardKey::Seven)
      start_transition("ripple")
    elsif RL.key_pressed?(RL::KeyboardKey::Eight)
      start_transition("warp")
    elsif RL.key_pressed?(RL::KeyboardKey::Nine)
      start_transition("checkerboard")
    elsif RL.key_pressed?(RL::KeyboardKey::Zero)
      start_transition("cross_fade")
    end
    
    # Space for random transition
    if RL.key_pressed?(RL::KeyboardKey::Space)
      start_transition(TRANSITIONS.sample)
    end
    
    # R for reverse (out) transition
    if RL.key_pressed?(RL::KeyboardKey::R)
      start_transition(TRANSITIONS.sample, reverse: true)
    end
  end
  
  private def start_transition(effect_name : String, reverse : Bool = false)
    @transitioning = true
    
    # Add transition effect
    if transition = @effect_manager.add_scene_effect(effect_name, 
                                                    duration: 1.5,
                                                    reverse: reverse)
      # Set callback to change scene at 50%
      if transition.responds_to?(:on_scene_change)
        transition.on_scene_change do
          change_scene unless reverse
        end
      end
      
      # Monitor transition completion
      spawn do
        while @effect_manager.@scene_effects.active_effects.includes?(transition)
          sleep 0.1
        end
        @transitioning = false
        change_scene if reverse
      end
    else
      # Fallback if transition creation failed
      @transitioning = false
      change_scene
    end
  end
  
  private def change_scene
    # Clear current scene effects
    @scene_sprites.each(&.clear_effects)
    
    # Move to next scene
    @current_scene += 1
    @scene_sprites = create_scene(@current_scene)
  end
  
  private def draw
    RL.begin_drawing
    RL.clear_background(RL::BLACK)
    
    @display.clear_screen
    
    # Check for active transition
    active_transition = find_active_transition
    
    if active_transition && transition_manager = active_transition.transition_manager
      # Render with transition
      transition_manager.render_with_transition do
        render_scene
      end
      
      # Draw any overlay effects
      active_transition.render_overlay
    else
      # Normal rendering
      render_scene
    end
    
    draw_info
    
    RL.end_drawing
  end
  
  private def render_scene
    @renderer.render do |context|
      @layers.render(@renderer.camera, @renderer) do |layer|
        case layer.name
        when "background"
          draw_background(context)
        when "scene"
          draw_sprites(context)
        when "ui"
          # UI not affected by transitions
        end
      end
    end
  end
  
  private def find_active_transition : PointClickEngine::Graphics::Effects::SceneEffects::TransitionAdapter?
    @effect_manager.@scene_effects.active_effects.each do |effect|
      if transition = effect.as?(PointClickEngine::Graphics::Effects::SceneEffects::TransitionAdapter)
        return transition
      end
    end
    nil
  end
  
  private def draw_background(context : PointClickEngine::Graphics::Core::RenderContext)
    # Simple gradient background
    RL.draw_rectangle_gradient_v(
      0, 0, 
      PointClickEngine::Graphics::Display::REFERENCE_WIDTH,
      PointClickEngine::Graphics::Display::REFERENCE_HEIGHT,
      RL::Color.new(r: 20, g: 20, b: 40, a: 255),
      RL::Color.new(r: 40, g: 40, b: 80, a: 255)
    )
  end
  
  private def draw_sprites(context : PointClickEngine::Graphics::Core::RenderContext)
    @scene_sprites.each do |sprite|
      # Apply object effects
      @effect_manager.apply_to_sprite(sprite.id, sprite, @renderer, RL.get_frame_time)
    end
  end
  
  private def draw_info
    y = 10
    RL.draw_text("Transition Effects Demo", 10, y, 24, RL::WHITE)
    y += 30
    
    RL.draw_text("Scene: #{@current_scene}", 10, y, 18, RL::YELLOW)
    y += 25
    
    if @transitioning
      RL.draw_text("TRANSITIONING...", 10, y, 20, RL::GREEN)
      y += 25
    end
    
    y += 10
    RL.draw_text("Transitions:", 10, y, 20, RL::YELLOW)
    y += 25
    RL.draw_text("1 - Fade", 10, y, 16, RL::GRAY)
    y += 20
    RL.draw_text("2 - Dissolve", 10, y, 16, RL::GRAY)
    y += 20
    RL.draw_text("3 - Slide Left", 10, y, 16, RL::GRAY)
    y += 20
    RL.draw_text("4 - Iris", 10, y, 16, RL::GRAY)
    y += 20
    RL.draw_text("5 - Pixelate", 10, y, 16, RL::GRAY)
    y += 20
    RL.draw_text("6 - Swirl", 10, y, 16, RL::GRAY)
    y += 20
    RL.draw_text("7 - Ripple", 10, y, 16, RL::GRAY)
    y += 20
    RL.draw_text("8 - Warp", 10, y, 16, RL::GRAY)
    y += 20
    RL.draw_text("9 - Checkerboard", 10, y, 16, RL::GRAY)
    y += 20
    RL.draw_text("0 - Cross Fade", 10, y, 16, RL::GRAY)
    y += 20
    RL.draw_text("Space - Random", 10, y, 16, RL::GRAY)
    y += 20
    RL.draw_text("R - Random Reverse", 10, y, 16, RL::GRAY)
    
    # Active effects
    stats = @effect_manager.stats
    y = 550
    RL.draw_text("Active Effects:", 10, y, 18, RL::GREEN)
    y += 25
    RL.draw_text("Scene: #{stats[:scene_effects]}", 10, y, 16, RL::GRAY)
    y += 20
    RL.draw_text("Objects: #{stats[:total_object_effects]}", 10, y, 16, RL::GRAY)
    
    RL.draw_fps(1200, 10)
  end
  
  private def cleanup
    @renderer.cleanup
    RL.close_window
  end
end

# Run the demo
demo = TransitionEffectsDemo.new
demo.run