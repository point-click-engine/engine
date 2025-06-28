require "../src/point_click_engine"

# Simple test without external assets
module SimpleGraphicsTest
  include PointClickEngine

  def self.run
    # Initialize Raylib window
    RL.init_window(800, 600, "Simple Graphics Test")
    RL.set_target_fps(60)

    # Initialize display
    display = Graphics::Display.new(800, 600)
    display.scaling_mode = Graphics::Display::ScalingMode::FitWithBars

    # Create renderer
    renderer = Graphics::Renderer.new(display)

    # Create a particle emitter config
    config = Graphics::Particles::EmitterConfig.new
    config.emission_rate = 30.0f32
    config.lifetime_min = 2.0f32
    config.lifetime_max = 3.0f32
    config.start_color = RL::YELLOW
    config.end_color = RL::Color.new(r: 255, g: 100, b: 0, a: 0)
    config.size_min = 4.0f32
    config.size_max = 6.0f32

    # Create a particle emitter
    emitter = Graphics::Particles::Emitter.new(
      RL::Vector2.new(x: 400, y: 300),
      config
    )

    # Create a layer manager
    layer_manager = Graphics::Layers::LayerManager.new
    background_layer = Graphics::Layers::BackgroundLayer.new("background")
    scene_layer = Graphics::Layers::SceneLayer.new("scene")
    ui_layer = Graphics::Layers::UILayer.new("ui")

    layer_manager.add_layer(background_layer)
    layer_manager.add_layer(scene_layer)
    layer_manager.add_layer(ui_layer)

    # Main loop
    until RL.close_window?
      dt = RL.get_frame_time

      # Update particles
      emitter.update(dt)

      # Update camera with arrow keys
      if RL.key_down?(RL::KeyboardKey::Right)
        renderer.camera.position.x += 200 * dt
      end
      if RL.key_down?(RL::KeyboardKey::Left)
        renderer.camera.position.x -= 200 * dt
      end
      if RL.key_down?(RL::KeyboardKey::Down)
        renderer.camera.position.y += 200 * dt
      end
      if RL.key_down?(RL::KeyboardKey::Up)
        renderer.camera.position.y -= 200 * dt
      end

      # Render
      RL.begin_drawing
      display.clear_screen(RL::DARKBLUE)

      renderer.render do |context|
        # Draw some shapes in world space
        context.draw_rectangle(350, 250, 100, 100, RL::GREEN)
        context.draw_circle(RL::Vector2.new(x: 400, y: 300), 30, RL::RED)

        # Draw particles
        emitter.draw_with_context(context)

        # Draw UI text (should not move with camera)
        context.draw_screen_space do
          RL.draw_text("New Graphics System Test", 10, 10, 20, RL::WHITE)
          RL.draw_text("Use Arrow Keys to Move Camera", 10, 40, 20, RL::WHITE)
          RL.draw_text("Camera: (#{renderer.camera.position.x.to_i}, #{renderer.camera.position.y.to_i})", 10, 70, 20, RL::WHITE)
          RL.draw_text("Particles: #{emitter.particle_count}", 10, 100, 20, RL::WHITE)
          RL.draw_text("FPS: #{RL.get_fps}", 10, 130, 20, RL::WHITE)
        end
      end

      RL.end_drawing
    end

    # Cleanup
    RL.close_window
  end
end

SimpleGraphicsTest.run
