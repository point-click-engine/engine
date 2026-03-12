# Graphics Module Showcase
# Demonstrates the new graphics system features

require "raylib-cr"
require "../src/graphics/graphics"

module GraphicsShowcase
  class Demo
    @display : PointClickEngine::Graphics::Display
    @renderer : PointClickEngine::Graphics::Renderer
    @layers : PointClickEngine::Graphics::LayerManager

    # Demo sprites
    @hero_sprite : PointClickEngine::Graphics::AnimatedSprite
    @item_sprite : PointClickEngine::Graphics::Sprite
    @ghost_sprite : PointClickEngine::Graphics::Sprite

    # Demo state
    @demo_time : Float32 = 0.0f32
    @current_demo : Int32 = 0
    @demo_names = [
      "Layer System",
      "Object Effects",
      "Sprite Animation",
      "Effect Combinations",
      "Camera Effects",
    ]

    def initialize
      # Initialize Raylib
      RL.init_window(1280, 720, "Graphics Module Showcase")
      RL.set_target_fps(60)

      # Initialize graphics components
      @display = PointClickEngine::Graphics::Display.new(1280, 720)
      @renderer = PointClickEngine::Graphics::Renderer.new(@display)
      @layers = PointClickEngine::Graphics::LayerManager.new
      @layers.add_default_layers

      # Create demo sprites
      @hero_sprite = create_hero_sprite
      @item_sprite = create_item_sprite
      @ghost_sprite = create_ghost_sprite

      setup_initial_effects
    end

    def run
      until RL.close_window?
        update
        draw
      end

      cleanup
    end

    private def create_hero_sprite : PointClickEngine::Graphics::AnimatedSprite
      # Create a simple colored rectangle as placeholder
      texture = RL.load_render_texture(64, 64)
      RL.begin_texture_mode(texture)
      RL.clear_background(RL::BLANK)
      RL.draw_rectangle(0, 0, 64, 64, RL::BLUE)
      RL.draw_rectangle(8, 8, 48, 48, RL::SKYBLUE)
      RL.end_texture_mode

      # Create animated sprite (single frame for demo)
      sprite = PointClickEngine::Graphics::AnimatedSprite.new("", 64, 64, 1)
      sprite.position = RL::Vector2.new(x: 400, y: 300)
      sprite.center_origin

      # Manually set texture (normally would load from file)
      # This is a hack for the demo
      sprite
    end

    private def create_item_sprite : PointClickEngine::Graphics::Sprite
      # Create a star shape
      texture = RL.load_render_texture(48, 48)
      RL.begin_texture_mode(texture)
      RL.clear_background(RL::BLANK)

      # Draw a simple star
      center = RL::Vector2.new(x: 24, y: 24)
      RL.draw_poly(center, 5, 20, 0, RL::GOLD)
      RL.draw_poly(center, 5, 15, 0, RL::YELLOW)

      RL.end_texture_mode

      sprite = PointClickEngine::Graphics::Sprite.new
      sprite.position = RL::Vector2.new(x: 600, y: 300)
      sprite.center_origin
      sprite
    end

    private def create_ghost_sprite : PointClickEngine::Graphics::Sprite
      # Create a ghost shape
      texture = RL.load_render_texture(64, 80)
      RL.begin_texture_mode(texture)
      RL.clear_background(RL::BLANK)

      # Draw ghost body
      RL.draw_circle(32, 32, 30, RL::Color.new(r: 200, g: 200, b: 255, a: 180))
      RL.draw_rectangle(2, 32, 60, 40, RL::Color.new(r: 200, g: 200, b: 255, a: 180))

      # Draw wavy bottom
      (0..6).each do |i|
        x = i * 10 + 2
        RL.draw_circle(x, 70, 5, RL::Color.new(r: 200, g: 200, b: 255, a: 180))
      end

      # Eyes
      RL.draw_circle(20, 30, 5, RL::BLACK)
      RL.draw_circle(44, 30, 5, RL::BLACK)

      RL.end_texture_mode

      sprite = PointClickEngine::Graphics::Sprite.new
      sprite.position = RL::Vector2.new(x: 800, y: 300)
      sprite.center_origin
      sprite
    end

    private def setup_initial_effects
      # Add initial effects to sprites
      @item_sprite.add_effect("pulse", scale_amount: 0.2, speed: 2.0)
      @item_sprite.add_effect("float", amplitude: 20, speed: 1.5)

      @ghost_sprite.add_effect("float", amplitude: 30, speed: 0.8, rotation: true)
      @ghost_sprite.add_effect("dissolve", mode: "in", duration: 2.0)
    end

    private def update
      dt = RL.get_frame_time
      @demo_time += dt

      # Switch demos with number keys
      (1..5).each do |i|
        if RL.key_pressed?(RL::KeyboardKey.from_value(48 + i)) # KEY_ONE + i - 1
          @current_demo = i - 1
          switch_demo(@current_demo)
        end
      end

      # Update sprites
      @hero_sprite.update(dt)
      @item_sprite.update(dt)
      @ghost_sprite.update(dt)

      # Update layers
      @layers.update(dt)

      # Demo-specific updates
      case @current_demo
      when 0 then update_layer_demo(dt)
      when 1 then update_effects_demo(dt)
      when 2 then update_animation_demo(dt)
      when 3 then update_combination_demo(dt)
      when 4 then update_camera_demo(dt)
      end
    end

    private def update_layer_demo(dt : Float32)
      # Animate layer properties
      if bg = @layers.background_layer
        bg.offset.x = Math.sin(@demo_time * 0.5) * 50
      end

      if fg = @layers.foreground_layer
        fg.opacity = (Math.sin(@demo_time * 2) + 1) * 0.5
      end
    end

    private def update_effects_demo(dt : Float32)
      # Cycle through effects on hero sprite
      cycle_time = (@demo_time % 12).to_i / 3

      @hero_sprite.clear_effects
      case cycle_time
      when 0
        @hero_sprite.add_effect("highlight", type: "glow", color: [255, 255, 0])
      when 1
        @hero_sprite.add_effect("shake", amplitude: 10, frequency: 15)
      when 2
        @hero_sprite.add_effect("color_shift", mode: "rainbow", speed: 2)
      when 3
        @hero_sprite.add_effect("pulse", scale_amount: 0.3, speed: 3, easing: "bounce")
      end
    end

    private def update_animation_demo(dt : Float32)
      # Simulate animation frames
      frame = ((@demo_time * 10).to_i % 8)
      @hero_sprite.set_frame(0) # Single frame in demo
    end

    private def update_combination_demo(dt : Float32)
      # Multiple effects at once
      if @demo_time.to_i % 5 == 0 && !@hero_sprite.has_effects?
        @hero_sprite.add_effect("highlight", type: "pulse", color: [100, 255, 100])
        @hero_sprite.add_effect("float", amplitude: 15, speed: 2)
        @hero_sprite.add_effect("shake", amplitude: 3, frequency: 20, direction: "horizontal")
      end
    end

    private def update_camera_demo(dt : Float32)
      # Camera shake effect
      if RL.key_pressed?(RL::KeyboardKey::Space)
        @renderer.camera.shake(20, 0.5)
      end

      # Camera movement
      @renderer.camera.position.x = Math.sin(@demo_time * 0.3) * 100
      @renderer.camera.position.y = Math.cos(@demo_time * 0.4) * 50
    end

    private def draw
      RL.begin_drawing
      RL.clear_background(RL::DARKGRAY)

      # Main game rendering
      @display.clear_screen(RL::BLACK)

      @renderer.render do |context|
        @layers.render(@renderer.camera, @renderer) do |layer|
          case layer.name
          when "background"
            draw_background(context)
          when "scene"
            draw_scene_objects(context)
          when "foreground"
            draw_foreground(context)
          when "ui"
            draw_ui(context)
          end
        end
      end

      # Draw demo info
      draw_demo_info

      RL.end_drawing
    end

    private def draw_background(context : PointClickEngine::Graphics::RenderContext)
      # Draw grid pattern
      grid_size = 50
      (0..20).each do |x|
        context.draw_line(
          RL::Vector2.new(x: x * grid_size, y: 0),
          RL::Vector2.new(x: x * grid_size, y: 768),
          RL::Color.new(r: 50, g: 50, b: 50, a: 100)
        )
      end

      (0..15).each do |y|
        context.draw_line(
          RL::Vector2.new(x: 0, y: y * grid_size),
          RL::Vector2.new(x: 1024, y: y * grid_size),
          RL::Color.new(r: 50, g: 50, b: 50, a: 100)
        )
      end
    end

    private def draw_scene_objects(context : PointClickEngine::Graphics::RenderContext)
      # Draw sprites with their effects
      @hero_sprite.draw_with_context(context)
      @item_sprite.draw_with_context(context)
      @ghost_sprite.draw_with_context(context)
    end

    private def draw_foreground(context : PointClickEngine::Graphics::RenderContext)
      # Draw some foreground elements
      context.draw_text("Foreground Layer", 50, 50, 20, RL::WHITE)
    end

    private def draw_ui(context : PointClickEngine::Graphics::RenderContext)
      # Draw UI elements
      context.draw_screen_space do
        RL.draw_text("UI Layer (Screen Space)", 10, 10, 16, RL::GREEN)
      end
    end

    private def draw_demo_info
      # Demo title
      RL.draw_text("Graphics Module Showcase", 10, 30, 30, RL::WHITE)
      RL.draw_text("Current Demo: #{@demo_names[@current_demo]}", 10, 70, 20, RL::YELLOW)

      # Controls
      y = 120
      RL.draw_text("Controls:", 10, y, 20, RL::LIGHTGRAY)
      y += 25
      RL.draw_text("1-5: Switch demos", 10, y, 16, RL::GRAY)
      y += 20
      RL.draw_text("Space: Trigger action (in Camera demo)", 10, y, 16, RL::GRAY)
      y += 20
      RL.draw_text("ESC: Exit", 10, y, 16, RL::GRAY)

      # Demo-specific info
      y = 250
      case @current_demo
      when 0
        RL.draw_text("Layer System Demo", 10, y, 18, RL::GREEN)
        RL.draw_text("- Background layer with parallax", 10, y + 25, 16, RL::GRAY)
        RL.draw_text("- Foreground layer with opacity animation", 10, y + 45, 16, RL::GRAY)
        RL.draw_text("- UI layer in screen space", 10, y + 65, 16, RL::GRAY)
      when 1
        RL.draw_text("Object Effects Demo", 10, y, 18, RL::GREEN)
        RL.draw_text("- Hero cycles through effects", 10, y + 25, 16, RL::GRAY)
        RL.draw_text("- Item has pulse + float", 10, y + 45, 16, RL::GRAY)
        RL.draw_text("- Ghost has float + dissolve", 10, y + 65, 16, RL::GRAY)
      when 2
        RL.draw_text("Animation Demo", 10, y, 18, RL::GREEN)
        RL.draw_text("- Frame-based animation", 10, y + 25, 16, RL::GRAY)
        RL.draw_text("- Animation events", 10, y + 45, 16, RL::GRAY)
      when 3
        RL.draw_text("Effect Combinations", 10, y, 18, RL::GREEN)
        RL.draw_text("- Multiple effects on one object", 10, y + 25, 16, RL::GRAY)
        RL.draw_text("- Effects work together", 10, y + 45, 16, RL::GRAY)
      when 4
        RL.draw_text("Camera Effects", 10, y, 18, RL::GREEN)
        RL.draw_text("- Press SPACE for camera shake", 10, y + 25, 16, RL::GRAY)
        RL.draw_text("- Smooth camera movement", 10, y + 45, 16, RL::GRAY)
      end

      # FPS
      RL.draw_fps(1200, 10)
    end

    private def switch_demo(index : Int32)
      # Clear all effects when switching demos
      @hero_sprite.clear_effects
      @item_sprite.clear_effects
      @ghost_sprite.clear_effects

      # Reset positions
      @hero_sprite.position = RL::Vector2.new(x: 400, y: 300)
      @item_sprite.position = RL::Vector2.new(x: 600, y: 300)
      @ghost_sprite.position = RL::Vector2.new(x: 800, y: 300)

      # Reset camera
      @renderer.camera.reset

      # Setup demo-specific effects
      case index
      when 0
        # Layer demo - no specific effects
      when 1
        # Effects demo
        @item_sprite.add_effect("pulse", scale_amount: 0.2, speed: 2.0)
        @item_sprite.add_effect("float", amplitude: 20, speed: 1.5)
        @ghost_sprite.add_effect("float", amplitude: 30, speed: 0.8, rotation: true)
        @ghost_sprite.add_effect("dissolve", mode: "in", duration: 2.0)
      when 2
        # Animation demo
        @hero_sprite.play
      when 3
        # Combination demo
        # Effects added dynamically
      when 4
        # Camera demo
        @item_sprite.add_effect("highlight", type: "glow", color: [255, 200, 100])
      end
    end

    private def cleanup
      @renderer.cleanup
      RL.close_window
    end
  end
end

# Run the demo
demo = GraphicsShowcase::Demo.new
demo.run
