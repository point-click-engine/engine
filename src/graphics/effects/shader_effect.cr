# Base class for all shader-based effects in the new graphics system
#
# This provides common functionality for loading, managing, and applying shaders
# to different types of targets (objects, scenes, camera, etc.)

require "./effect"
require "raylib-cr"

module PointClickEngine
  module Graphics
    module Effects
      # Base class for shader-based effects
      abstract class ShaderEffect < Effect
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
        
        # Cache common uniform locations for performance
        protected def cache_uniform_locations
          return unless shader = @shader
          
          @time_loc = RL.get_shader_location(shader, "time")
          @progress_loc = RL.get_shader_location(shader, "progress")
          @resolution_loc = RL.get_shader_location(shader, "resolution")
        end
        
        # Update common shader uniforms
        protected def update_common_uniforms(shader : RL::Shader)
          # Update time if used
          if @time_loc >= 0
            time = RL.get_time.to_f32
            RL.set_shader_value(shader, @time_loc, pointerof(time), RL::ShaderUniformDataType::Float)
          end
          
          # Update progress if used
          if @progress_loc >= 0
            RL.set_shader_value(shader, @progress_loc, pointerof(@progress), RL::ShaderUniformDataType::Float)
          end
          
          # Update resolution if used
          if @resolution_loc >= 0
            resolution = RL::Vector2.new(x: Display::REFERENCE_WIDTH.to_f32, y: Display::REFERENCE_HEIGHT.to_f32)
            RL.set_shader_value(shader, @resolution_loc, pointerof(resolution), RL::ShaderUniformDataType::Vec2)
          end
        end
        
        # Apply the effect (must be implemented by subclasses)
        abstract def apply(context : EffectContext)
        
        # Cleanup resources
        def cleanup
          @shader.try { |s| RL.unload_shader(s) }
          @render_texture.try { |rt| RL.unload_render_texture(rt) }
          @shader = nil
          @render_texture = nil
        end
        
        # Helper to load shader from source strings
        protected def load_shader_from_memory(vertex_source : String, fragment_source : String) : RL::Shader?
          begin
            shader = RL.load_shader_from_memory(vertex_source, fragment_source)
            if shader.id > 0
              puts "[ShaderEffect] Successfully loaded shader for #{self.class.name}"
              return shader
            else
              puts "[ShaderEffect] Failed to load shader - invalid shader ID"
              return nil
            end
          rescue ex
            puts "[ShaderEffect] Failed to load shader - #{ex.message}"
            return nil
          end
        end
        
        # Common vertex shader for 2D effects
        protected def default_vertex_shader : String
          <<-SHADER
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
          SHADER
        end
        
        # Helper to set shader value safely
        protected def set_shader_value(uniform_name : String, value : Float32)
          return unless shader = @shader
          
          loc = RL.get_shader_location(shader, uniform_name)
          if loc >= 0
            RL.set_shader_value(shader, loc, pointerof(value), RL::ShaderUniformDataType::Float)
          end
        end
        
        protected def set_shader_value(uniform_name : String, value : RL::Vector2)
          return unless shader = @shader
          
          loc = RL.get_shader_location(shader, uniform_name)
          if loc >= 0
            RL.set_shader_value(shader, loc, pointerof(value), RL::ShaderUniformDataType::Vec2)
          end
        end
        
        protected def set_shader_value(uniform_name : String, value : RL::Vector3)
          return unless shader = @shader
          
          loc = RL.get_shader_location(shader, uniform_name)
          if loc >= 0
            RL.set_shader_value(shader, loc, pointerof(value), RL::ShaderUniformDataType::Vec3)
          end
        end
        
        protected def set_shader_value(uniform_name : String, value : RL::Color)
          return unless shader = @shader
          
          loc = RL.get_shader_location(shader, uniform_name)
          if loc >= 0
            vec4 = RL::Vector4.new(
              x: value.r.to_f32 / 255.0f32,
              y: value.g.to_f32 / 255.0f32,
              z: value.b.to_f32 / 255.0f32,
              w: value.a.to_f32 / 255.0f32
            )
            RL.set_shader_value(shader, loc, pointerof(vec4), RL::ShaderUniformDataType::Vec4)
          end
        end
      end
    end
  end
end