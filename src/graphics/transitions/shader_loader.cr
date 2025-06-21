# Common shader loading utilities for transitions

require "raylib-cr"
require "./transition_effect"

module PointClickEngine
  module Graphics
    module Transitions
      # Utility class for loading transition shaders
      class ShaderLoader
        # Load a shader from source code
        def self.load_shader_from_code(vertex_source : String, fragment_source : String) : RL::Shader?
          begin
            shader = RL.load_shader_from_memory(vertex_source, fragment_source)
            return shader
          rescue
            puts "Failed to load transition shader"
            return nil
          end
        end

        # Create a basic shader with the common vertex shader
        def self.create_basic_shader(fragment_source : String) : RL::Shader?
          vertex_source = <<-SHADER
          #version 330 core
          layout (location = 0) in vec3 aPos;
          layout (location = 1) in vec2 aTexCoord;
          layout (location = 2) in vec3 aNormal;
          layout (location = 3) in vec4 aColor;

          out vec2 fragTexCoord;
          out vec4 fragColor;

          uniform mat4 mvp;

          void main()
          {
              fragTexCoord = aTexCoord;
              fragColor = aColor;
              gl_Position = mvp * vec4(aPos, 1.0);
          }
          SHADER

          load_shader_from_code(vertex_source, fragment_source)
        end

        # Set uniform values safely
        def self.set_shader_uniform_safe(shader : RL::Shader, uniform_name : String, value : Float32)
          location = RL.get_shader_location(shader, uniform_name)
          if location >= 0
            RL.set_shader_value(shader, location, pointerof(value), RL::ShaderUniformDataType::Float)
          end
        end

        def self.set_shader_uniform_safe(shader : RL::Shader, uniform_name : String, value : RL::Vector2)
          location = RL.get_shader_location(shader, uniform_name)
          if location >= 0
            RL.set_shader_value(shader, location, pointerof(value), RL::ShaderUniformDataType::Vec2)
          end
        end

        def self.set_shader_uniform_safe(shader : RL::Shader, uniform_name : String, value : RL::Vector3)
          location = RL.get_shader_location(shader, uniform_name)
          if location >= 0
            RL.set_shader_value(shader, location, pointerof(value), RL::ShaderUniformDataType::Vec3)
          end
        end

        def self.set_shader_uniform_safe(shader : RL::Shader, uniform_name : String, value : RL::Vector4)
          location = RL.get_shader_location(shader, uniform_name)
          if location >= 0
            RL.set_shader_value(shader, location, pointerof(value), RL::ShaderUniformDataType::Vec4)
          end
        end

        # Set texture uniform
        def self.set_shader_texture_uniform(shader : RL::Shader, uniform_name : String, texture : RL::Texture2D, slot : Int32 = 0)
          location = RL.get_shader_location(shader, uniform_name)
          if location >= 0
            RL.set_shader_value_texture(shader, location, texture)
          end
        end

        # Helper methods for common shader parameters
        def self.set_progress(shader : RL::Shader, progress : Float32)
          set_shader_uniform_safe(shader, "progress", progress)
        end

        def self.set_resolution(shader : RL::Shader, width : Float32, height : Float32)
          resolution = RL::Vector2.new(x: width, y: height)
          set_shader_uniform_safe(shader, "resolution", resolution)
        end

        def self.set_time(shader : RL::Shader, time : Float32)
          set_shader_uniform_safe(shader, "time", time)
        end

        def self.set_direction(shader : RL::Shader, direction : RL::Vector2)
          set_shader_uniform_safe(shader, "direction", direction)
        end
      end
    end
  end
end
