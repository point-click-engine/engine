module PointClickEngine
  module Graphics
    module Shaders
      class ShaderSystem
        property shaders : Hash(Symbol, Raylib::Shader)
        property active_shader : Raylib::Shader?

        def initialize
          @shaders = {} of Symbol => Raylib::Shader
          @active_shader = nil
        end

        def load_shader(name : Symbol, fragment_path : String, vertex_path : String? = nil)
          shader = Raylib.load_shader(vertex_path, fragment_path)
          @shaders[name] = shader
          shader
        end

        def load_shader_from_memory(name : Symbol, fragment_code : String, vertex_code : String? = nil)
          shader = Raylib.load_shader_from_memory(vertex_code, fragment_code)
          @shaders[name] = shader
          shader
        end

        def get_shader(name : Symbol) : Raylib::Shader?
          @shaders[name]?
        end

        def set_active(name : Symbol)
          if shader = @shaders[name]?
            @active_shader = shader
          else
            raise "Shader #{name} not found"
          end
        end

        def begin_mode
          if shader = @active_shader
            Raylib.begin_shader_mode(shader)
          end
        end

        def end_mode
          Raylib.end_shader_mode if @active_shader
        end

        def set_value(name : Symbol, uniform_name : String, value : Float32 | Int32 | Array(Float32) | Raylib::Vector2 | Raylib::Vector3 | Raylib::Vector4)
          if shader = @shaders[name]?
            location = Raylib.get_shader_location(shader, uniform_name)

            case value
            when Float32
              Raylib.set_shader_value(shader, location, pointerof(value), Raylib::ShaderUniformDataType::Float)
            when Int32
              Raylib.set_shader_value(shader, location, pointerof(value), Raylib::ShaderUniformDataType::Int)
            when Array(Float32)
              case value.size
              when 2
                vec = Raylib::Vector2.new(x: value[0], y: value[1])
                Raylib.set_shader_value(shader, location, pointerof(vec), Raylib::ShaderUniformDataType::Vec2)
              when 3
                vec = Raylib::Vector3.new(x: value[0], y: value[1], z: value[2])
                Raylib.set_shader_value(shader, location, pointerof(vec), Raylib::ShaderUniformDataType::Vec3)
              when 4
                vec = Raylib::Vector4.new(x: value[0], y: value[1], z: value[2], w: value[3])
                Raylib.set_shader_value(shader, location, pointerof(vec), Raylib::ShaderUniformDataType::Vec4)
              else
                raise "Invalid array size for shader value"
              end
            when Raylib::Vector2
              Raylib.set_shader_value(shader, location, pointerof(value), Raylib::ShaderUniformDataType::Vec2)
            when Raylib::Vector3
              Raylib.set_shader_value(shader, location, pointerof(value), Raylib::ShaderUniformDataType::Vec3)
            when Raylib::Vector4
              Raylib.set_shader_value(shader, location, pointerof(value), Raylib::ShaderUniformDataType::Vec4)
            end
          end
        end

        def cleanup
          @shaders.each_value do |shader|
            Raylib.unload_shader(shader)
          end
          @shaders.clear
        end
      end
    end
  end
end
