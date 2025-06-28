# Enhanced particle system module

require "./particles/particle"
require "./particles/emitter"
require "./particles/presets"

module PointClickEngine
  module Graphics
    # Particle system with visual effects
    module Particles
      # Create preset particle effects
      def self.fire(position : RL::Vector2, intensity : Float32 = 1.0f32) : Emitter
        Presets.fire(position, intensity)
      end

      def self.smoke(position : RL::Vector2, density : Float32 = 1.0f32) : Emitter
        Presets.smoke(position, density)
      end

      def self.explosion(position : RL::Vector2, power : Float32 = 1.0f32) : Emitter
        Presets.explosion(position, power)
      end

      def self.sparkles(position : RL::Vector2, spread : Float32 = 50.0f32) : Emitter
        Presets.sparkles(position, spread)
      end

      def self.rain(position : RL::Vector2, width : Float32 = 800.0f32, intensity : Float32 = 1.0f32) : Emitter
        Presets.rain(position, width, intensity)
      end

      def self.snow(position : RL::Vector2, width : Float32 = 800.0f32, density : Float32 = 1.0f32) : Emitter
        Presets.snow(position, width, density)
      end

      def self.hit_spark(position : RL::Vector2, direction : RL::Vector2? = nil) : Emitter
        Presets.hit_spark(position, direction)
      end

      def self.dust(position : RL::Vector2, radius : Float32 = 30.0f32) : Emitter
        Presets.dust(position, radius)
      end

      def self.bubbles(position : RL::Vector2, spread : Float32 = 50.0f32) : Emitter
        Presets.bubbles(position, spread)
      end

      def self.trail(position : RL::Vector2, color : RL::Color = RL::WHITE) : Emitter
        Presets.trail(position, color)
      end
    end
  end
end
