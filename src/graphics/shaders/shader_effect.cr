# Base shader effect class

require "raylib-cr"

module PointClickEngine
  module Graphics
    module Shaders
      # Base class for shader-based effects
      abstract class ShaderEffect
        property shader : RL::Shader
        property enabled : Bool = true
        property intensity : Float32 = 1.0f32

        # Uniform locations cache
        @uniform_locations = {} of String => Int32

        def initialize(@shader : RL::Shader)
          setup_uniforms
        end

        # Setup uniform locations (override in subclasses)
        abstract def setup_uniforms

        # Update shader uniforms before rendering
        abstract def update_uniforms(time : Float32)

        # Apply effect to render texture
        def apply(source : RL::RenderTexture2D, target : RL::RenderTexture2D, time : Float32)
          return unless @enabled

          update_uniforms(time)

          RL.begin_texture_mode(target)
          RL.clear_background(RL::BLACK)

          RL.begin_shader_mode(@shader)
          RL.draw_texture_rec(
            source.texture,
            RL::Rectangle.new(0, 0, source.texture.width, -source.texture.height),
            RL::Vector2.new(0, 0),
            RL::WHITE
          )
          RL.end_shader_mode

          RL.end_texture_mode
        end

        # Get uniform location with caching
        protected def get_uniform_location(name : String) : Int32
          @uniform_locations[name] ||= RL.get_shader_location(@shader, name)
        end

        # Set shader uniform value
        protected def set_uniform(name : String, value : Float32)
          location = get_uniform_location(name)
          RL.set_shader_value(@shader, location, pointerof(value), RL::ShaderUniformDataType::Float)
        end

        protected def set_uniform(name : String, value : RL::Vector2)
          location = get_uniform_location(name)
          RL.set_shader_value(@shader, location, pointerof(value), RL::ShaderUniformDataType::Vec2)
        end

        protected def set_uniform(name : String, value : RL::Vector3)
          location = get_uniform_location(name)
          RL.set_shader_value(@shader, location, pointerof(value), RL::ShaderUniformDataType::Vec3)
        end

        protected def set_uniform(name : String, value : RL::Vector4)
          location = get_uniform_location(name)
          RL.set_shader_value(@shader, location, pointerof(value), RL::ShaderUniformDataType::Vec4)
        end

        protected def set_uniform(name : String, value : Int32)
          location = get_uniform_location(name)
          RL.set_shader_value(@shader, location, pointerof(value), RL::ShaderUniformDataType::Int)
        end

        # Cleanup
        def cleanup
          # Shader cleanup handled by shader manager
        end
      end
    end
  end
end
