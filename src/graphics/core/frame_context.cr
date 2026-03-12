# Per-frame render/display context used to keep world, UI, and display
# calculations on one explicit contract.

require "raylib-cr"

module PointClickEngine
  module Graphics
    module Core
      class FrameContext
        getter display : Display
        getter camera : Camera
        getter logical_width : Int32
        getter logical_height : Int32
        getter scene_width : Int32
        getter scene_height : Int32
        getter cinematic_width : Int32?
        getter cinematic_height : Int32?

        def initialize(
          @display : Display,
          @camera : Camera,
          @logical_width : Int32,
          @logical_height : Int32,
          @scene_width : Int32,
          @scene_height : Int32,
          @cinematic_width : Int32? = nil,
          @cinematic_height : Int32? = nil
        )
        end

        def logical_rect : RL::Rectangle
          RL::Rectangle.new(x: 0.0f32, y: 0.0f32, width: @logical_width.to_f32, height: @logical_height.to_f32)
        end

        def scene_rect : RL::Rectangle
          RL::Rectangle.new(x: 0.0f32, y: 0.0f32, width: @scene_width.to_f32, height: @scene_height.to_f32)
        end

        def screen_rect : RL::Rectangle
          @display.game_area_screen_rect
        end

        def world_to_ui(world_pos : RL::Vector2) : RL::Vector2
          @camera.world_to_screen(world_pos.x, world_pos.y)
        end

        def ui_to_world(ui_pos : RL::Vector2) : RL::Vector2
          @camera.screen_to_world(ui_pos.x.to_i, ui_pos.y.to_i)
        end

        def cinematic_rect : RL::Rectangle
          width = (@cinematic_width || @logical_width).to_f32
          height = (@cinematic_height || @logical_height).to_f32
          RL::Rectangle.new(x: 0.0f32, y: 0.0f32, width: width, height: height)
        end
      end
    end
  end
end
