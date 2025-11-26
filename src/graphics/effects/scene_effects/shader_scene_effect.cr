# Base class for shader-based scene effects
#
# This bridges ShaderEffect with BaseSceneEffect to allow shader effects
# to be used as scene effects.

require "../shader_effect"
require "./base_scene_effect"
require "../../core/display"

module PointClickEngine
  module Graphics
    module Effects
      module SceneEffects
        # Base class for shader-based scene effects
        abstract class ShaderSceneEffect < BaseSceneEffect
          @shader : RL::Shader?
          @render_texture : RL::RenderTexture2D?
          
          # Common uniform locations
          @time_loc : Int32 = -1
          @progress_loc : Int32 = -1
          @resolution_loc : Int32 = -1
          
          def initialize(duration : Float32 = 0.0f32)
            super(duration)
            load_shader
            cache_uniform_locations if @shader
          end
          
          # Abstract method to get vertex shader source
          abstract def vertex_shader_source : String
          
          # Abstract method to get fragment shader source
          abstract def fragment_shader_source : String
          
          # Load and compile the shader
          protected def load_shader
            @shader = load_shader_from_memory(vertex_shader_source, fragment_shader_source)
          end
          
          # Default vertex shader
          protected def default_vertex_shader : String
            <<-VERTEX
            #version 330 core
            
            in vec3 vertexPosition;
            in vec2 vertexTexCoord;
            in vec4 vertexColor;
            
            out vec2 fragTexCoord;
            out vec4 fragColor;
            
            uniform mat4 mvp;
            
            void main()
            {
                fragTexCoord = vertexTexCoord;
                fragColor = vertexColor;
                gl_Position = mvp * vec4(vertexPosition, 1.0);
            }
            VERTEX
          end
          
          # Helper to load shader from memory
          protected def load_shader_from_memory(vs_code : String, fs_code : String) : RL::Shader
            RL.load_shader_from_memory(vs_code, fs_code)
          end
          
          # Cache common uniform locations
          protected def cache_uniform_locations
            return unless shader = @shader
            
            @time_loc = RL.get_shader_location(shader, "time")
            @progress_loc = RL.get_shader_location(shader, "progress")
            @resolution_loc = RL.get_shader_location(shader, "resolution")
          end
          
          # Update common uniforms
          protected def update_common_uniforms(shader : RL::Shader)
            # Time
            if @time_loc >= 0
              time = @elapsed
              RL.set_shader_value(shader, @time_loc, pointerof(time), RL::ShaderUniformDataType::Float)
            end
            
            # Progress
            if @progress_loc >= 0 && @duration > 0
              progress_val = progress
              RL.set_shader_value(shader, @progress_loc, pointerof(progress_val), RL::ShaderUniformDataType::Float)
            end
            
            # Resolution
            if @resolution_loc >= 0
              resolution = RL::Vector2.new(
                x: Core::Display::REFERENCE_WIDTH.to_f32,
                y: Core::Display::REFERENCE_HEIGHT.to_f32
              )
              RL.set_shader_value(shader, @resolution_loc, pointerof(resolution), RL::ShaderUniformDataType::Vec2)
            end
          end
          
          # Helper to set shader values
          protected def set_shader_value(name : String, value : Float32)
            return unless shader = @shader
            loc = RL.get_shader_location(shader, name)
            if loc >= 0
              RL.set_shader_value(shader, loc, pointerof(value), RL::ShaderUniformDataType::Float)
            end
          end
          
          protected def set_shader_value(name : String, value : RL::Color)
            return unless shader = @shader
            loc = RL.get_shader_location(shader, name)
            if loc >= 0
              vec4 = RL::Vector4.new(
                x: value.r / 255.0f32,
                y: value.g / 255.0f32,
                z: value.b / 255.0f32,
                w: value.a / 255.0f32
              )
              RL.set_shader_value(shader, loc, pointerof(vec4), RL::ShaderUniformDataType::Vec4)
            end
          end
          
          protected def set_shader_value(name : String, value : RL::Vector2)
            return unless shader = @shader
            loc = RL.get_shader_location(shader, name)
            if loc >= 0
              RL.set_shader_value(shader, loc, pointerof(value), RL::ShaderUniformDataType::Vec2)
            end
          end
          
          # Default implementation for apply_to_layer
          def apply_to_layer(context : EffectContext, layer : Layers::Layer)
            # Most shader effects work on the whole scene, not individual layers
          end
          
          # Generic render method that subclasses can override
          def render_scene_with_effect(&block : -> Nil)
            # Default implementation - subclasses should override this
            yield
          end
          
          # Cleanup
          def cleanup
            if shader = @shader
              RL.unload_shader(shader)
              @shader = nil
            end
            
            if render_texture = @render_texture
              RL.unload_render_texture(render_texture)
              @render_texture = nil
            end
            
            super
          end
        end
      end
    end
  end
end