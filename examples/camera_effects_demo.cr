require "../src/point_click_engine"

# Camera Effects Demo
# Demonstrates various camera effects like shake, zoom, pan, follow, and sway

class CameraEffectsDemo
  include PointClickEngine

  def initialize
    @engine = Core::Engine.new(1024, 768, "Camera Effects Demo")
    @engine.init

    # Create a simple scene
    scene = Scenes::Scene.new("demo_scene")
    scene.walkable_area = Scenes::WalkableArea.new(
      polygon: Scenes::PolygonRegion.new([
        RL::Vector2.new(x: 0, y: 400),
        RL::Vector2.new(x: 1024, y: 400),
        RL::Vector2.new(x: 1024, y: 768),
        RL::Vector2.new(x: 0, y: 768),
      ])
    )

    # Create player
    player = Characters::Player.new(
      "Player",
      RL::Vector2.new(x: 512, y: 500),
      RL::Vector2.new(x: 32, y: 64)
    )

    @engine.add_scene(scene)
    @engine.change_scene("demo_scene")
    @engine.player = player

    setup_ui
  end

  def setup_ui
    # Add UI instructions
    @instructions = [
      "Camera Effects Demo - Press keys to trigger effects:",
      "1 - Shake (earthquake)",
      "2 - Zoom In (2x)",
      "3 - Zoom Out (0.5x)",
      "4 - Pan to corner",
      "5 - Follow player",
      "6 - Sea sway effect",
      "7 - Stop all effects",
      "8 - Reset camera",
      "ESC - Exit",
    ]
  end

  def run
    # Set up keyboard handler
    @engine.on_update = ->(dt : Float32) {
      handle_input
      draw_ui
    }

    @engine.run
  end

  private def handle_input
    camera_manager = @engine.camera_manager

    # Shake effect
    if RL.key_pressed?(RL::KeyboardKey::One)
      puts "Applying shake effect"
      camera_manager.apply_effect(:shake, intensity: 20.0f32, duration: 2.0f32, frequency: 15.0f32)
    end

    # Zoom in
    if RL.key_pressed?(RL::KeyboardKey::Two)
      puts "Applying zoom in effect"
      camera_manager.apply_effect(:zoom, target: 2.0f32, duration: 1.0f32)
    end

    # Zoom out
    if RL.key_pressed?(RL::KeyboardKey::Three)
      puts "Applying zoom out effect"
      camera_manager.apply_effect(:zoom, target: 0.5f32, duration: 1.0f32)
    end

    # Pan to corner
    if RL.key_pressed?(RL::KeyboardKey::Four)
      puts "Applying pan effect"
      camera_manager.apply_effect(:pan, target_x: 800.0f32, target_y: 600.0f32, duration: 2.0f32)
    end

    # Follow player
    if RL.key_pressed?(RL::KeyboardKey::Five)
      if player = @engine.player
        puts "Following player"
        camera_manager.apply_effect(:follow, target: player, smooth: true, deadzone: 30.0f32)
      end
    end

    # Sea sway
    if RL.key_pressed?(RL::KeyboardKey::Six)
      puts "Applying sway effect"
      camera_manager.apply_effect(:sway, amplitude: 15.0f32, frequency: 0.3f32, duration: 5.0f32, vertical_factor: 0.4f32)
    end

    # Stop all effects
    if RL.key_pressed?(RL::KeyboardKey::Seven)
      puts "Removing all effects"
      camera_manager.remove_all_effects
    end

    # Reset camera
    if RL.key_pressed?(RL::KeyboardKey::Eight)
      puts "Resetting camera"
      camera_manager.remove_all_effects
      camera_manager.center_on(512.0f32, 400.0f32)
    end
  end

  private def draw_ui
    # Draw instructions
    y = 10
    @instructions.each do |instruction|
      RL.draw_text(instruction, 10, y, 20, RL::WHITE)
      y += 25
    end

    # Draw current effects
    camera_manager = @engine.camera_manager
    active_effects = camera_manager.active_effects

    if active_effects.any?
      RL.draw_text("Active Effects:", 10, 300, 20, RL::YELLOW)
      y = 325
      active_effects.each do |effect|
        progress = (effect.progress * 100).to_i
        RL.draw_text("- #{effect.type} (#{progress}%)", 10, y, 18, RL::GREEN)
        y += 20
      end
    end

    # Draw camera info
    camera = camera_manager.current_camera
    RL.draw_text("Camera Position: #{camera.position.x.to_i}, #{camera.position.y.to_i}", 10, 400, 18, RL::GRAY)
    RL.draw_text("Camera Zoom: #{camera_manager.total_zoom.round(2)}", 10, 420, 18, RL::GRAY)
  end
end

# Run the demo
demo = CameraEffectsDemo.new
demo.run
