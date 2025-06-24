require "./cutscene_action"

module PointClickEngine
  module Cutscenes
    # A cutscene is a sequence of actions
    class Cutscene
      property name : String
      property actions : Array(CutsceneAction)
      property current_action_index : Int32 = 0
      property playing : Bool = false
      property completed : Bool = false
      property skippable : Bool = true
      property on_complete : Proc(Nil)?

      @fade_overlay : FadeAction?

      def initialize(@name : String)
        @actions = [] of CutsceneAction
      end

      def add_action(action : CutsceneAction)
        @actions << action
      end

      # Convenience methods for common actions
      def move_character(character : Characters::Character, position : Raylib::Vector2,
                         use_pathfinding : Bool = true)
        add_action(MoveCharacterAction.new(character, position, use_pathfinding))
      end

      def dialog(character : Characters::Character, text : String, duration : Float32 = 0.0f32)
        add_action(DialogAction.new(character, text, duration))
      end

      def wait(duration : Float32)
        add_action(WaitAction.new(duration))
      end

      def fade_in(duration : Float32 = 1.0f32, color : Raylib::Color = Raylib::BLACK)
        action = FadeAction.new(true, color, duration)
        @fade_overlay = action
        add_action(action)
      end

      def fade_out(duration : Float32 = 1.0f32, color : Raylib::Color = Raylib::BLACK)
        action = FadeAction.new(false, color, duration)
        @fade_overlay = action
        add_action(action)
      end

      def change_scene(scene_name : String)
        add_action(ChangeSceneAction.new(scene_name))
      end

      def play_animation(character : Characters::Character, animation_name : String,
                         wait_for_completion : Bool = false)
        add_action(PlayAnimationAction.new(character, animation_name, wait_for_completion))
      end

      def camera_move(position : Raylib::Vector2, duration : Float32 = 1.0f32)
        add_action(CameraAction.new(position, nil, duration))
      end

      def camera_zoom(zoom : Float32, duration : Float32 = 1.0f32)
        add_action(CameraAction.new(nil, zoom, duration))
      end

      def hide_ui
        add_action(UIVisibilityAction.new(false))
      end

      def show_ui
        add_action(UIVisibilityAction.new(true))
      end

      def run(&block : Proc(Nil))
        add_action(CallbackAction.new(block))
      end

      def parallel(&block)
        actions = [] of CutsceneAction
        with CutsceneBuilder.new(actions) yield
        add_action(ParallelAction.new(actions))
      end

      def play
        @playing = true
        @completed = false
        @current_action_index = 0
        @actions.each(&.reset)
      end

      def stop
        @playing = false
        @on_complete.try(&.call)
      end

      def skip
        return unless @skippable
        stop
      end

      def update(dt : Float32)
        return unless @playing
        return if @completed

        # Update current action
        if @current_action_index < @actions.size
          current_action = @actions[@current_action_index]

          if current_action.update(dt)
            # Action completed, move to next
            @current_action_index += 1

            if @current_action_index >= @actions.size
              # Cutscene completed
              @completed = true
              @playing = false
              @on_complete.try(&.call)
            end
          end
        end
      end

      def draw
        return unless @playing

        # Draw fade overlay if active
        @fade_overlay.try(&.draw)
      end

      # Builder for parallel actions
      class CutsceneBuilder
        def initialize(@actions : Array(CutsceneAction))
        end

        def move_character(character : Characters::Character, position : Raylib::Vector2,
                           use_pathfinding : Bool = true)
          @actions << MoveCharacterAction.new(character, position, use_pathfinding)
        end

        def dialog(character : Characters::Character, text : String, duration : Float32 = 0.0f32)
          @actions << DialogAction.new(character, text, duration)
        end

        def wait(duration : Float32)
          @actions << WaitAction.new(duration)
        end

        def play_animation(character : Characters::Character, animation_name : String,
                           wait_for_completion : Bool = false)
          @actions << PlayAnimationAction.new(character, animation_name, wait_for_completion)
        end

        def run(&block : Proc(Nil))
          @actions << CallbackAction.new(block)
        end
      end
    end
  end
end
