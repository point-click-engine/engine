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

          # Common uniform locations
          @time_loc : Int32 = -1
          @progress_loc : Int32 = -1
          @resolution_loc : Int32 = -1

          # Track whether shader is available (GPU context exists)
          getter shader_available : Bool = false

          def initialize(duration : Float32 = 0.0f32)
            super(duration)
            if ShaderEffect.gl_context_available?
              load_shader
              cache_uniform_locations if @shader
              @shader_available = @shader != nil
            end
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
            # Resolution is provided by the frame graph when rendering to a target.
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

          def apply_to_render_target(source : RL::RenderTexture2D, destination : RL::RenderTexture2D,
                                     logical_width : Int32, logical_height : Int32)
            RL.begin_texture_mode(destination)
            RL.clear_background(RL::BLANK)

            if shader = @shader
              RL.begin_shader_mode(shader)
              update_common_uniforms(shader)
              set_resolution_uniform(shader, logical_width.to_f32, logical_height.to_f32)
              update_effect_uniforms(shader, logical_width, logical_height)
            end

            draw_source_texture(source.texture, logical_width, logical_height)

            RL.end_shader_mode if @shader
            RL.end_texture_mode
          end

          protected def update_effect_uniforms(shader : RL::Shader, logical_width : Int32, logical_height : Int32)
          end

          protected def set_resolution_uniform(shader : RL::Shader, width : Float32, height : Float32)
            return unless @resolution_loc >= 0

            resolution = RL::Vector2.new(x: width, y: height)
            RL.set_shader_value(shader, @resolution_loc, pointerof(resolution), RL::ShaderUniformDataType::Vec2)
          end

          protected def draw_source_texture(texture : RL::Texture2D, logical_width : Int32, logical_height : Int32)
            source_rect = RL::Rectangle.new(
              x: 0.0f32,
              y: 0.0f32,
              width: logical_width.to_f32,
              height: -logical_height.to_f32
            )
            destination_rect = RL::Rectangle.new(
              x: 0.0f32,
              y: 0.0f32,
              width: logical_width.to_f32,
              height: logical_height.to_f32
            )

            RL.draw_texture_pro(
              texture,
              source_rect,
              destination_rect,
              RL::Vector2.new(x: 0.0f32, y: 0.0f32),
              0.0f32,
              RL::WHITE
            )
          end
          
          # Cleanup
          def cleanup
            if shader = @shader
              RL.unload_shader(shader)
              @shader = nil
            end

            super
          end
        end
      end
    end
  end
end
