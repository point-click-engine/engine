# Particle system for visual effects

require "raylib-cr"
require "yaml"
require "../utils/yaml_converters"

module PointClickEngine
  module Graphics
    # Individual particle
    class Particle
      include YAML::Serializable
      
      @[YAML::Field(converter: PointClickEngine::Utils::YAMLConverters::Vector2Converter)]
      property position : RL::Vector2
      property size : Float64 = 0.0
      @[YAML::Field(converter: PointClickEngine::Utils::YAMLConverters::Vector2Converter)]
      property velocity : RL::Vector2
      @[YAML::Field(converter: PointClickEngine::Utils::YAMLConverters::ColorConverter)]
      property color : RL::Color
      property lifetime : Float64
      property age : Float64 = 0.0

      def initialize(@position : RL::Vector2, @velocity : RL::Vector2, @color : RL::Color,
        @size : Float64, @lifetime : Float64)
      end

      def update(dt : Float32)
        @age += dt
        @position.x += @velocity.x * dt
        @position.y += @velocity.y * dt
      end

      def draw
        alpha = (1.0 - @age / @lifetime) * 255
        color = RL::Color.new(r: @color.r, g: @color.g, b: @color.b, a: alpha.to_u8.clamp(0, 255))
        RL.draw_circle(@position.x.to_i, @position.y.to_i, @size, color)
      end

      def alive? : Bool
        @age < @lifetime
      end
    end

    # Particle system for managing multiple particles
    class ParticleSystem < Core::GameObject
      property particles : Array(Particle) = [] of Particle
      property emit_rate : Float64 = 10.0
      property emit_timer : Float64 = 0.0
      property particle_lifetime : Float64 = 1.0
      property particle_size : Float64 = 3.0
      property particle_speed : Float64 = 100.0
      @[YAML::Field(converter: PointClickEngine::Utils::YAMLConverters::ColorConverter)]
      property particle_color : RL::Color = RL::WHITE
      property emitting : Bool = true

      def initialize(position : RL::Vector2)
        super(position, RL::Vector2.new(x: 0, y: 0))
      end

      def emit_particle
        angle = Random.rand * Math::PI * 2
        vel_x = Math.cos(angle) * @particle_speed * (0.5 + Random.rand * 0.5)
        vel_y = Math.sin(angle) * @particle_speed * (0.5 + Random.rand * 0.5)
        velocity = RL::Vector2.new(x: vel_x.to_f, y: vel_y.to_f)
        p_size = @particle_size * (0.5 + Random.rand * 0.5)
        p_lifetime = @particle_lifetime * (0.5 + Random.rand * 0.5)
        @particles << Particle.new(@position, velocity, @particle_color, p_size.to_f, p_lifetime.to_f)
      end

      def update(dt : Float32)
        if @emitting
          @emit_timer += dt
          while @emit_timer >= (1.0 / @emit_rate)
            emit_particle
            @emit_timer -= (1.0 / @emit_rate)
          end
        end
        @particles.each(&.update(dt))
        @particles.reject! { |p| !p.alive? }
      end

      def draw
        @particles.each(&.draw)
      end
    end
  end
end