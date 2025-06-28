require "../src/point_click_engine"

# Simple test to verify the new graphics system is working
module GraphicsTest
  include PointClickEngine

  def self.run
    # Initialize display
    display = Graphics::Display.new(800, 600, "Graphics Test")
    display.set_scaling_mode(Graphics::Display::ScalingMode::FitHeight)

    # Create renderer
    renderer = Graphics::Renderer.new(display)

    # Create a simple sprite
    texture = RL.load_texture("assets/textures/test_sprite.png")
    sprite = Graphics::Sprites::Sprite.new(texture)
    sprite.position = RL::Vector2.new(x: 400, y: 300)

    # Create a particle emitter
    emitter = Graphics::Particles::Emitter.new(
      RL::Vector2.new(x: 400, y: 100),
      Graphics::Particles::EmitterType::Point
    )
    emitter.emission_rate = 50.0f32
    emitter.particle_lifetime = 2.0f32
    emitter.start_color = RL::RED
    emitter.end_color = RL::Color.new(r: 255, g: 0, b: 0, a: 0)

    # Main loop
    until display.should_close?
      dt = RL.get_frame_time

      # Update particles
      emitter.update(dt)

      # Render
      display.begin_frame
      RL.clear_background(RL::DARKGRAY)

      renderer.render do |context|
        # Draw sprite
        context.draw_sprite(sprite, sprite.position)

        # Draw particles
        emitter.draw_with_context(context)

        # Draw some debug text
        context.draw_text("New Graphics System Test", 10, 10, 20, RL::WHITE)
        context.draw_text("Particles: #{emitter.particle_count}", 10, 40, 20, RL::WHITE)
      end

      display.end_frame
    end

    # Cleanup
    RL.unload_texture(texture)
    display.close
  end
end

GraphicsTest.run
