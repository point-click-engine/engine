# Shader resource manager

require "raylib-cr"

module PointClickEngine
  module Graphics
    module Shaders
      # Manages shader loading and caching
      class ShaderManager
        # Cached shaders
        @shaders = {} of String => RL::Shader

        # Load shader from files
        def load(name : String, vertex_path : String?, fragment_path : String) : RL::Shader
          return @shaders[name] if @shaders.has_key?(name)

          shader = RL.load_shader(vertex_path, fragment_path)
          @shaders[name] = shader
          shader
        end

        # Load shader from strings
        def load_from_memory(name : String, vertex_code : String?, fragment_code : String) : RL::Shader
          return @shaders[name] if @shaders.has_key?(name)

          shader = RL.load_shader_from_memory(vertex_code, fragment_code)
          @shaders[name] = shader
          shader
        end

        # Get cached shader
        def get(name : String) : RL::Shader?
          @shaders[name]?
        end

        # Unload specific shader
        def unload(name : String)
          if shader = @shaders[name]?
            RL.unload_shader(shader)
            @shaders.delete(name)
          end
        end

        # Unload all shaders
        def cleanup
          @shaders.each_value do |shader|
            RL.unload_shader(shader)
          end
          @shaders.clear
        end
      end

      # Global shader manager instance
      class_property manager : ShaderManager = ShaderManager.new
    end
  end
end
