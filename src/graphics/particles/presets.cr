# Preset particle effects for common use cases

require "./emitter"

module PointClickEngine
  module Graphics
    module Particles
      # Factory for creating preset particle effects
      module Presets
        # Create a fire effect
        def self.fire(position : RL::Vector2, intensity : Float32 = 1.0f32) : Emitter
          config = EmitterConfig.new

          # Fire properties
          config.emission_rate = 30.0f32 * intensity
          config.emission_shape = EmissionShape::CircleArea
          config.emission_radius = 10.0f32 * intensity

          # Lifetime and speed
          config.lifetime_min = 0.5f32
          config.lifetime_max = 1.0f32
          config.speed_min = 80.0f32 * intensity
          config.speed_max = 120.0f32 * intensity

          # Size
          config.size_min = 3.0f32 * intensity
          config.size_max = 6.0f32 * intensity
          config.size_over_lifetime = true
          config.end_size_multiplier = 0.1f32

          # Movement - fire rises
          config.direction = RL::Vector2.new(x: 0, y: -1)
          config.spread = 30.0f32
          config.gravity = RL::Vector2.new(x: 0, y: -50) # Negative gravity (rises)

          # Colors - yellow to red to dark
          config.start_color = RL::Color.new(r: 255, g: 200, b: 50, a: 200)
          config.end_color = RL::Color.new(r: 180, g: 0, b: 0, a: 0)
          config.color_variation = 0.1f32

          # Fading
          config.fade_in_time = 0.1f32
          config.fade_out_time = 0.3f32

          Emitter.new(position, config)
        end

        # Create smoke effect
        def self.smoke(position : RL::Vector2, density : Float32 = 1.0f32) : Emitter
          config = EmitterConfig.new

          # Smoke properties
          config.emission_rate = 10.0f32 * density
          config.emission_shape = EmissionShape::CircleArea
          config.emission_radius = 15.0f32

          # Lifetime and speed
          config.lifetime_min = 2.0f32
          config.lifetime_max = 3.0f32
          config.speed_min = 20.0f32
          config.speed_max = 40.0f32

          # Size - grows over time
          config.size_min = 5.0f32
          config.size_max = 10.0f32
          config.size_over_lifetime = true
          config.end_size_multiplier = 3.0f32

          # Movement - rises slowly with sway
          config.direction = RL::Vector2.new(x: 0, y: -1)
          config.spread = 45.0f32
          config.gravity = RL::Vector2.new(x: 0, y: -10)

          # Colors - gray smoke
          config.start_color = RL::Color.new(r: 100, g: 100, b: 100, a: 150)
          config.end_color = RL::Color.new(r: 60, g: 60, b: 60, a: 0)

          # Fading
          config.fade_in_time = 0.3f32
          config.fade_out_time = 0.5f32

          Emitter.new(position, config)
        end

        # Create explosion effect
        def self.explosion(position : RL::Vector2, power : Float32 = 1.0f32) : Emitter
          config = EmitterConfig.new

          # Burst emission
          config.emission_rate = 0.0f32
          config.burst_count = (50 * power).to_i
          config.emission_shape = EmissionShape::Point

          # Lifetime and speed
          config.lifetime_min = 0.5f32
          config.lifetime_max = 1.0f32
          config.speed_min = 200.0f32 * power
          config.speed_max = 400.0f32 * power

          # Size
          config.size_min = 2.0f32
          config.size_max = 5.0f32
          config.size_over_lifetime = true
          config.end_size_multiplier = 0.0f32

          # Movement - all directions
          config.direction = RL::Vector2.new(x: 0, y: 0)
          config.spread = 360.0f32
          config.gravity = RL::Vector2.new(x: 0, y: 300)

          # Colors - bright to dark
          config.start_color = RL::Color.new(r: 255, g: 200, b: 100, a: 255)
          config.end_color = RL::Color.new(r: 255, g: 50, b: 0, a: 0)

          # Fading
          config.fade_out_time = 0.2f32

          emitter = Emitter.new(position, config)
          emitter.burst # Trigger burst immediately
          emitter.stop  # Don't continue emitting
          emitter
        end

        # Create sparkle/magic effect
        def self.sparkles(position : RL::Vector2, spread_radius : Float32 = 50.0f32) : Emitter
          config = EmitterConfig.new

          # Sparkle properties
          config.emission_rate = 20.0f32
          config.emission_shape = EmissionShape::CircleArea
          config.emission_radius = spread_radius

          # Lifetime and speed
          config.lifetime_min = 0.5f32
          config.lifetime_max = 1.5f32
          config.speed_min = 10.0f32
          config.speed_max = 30.0f32

          # Size - small sparkles
          config.size_min = 1.0f32
          config.size_max = 3.0f32
          config.size_over_lifetime = true
          config.end_size_multiplier = 0.0f32

          # Movement - gentle float
          config.direction = RL::Vector2.new(x: 0, y: -1)
          config.spread = 180.0f32
          config.gravity = RL::Vector2.new(x: 0, y: -20)

          # Rotation for twinkle effect
          config.rotation_speed_min = -180.0f32
          config.rotation_speed_max = 180.0f32

          # Colors - white/yellow sparkles
          config.start_color = RL::Color.new(r: 255, g: 255, b: 200, a: 255)
          config.end_color = RL::Color.new(r: 255, g: 255, b: 255, a: 0)
          config.color_variation = 0.2f32

          # Quick fade
          config.fade_in_time = 0.1f32
          config.fade_out_time = 0.3f32

          Emitter.new(position, config)
        end

        # Create rain effect
        def self.rain(position : RL::Vector2, width : Float32 = 800.0f32, intensity : Float32 = 1.0f32) : Emitter
          config = EmitterConfig.new

          # Rain properties
          config.emission_rate = 100.0f32 * intensity
          config.emission_shape = EmissionShape::Line
          config.emission_size = RL::Vector2.new(x: width, y: 0)
          config.max_particles = 500

          # Lifetime and speed
          config.lifetime_min = 2.0f32
          config.lifetime_max = 3.0f32
          config.speed_min = 300.0f32
          config.speed_max = 400.0f32

          # Size - thin drops
          config.size_min = 1.0f32
          config.size_max = 2.0f32

          # Movement - straight down with slight angle
          config.direction = RL::Vector2.new(x: -0.2, y: 1)
          config.spread = 5.0f32
          config.gravity = RL::Vector2.new(x: 0, y: 200)

          # Colors - blue-white rain
          config.start_color = RL::Color.new(r: 150, g: 150, b: 200, a: 100)
          config.end_color = RL::Color.new(r: 150, g: 150, b: 200, a: 50)

          Emitter.new(position, config)
        end

        # Create snow effect
        def self.snow(position : RL::Vector2, width : Float32 = 800.0f32, density : Float32 = 1.0f32) : Emitter
          config = EmitterConfig.new

          # Snow properties
          config.emission_rate = 30.0f32 * density
          config.emission_shape = EmissionShape::Line
          config.emission_size = RL::Vector2.new(x: width, y: 0)
          config.max_particles = 200

          # Lifetime and speed
          config.lifetime_min = 4.0f32
          config.lifetime_max = 6.0f32
          config.speed_min = 20.0f32
          config.speed_max = 50.0f32

          # Size - varied flakes
          config.size_min = 1.0f32
          config.size_max = 4.0f32

          # Movement - gentle drift
          config.direction = RL::Vector2.new(x: 0, y: 1)
          config.spread = 30.0f32
          config.gravity = RL::Vector2.new(x: 20, y: 30) # Slight drift

          # Rotation for flake tumble
          config.rotation_speed_min = -30.0f32
          config.rotation_speed_max = 30.0f32

          # Colors - white snow
          config.start_color = RL::Color.new(r: 255, g: 255, b: 255, a: 200)
          config.end_color = RL::Color.new(r: 255, g: 255, b: 255, a: 100)

          Emitter.new(position, config)
        end

        # Create hit/impact effect
        def self.hit_spark(position : RL::Vector2, direction : RL::Vector2? = nil) : Emitter
          config = EmitterConfig.new

          # Burst of sparks
          config.emission_rate = 0.0f32
          config.burst_count = 15
          config.emission_shape = EmissionShape::Point

          # Lifetime and speed
          config.lifetime_min = 0.2f32
          config.lifetime_max = 0.4f32
          config.speed_min = 100.0f32
          config.speed_max = 200.0f32

          # Size
          config.size_min = 1.0f32
          config.size_max = 2.0f32
          config.size_over_lifetime = true
          config.end_size_multiplier = 0.0f32

          # Movement - reflect from impact
          if dir = direction
            config.direction = dir
            config.spread = 90.0f32
          else
            config.direction = RL::Vector2.new(x: 0, y: -1)
            config.spread = 180.0f32
          end
          config.gravity = RL::Vector2.new(x: 0, y: 500)

          # Colors - white hot sparks
          config.start_color = RL::Color.new(r: 255, g: 255, b: 200, a: 255)
          config.end_color = RL::Color.new(r: 255, g: 100, b: 0, a: 0)

          # Quick fade
          config.fade_out_time = 0.1f32

          emitter = Emitter.new(position, config)
          emitter.burst
          emitter.stop
          emitter
        end

        # Create dust/debris effect
        def self.dust(position : RL::Vector2, radius : Float32 = 30.0f32) : Emitter
          config = EmitterConfig.new

          # Dust properties
          config.emission_rate = 0.0f32
          config.burst_count = 20
          config.emission_shape = EmissionShape::CircleArea
          config.emission_radius = radius

          # Lifetime and speed
          config.lifetime_min = 1.0f32
          config.lifetime_max = 2.0f32
          config.speed_min = 20.0f32
          config.speed_max = 60.0f32

          # Size
          config.size_min = 2.0f32
          config.size_max = 5.0f32
          config.size_over_lifetime = true
          config.end_size_multiplier = 2.0f32

          # Movement - spread out and fall
          config.direction = RL::Vector2.new(x: 0, y: 0)
          config.spread = 360.0f32
          config.gravity = RL::Vector2.new(x: 0, y: 50)

          # Colors - brown dust
          config.start_color = RL::Color.new(r: 139, g: 90, b: 43, a: 150)
          config.end_color = RL::Color.new(r: 100, g: 70, b: 40, a: 0)

          # Fading
          config.fade_in_time = 0.1f32
          config.fade_out_time = 0.5f32

          emitter = Emitter.new(position, config)
          emitter.burst
          emitter.stop
          emitter
        end

        # Create bubble effect
        def self.bubbles(position : RL::Vector2, spread : Float32 = 50.0f32) : Emitter
          config = EmitterConfig.new

          # Bubble properties
          config.emission_rate = 5.0f32
          config.emission_shape = EmissionShape::CircleArea
          config.emission_radius = spread

          # Lifetime and speed
          config.lifetime_min = 2.0f32
          config.lifetime_max = 4.0f32
          config.speed_min = 30.0f32
          config.speed_max = 60.0f32

          # Size
          config.size_min = 3.0f32
          config.size_max = 8.0f32

          # Movement - rise with wobble
          config.direction = RL::Vector2.new(x: 0, y: -1)
          config.spread = 30.0f32
          config.gravity = RL::Vector2.new(x: 0, y: -30) # Buoyancy

          # Colors - translucent bubbles
          config.start_color = RL::Color.new(r: 200, g: 200, b: 255, a: 100)
          config.end_color = RL::Color.new(r: 255, g: 255, b: 255, a: 0)

          # Pop at end
          config.fade_out_time = 0.1f32

          Emitter.new(position, config)
        end

        # Create trail effect (for moving objects)
        def self.trail(position : RL::Vector2, color : RL::Color = RL::WHITE) : Emitter
          config = EmitterConfig.new

          # Trail properties
          config.emission_rate = 60.0f32
          config.emission_shape = EmissionShape::Point
          config.max_particles = 50

          # Lifetime and speed
          config.lifetime_min = 0.3f32
          config.lifetime_max = 0.5f32
          config.speed_min = 0.0f32
          config.speed_max = 10.0f32

          # Size
          config.size_min = 3.0f32
          config.size_max = 5.0f32
          config.size_over_lifetime = true
          config.end_size_multiplier = 0.0f32

          # No movement
          config.direction = RL::Vector2.new(x: 0, y: 0)
          config.spread = 360.0f32
          config.gravity = RL::Vector2.new(x: 0, y: 0)
          config.use_world_space = false # Stay relative to emitter

          # Colors
          config.start_color = color
          config.end_color = RL::Color.new(r: color.r, g: color.g, b: color.b, a: 0)

          # Quick fade
          config.fade_out_time = 0.2f32

          Emitter.new(position, config)
        end
      end
    end
  end
end
