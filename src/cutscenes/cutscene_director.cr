# Cutscene Director for complex scripted sequences
# Provides timeline-based scripting, conditional branches, and advanced cutscene control

require "./cutscene"
require "./cutscene_camera"
# require "./enhanced_cutscene_actions" # File removed
require "../core/game_state_manager"

module PointClickEngine
  module Cutscenes
    # Timeline event for precise cutscene timing
    struct TimelineEvent
      property time : Float32
      property action : CutsceneAction
      property executed : Bool = false

      def initialize(@time : Float32, @action : CutsceneAction)
      end

      def reset
        @executed = false
        @action.reset
      end
    end

    # Cutscene checkpoint for save/load and skipping
    struct CutsceneCheckpoint
      property time : Float32
      property name : String
      property game_state : Hash(String, Core::GameValue)?

      def initialize(@time : Float32, @name : String, @game_state : Hash(String, Core::GameValue)? = nil)
      end
    end

    # Enhanced cutscene with timeline-based scripting
    class EnhancedCutscene < Cutscene
      property timeline : Array(TimelineEvent) = [] of TimelineEvent
      property checkpoints : Array(CutsceneCheckpoint) = [] of CutsceneCheckpoint
      property current_time : Float32 = 0.0f32
      property camera : CutsceneCamera?
      property allow_skipping : Bool = true
      property skip_to_checkpoint : Bool = true
      property loop_cutscene : Bool = false
      property cutscene_speed : Float32 = 1.0f32

      # Branching support
      property branches : Hash(String, EnhancedCutscene) = {} of String => EnhancedCutscene
      property current_branch : String?

      # State integration
      property state_manager : Core::GameStateManager?

      def initialize(name : String)
        super(name)

        # Initialize camera if not provided
        @camera = CutsceneCamera.new(RL::Vector2.new(x: 0, y: 0))
      end

      # Add timeline event at specific time
      def add_timeline_event(time : Float32, action : CutsceneAction)
        event = TimelineEvent.new(time, action)
        @timeline << event

        # Sort timeline by time
        @timeline.sort_by!(&.time)
      end

      # Add checkpoint for skipping/saving
      def add_checkpoint(time : Float32, name : String, save_state : Bool = false)
        game_state = if save_state && (manager = @state_manager)
                       # Capture current game state
                       state_copy = {} of String => Core::GameValue
                       manager.flags.each { |k, v| state_copy[k] = v }
                       manager.variables.each { |k, v| state_copy[k] = v }
                       state_copy
                     else
                       nil
                     end

        checkpoint = CutsceneCheckpoint.new(time, name, game_state)
        @checkpoints << checkpoint
        @checkpoints.sort_by!(&.time)
      end

      # Add conditional branch
      def add_branch(condition : String, branch_cutscene : EnhancedCutscene)
        @branches[condition] = branch_cutscene
      end

      # Enhanced convenience methods with timeline support
      def at_time(time : Float32, &block)
        builder = TimelineBuilder.new(time, self)
        with builder yield
      end

      def camera_pan(time : Float32, target : RL::Vector2, duration : Float32,
                     transition : CameraTransition = CameraTransition::EaseInOut)
        if camera = @camera
          action = CameraPanAction.new(camera, target, duration, transition)
          add_timeline_event(time, action)
        end
      end

      def camera_zoom(time : Float32, zoom : Float32, duration : Float32,
                      transition : CameraTransition = CameraTransition::EaseInOut)
        if camera = @camera
          action = CameraZoomAction.new(camera, zoom, duration, transition)
          add_timeline_event(time, action)
        end
      end

      def camera_shake(time : Float32, intensity : Float32, duration : Float32, frequency : Float32 = 10.0f32)
        if camera = @camera
          action = CameraShakeAction.new(camera, intensity, duration, frequency)
          add_timeline_event(time, action)
        end
      end

      def camera_follow(time : Float32, character : Characters::Character, smooth : Bool = true)
        if camera = @camera
          action = CameraFollowAction.new(camera, character, smooth)
          add_timeline_event(time, action)
        end
      end

      def particle_effect(time : Float32, position : RL::Vector2, effect_type : String,
                          duration : Float32 = 0.0f32, particle_system : Graphics::ParticleSystem? = nil)
        return unless particle_system
        action = ParticleEffectAction.new(particle_system, position, effect_type, duration)
        add_timeline_event(time, action)
      end

      def weather_effect(time : Float32, effect_type : String, intensity : Float32 = 1.0f32,
                         duration : Float32 = 0.0f32)
        action = WeatherEffectAction.new(effect_type, intensity, duration)
        add_timeline_event(time, action)
      end

      def sound_effect(time : Float32, sound_name : String, volume : Float32 = 1.0f32, pitch : Float32 = 1.0f32)
        action = SoundEffectAction.new(sound_name, volume, pitch)
        add_timeline_event(time, action)
      end

      def music_transition(time : Float32, track : String, fade_duration : Float32 = 2.0f32)
        action = MusicTransitionAction.new(track, fade_duration)
        add_timeline_event(time, action)
      end

      def synchronized_actions(time : Float32, character_actions : Hash(Characters::Character, CutsceneAction))
        action = SynchronizedAction.new(character_actions)
        add_timeline_event(time, action)
      end

      def conditional_action(time : Float32, condition : String, true_action : CutsceneAction,
                             false_action : CutsceneAction? = nil)
        action = ConditionalAction.new(condition, true_action, false_action, @state_manager)
        add_timeline_event(time, action)
      end

      # Override play to reset timeline
      def play
        super
        @current_time = 0.0f32
        reset_timeline
        @camera.try(&.reset)
      end

      # Override update for timeline processing
      def update(dt : Float32)
        return unless @playing
        return if @completed

        # Update timeline
        @current_time += dt * @cutscene_speed

        # Process timeline events
        process_timeline_events

        # Update camera
        @camera.try(&.update(dt))

        # Check for branch conditions
        check_branch_conditions

        # Check for cutscene completion
        check_completion

        # Call parent update for legacy actions
        super(dt * @cutscene_speed)
      end

      # Skip to next checkpoint or end
      def skip_to_next_checkpoint
        return unless @allow_skipping

        if @skip_to_checkpoint
          next_checkpoint = @checkpoints.find { |cp| cp.time > @current_time }
          if next_checkpoint
            skip_to_time(next_checkpoint.time)
            restore_checkpoint_state(next_checkpoint)
          else
            skip_to_end
          end
        else
          skip_to_end
        end
      end

      # Skip to specific time
      def skip_to_time(target_time : Float32)
        @current_time = target_time

        # Execute all events up to target time
        @timeline.each do |event|
          if event.time <= target_time && !event.executed
            event.action.start
            event.action.finish
            event.executed = true
          end
        end
      end

      # Skip to end of cutscene
      def skip_to_end
        @current_time = get_total_duration
        execute_all_remaining_events
        complete_cutscene
      end

      # Get total cutscene duration
      def get_total_duration : Float32
        timeline_duration = @timeline.empty? ? 0.0f32 : @timeline.last.time + @timeline.last.action.duration
        actions_duration = @actions.empty? ? 0.0f32 : @actions.map(&.duration).sum
        Math.max(timeline_duration, actions_duration)
      end

      # Set cutscene playback speed
      def set_speed(speed : Float32)
        @cutscene_speed = speed.clamp(0.1f32, 5.0f32)
      end

      # Pause cutscene
      def pause
        @cutscene_speed = 0.0f32
      end

      # Resume cutscene
      def resume
        @cutscene_speed = 1.0f32
      end

      # Check if cutscene can be skipped
      def can_skip? : Bool
        @allow_skipping && @skippable
      end

      private def reset_timeline
        @timeline.each(&.reset)
      end

      private def process_timeline_events
        @timeline.each do |event|
          if event.time <= @current_time && !event.executed
            event.action.start
            event.executed = true
          end

          # Update active events
          if event.executed && !event.action.completed
            event.action.update(@current_time - event.time)
          end
        end
      end

      private def check_branch_conditions
        return if @current_branch # Already in a branch
        return unless manager = @state_manager

        @branches.each do |condition, branch_cutscene|
          if manager.check_condition(condition)
            @current_branch = condition
            # Switch to branch cutscene
            branch_cutscene.play
            break
          end
        end
      end

      private def check_completion
        # Check if all timeline events are complete
        timeline_complete = @timeline.all? { |event| event.executed && event.action.completed }

        # Check if regular actions are complete
        actions_complete = @current_action_index >= @actions.size

        if timeline_complete && actions_complete
          complete_cutscene
        end
      end

      private def complete_cutscene
        if @loop_cutscene
          play # Restart cutscene
        else
          @completed = true
          @playing = false
          @on_complete.try(&.call)
        end
      end

      private def execute_all_remaining_events
        @timeline.each do |event|
          unless event.executed
            event.action.start
            event.action.finish
            event.executed = true
          end
        end
      end

      private def restore_checkpoint_state(checkpoint : CutsceneCheckpoint)
        return unless manager = @state_manager
        return unless state = checkpoint.game_state

        # Restore game state from checkpoint
        state.each do |key, value|
          case value
          when Bool
            manager.set_flag(key, value)
          else
            manager.set_variable(key, value)
          end
        end
      end
    end

    # Builder for timeline events
    class TimelineBuilder
      def initialize(@time : Float32, @cutscene : EnhancedCutscene)
      end

      def move_character(character : Characters::Character, position : RL::Vector2, duration : Float32 = 0.0f32)
        action = MoveCharacterAction.new(character, position, true, duration)
        @cutscene.add_timeline_event(@time, action)
      end

      def dialog(character : Characters::Character, text : String, duration : Float32 = 0.0f32)
        action = DialogAction.new(character, text, duration)
        @cutscene.add_timeline_event(@time, action)
      end

      def camera_pan(target : RL::Vector2, duration : Float32, transition : CameraTransition = CameraTransition::EaseInOut)
        @cutscene.camera_pan(@time, target, duration, transition)
      end

      def camera_zoom(zoom : Float32, duration : Float32, transition : CameraTransition = CameraTransition::EaseInOut)
        @cutscene.camera_zoom(@time, zoom, duration, transition)
      end

      def camera_shake(intensity : Float32, duration : Float32, frequency : Float32 = 10.0f32)
        @cutscene.camera_shake(@time, intensity, duration, frequency)
      end

      def sound_effect(name : String, volume : Float32 = 1.0f32, pitch : Float32 = 1.0f32)
        @cutscene.sound_effect(@time, name, volume, pitch)
      end

      def particle_effect(position : RL::Vector2, effect_type : String, duration : Float32 = 0.0f32)
        # Would need particle system reference
        puts "Timeline particle effect: #{effect_type} at #{position} for #{duration}s"
      end

      def weather_effect(effect_type : String, intensity : Float32 = 1.0f32, duration : Float32 = 0.0f32)
        @cutscene.weather_effect(@time, effect_type, intensity, duration)
      end

      def run(&block : Proc(Nil))
        action = CallbackAction.new(block)
        @cutscene.add_timeline_event(@time, action)
      end
    end
  end
end
