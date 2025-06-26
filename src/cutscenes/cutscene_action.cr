module PointClickEngine
  module Cutscenes
    # Base class for all cutscene actions
    abstract class CutsceneAction
      property duration : Float32
      property completed : Bool = false
      property started : Bool = false
      @elapsed_time : Float32 = 0.0f32

      def initialize(@duration : Float32 = 0.0f32)
      end

      def update(dt : Float32) : Bool
        unless @started
          start
          @started = true
        end

        if @duration > 0.0f32
          @elapsed_time += dt
          progress = (@elapsed_time / @duration).clamp(0.0f32, 1.0f32)
          update_action(progress)

          if @elapsed_time >= @duration && !@completed
            finish
            @completed = true
          end
        else
          # Instant action
          update_action(1.0f32)
          finish
          @completed = true
        end

        @completed
      end

      def reset
        @elapsed_time = 0.0f32
        @completed = false
        @started = false
      end

      abstract def start
      abstract def update_action(progress : Float32)
      abstract def finish
    end

    # Move a character to a position
    class MoveCharacterAction < CutsceneAction
      def initialize(@character : Characters::Character, @target_position : Raylib::Vector2,
                     @use_pathfinding : Bool = true, duration : Float32 = 0.0f32)
        super(duration)
      end

      def start
        if @use_pathfinding && (scene = Core::Engine.instance.current_scene)
          if path = scene.find_path(@character.position.x, @character.position.y,
               @target_position.x, @target_position.y)
            @character.walk_to_with_path(path)
          else
            @character.walk_to(@target_position)
          end
        else
          @character.walk_to(@target_position)
        end
      end

      def update_action(progress : Float32)
        # Character movement is handled by the character itself
        # Check if character reached destination
        if @character.state != Characters::CharacterState::Walking
          @completed = true
        end
      end

      def finish
        # Ensure character is at final position
      end
    end

    # Make a character say something
    class DialogAction < CutsceneAction
      @dialog_completed : Bool = false

      def initialize(@character : Characters::Character, @text : String, duration : Float32 = 0.0f32)
        super(duration)
      end

      def start
        @character.say(@text) do
          @dialog_completed = true
          nil
        end
      end

      def update_action(progress : Float32)
        if @dialog_completed || @duration > 0.0f32 && progress >= 1.0f32
          @completed = true
        end
      end

      def finish
        # Dialog cleanup is handled by the character
      end
    end

    # Wait for a duration
    class WaitAction < CutsceneAction
      def initialize(duration : Float32)
        super(duration)
      end

      def start
      end

      def update_action(progress : Float32)
      end

      def finish
      end
    end

    # Fade in/out
    class FadeAction < CutsceneAction
      @start_alpha : Float32 = 0.0f32
      @current_alpha : Float32 = 0.0f32

      def initialize(@fade_in : Bool, @color : Raylib::Color = Raylib::BLACK, duration : Float32 = 1.0f32)
        super(duration)
        @start_alpha = @fade_in ? 1.0f32 : 0.0f32
        @current_alpha = @start_alpha
      end

      def start
      end

      def update_action(progress : Float32)
        if @fade_in
          @current_alpha = 1.0f32 - progress
        else
          @current_alpha = progress
        end
      end

      def finish
        @current_alpha = @fade_in ? 0.0f32 : 1.0f32
      end

      def draw
        if @current_alpha > 0.0f32
          fade_color = @color
          fade_color.a = (@current_alpha * 255).to_u8
          Raylib.draw_rectangle(0, 0, Raylib.get_screen_width, Raylib.get_screen_height, fade_color)
        end
      end
    end

    # Change scene
    class ChangeSceneAction < CutsceneAction
      def initialize(@scene_name : String)
        super(0.0f32) # Instant
      end

      def start
        Core::Engine.instance.change_scene(@scene_name)
      end

      def update_action(progress : Float32)
      end

      def finish
      end
    end

    # Play animation
    class PlayAnimationAction < CutsceneAction
      def initialize(@character : Characters::Character, @animation_name : String,
                     @wait_for_completion : Bool = false, duration : Float32 = 0.0f32)
        super(duration)
      end

      def start
        @character.play_animation(@animation_name)
      end

      def update_action(progress : Float32)
        if @wait_for_completion && @character.sprite
          sprite = @character.sprite.not_nil!
          current_anim = @character.animation_controller.try(&.current_animation) || ""
          if !sprite.playing && current_anim == @animation_name
            @completed = true
          end
        end
      end

      def finish
      end
    end

    # Camera movement
    class CameraAction < CutsceneAction
      @start_position : Raylib::Vector2
      @start_zoom : Float32

      def initialize(@target_position : Raylib::Vector2? = nil, @target_zoom : Float32? = nil,
                     duration : Float32 = 1.0f32)
        super(duration)
        @start_position = Raylib::Vector2.new(0, 0)
        @start_zoom = 1.0f32
      end

      def start
        if display = Core::Engine.instance.display_manager
          # Store current camera state
          # Note: This would need camera position tracking in DisplayManager
          @start_position = Raylib::Vector2.new(0, 0)
          @start_zoom = 1.0f32
        end
      end

      def update_action(progress : Float32)
        # Interpolate camera position and zoom
        # This would need camera control methods in DisplayManager
      end

      def finish
      end
    end

    # Run a callback
    class CallbackAction < CutsceneAction
      def initialize(@callback : Proc(Nil))
        super(0.0f32) # Instant
      end

      def start
        @callback.call
      end

      def update_action(progress : Float32)
      end

      def finish
      end
    end

    # Show/hide UI elements
    class UIVisibilityAction < CutsceneAction
      def initialize(@show_ui : Bool)
        super(0.0f32) # Instant
      end

      def start
        # This would need UI visibility control in Engine
        if @show_ui
          Core::Engine.instance.render_manager.show_ui
        else
          Core::Engine.instance.render_manager.hide_ui
        end
      end

      def update_action(progress : Float32)
      end

      def finish
      end
    end

    # Parallel action group
    class ParallelAction < CutsceneAction
      @actions : Array(CutsceneAction)

      def initialize(@actions : Array(CutsceneAction))
        # Duration is the longest action
        max_duration = @actions.map(&.duration).max? || 0.0f32
        super(max_duration)
      end

      def start
        @actions.each(&.reset)
      end

      def update_action(progress : Float32)
        all_completed = true

        @actions.each do |action|
          unless action.completed
            action.update(@duration > 0 ? @elapsed_time : 0.1f32)
            all_completed = false if !action.completed
          end
        end

        if all_completed
          @completed = true
        end
      end

      def finish
        @actions.each do |action|
          action.finish unless action.completed
        end
      end
    end
  end
end
