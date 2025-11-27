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

      # Override in subclasses that need to draw visual content
      def draw
      end
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

    # Change scene with optional transition
    class ChangeSceneAction < CutsceneAction
      def initialize(@scene_name : String, @transition_type : String = "fade",
                     @transition_duration : Float32 = 1.0f32)
        super(@transition_duration)
      end

      def start
        Core::Engine.instance.change_scene_with_transition(
          @scene_name, @transition_type, @transition_duration
        )
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

    # ============================================================
    # TEXT DISPLAY ACTIONS
    # ============================================================

    # Show text on screen with effects
    class ShowTextAction < CutsceneAction
      property text : String
      property font_size : Int32
      property color : Raylib::Color
      property position : String
      property fade_in : Float32
      property fade_out : Float32
      property glow : Bool
      property glow_color : Raylib::Color?

      @current_alpha : Float32 = 0.0f32
      @text_x : Int32 = 0
      @text_y : Int32 = 0

      def initialize(
        @text : String,
        @font_size : Int32 = 24,
        @color : Raylib::Color = Raylib::WHITE,
        @position : String = "center",
        duration : Float32 = 3.0f32,
        @fade_in : Float32 = 0.5f32,
        @fade_out : Float32 = 0.5f32,
        @glow : Bool = false,
        @glow_color : Raylib::Color? = nil
      )
        super(duration)
      end

      def start
        # Calculate text position
        screen_width = Raylib.get_screen_width
        screen_height = Raylib.get_screen_height
        text_width = Raylib.measure_text(@text, @font_size)

        case @position.downcase
        when "center"
          @text_x = (screen_width - text_width) // 2
          @text_y = screen_height // 2
        when "top"
          @text_x = (screen_width - text_width) // 2
          @text_y = screen_height // 6
        when "bottom"
          @text_x = (screen_width - text_width) // 2
          @text_y = (screen_height * 5) // 6
        else
          @text_x = (screen_width - text_width) // 2
          @text_y = screen_height // 2
        end
      end

      def update_action(progress : Float32)
        # Calculate alpha based on fade in/out
        fade_in_end = @fade_in / @duration
        fade_out_start = 1.0f32 - (@fade_out / @duration)

        if progress < fade_in_end
          @current_alpha = progress / fade_in_end
        elsif progress > fade_out_start
          @current_alpha = 1.0f32 - ((progress - fade_out_start) / (1.0f32 - fade_out_start))
        else
          @current_alpha = 1.0f32
        end
      end

      def finish
        @current_alpha = 0.0f32
      end

      def draw
        return if @current_alpha <= 0.0f32

        draw_color = @color
        draw_color.a = (@current_alpha * 255).to_u8

        # Draw glow effect if enabled
        if @glow
          glow_c = @glow_color || Raylib::Color.new(r: 255, g: 255, b: 200, a: 100)
          glow_c.a = (@current_alpha * glow_c.a.to_f32).to_u8
          Raylib.draw_text(@text, @text_x - 2, @text_y - 2, @font_size, glow_c)
          Raylib.draw_text(@text, @text_x + 2, @text_y + 2, @font_size, glow_c)
        end

        Raylib.draw_text(@text, @text_x, @text_y, @font_size, draw_color)
      end
    end

    # ============================================================
    # AUDIO ACTIONS
    # ============================================================

    # Play music track
    class PlayMusicAction < CutsceneAction
      property track : String
      property volume : Float32
      property fade_in_duration : Float32
      property loop : Bool
      property crossfade : Bool

      def initialize(
        @track : String,
        @volume : Float32 = 0.7f32,
        @fade_in_duration : Float32 = 0.0f32,
        @loop : Bool = true,
        @crossfade : Bool = false
      )
        super(0.0f32) # Instant action
      end

      def start
        if audio = Core::Engine.instance.system_manager.audio_manager
          audio.play_music(@track, @loop)
          audio.set_music_volume(@volume)
        end
      end

      def update_action(progress : Float32)
      end

      def finish
      end
    end

    # Stop music
    class StopMusicAction < CutsceneAction
      property fade_out : Float32

      @start_volume : Float32 = 1.0f32

      def initialize(@fade_out : Float32 = 1.0f32)
        super(@fade_out)
      end

      def start
        # Store initial volume for fade
        if audio = Core::Engine.instance.system_manager.audio_manager
          @start_volume = audio.music_volume
        end
      end

      def update_action(progress : Float32)
        if audio = Core::Engine.instance.system_manager.audio_manager
          # Gradually reduce volume
          audio.set_music_volume(@start_volume * (1.0f32 - progress))
        end
      end

      def finish
        if audio = Core::Engine.instance.system_manager.audio_manager
          audio.stop_music
          audio.set_music_volume(@start_volume) # Restore volume for next track
        end
      end
    end

    # Play ambient sound
    class PlayAmbientAction < CutsceneAction
      property sound : String
      property volume : Float32
      property fade_in : Float32

      def initialize(@sound : String, @volume : Float32 = 0.5f32, @fade_in : Float32 = 0.0f32)
        super(0.0f32) # Instant
      end

      def start
        if audio = Core::Engine.instance.system_manager.audio_manager
          audio.play_sound_effect(@sound)
        end
      end

      def update_action(progress : Float32)
      end

      def finish
      end
    end

    # Stop ambient sound
    class StopAmbientAction < CutsceneAction
      property sound : String
      property fade_out : Float32

      def initialize(@sound : String, @fade_out : Float32 = 1.0f32)
        super(0.0f32) # Instant
      end

      def start
        # Ambient sounds stop naturally or we could track them
      end

      def update_action(progress : Float32)
      end

      def finish
      end
    end

    # Play sound effect
    class SoundEffectAction < CutsceneAction
      property sound : String
      property volume : Float32
      property delay : Float32

      @played : Bool = false

      def initialize(@sound : String, @volume : Float32 = 1.0f32, @delay : Float32 = 0.0f32)
        super(@delay)
      end

      def start
        if @delay <= 0.0f32
          play_sound
        end
      end

      def update_action(progress : Float32)
        if !@played && progress >= 1.0f32
          play_sound
        end
      end

      def finish
        play_sound unless @played
      end

      private def play_sound
        return if @played
        @played = true
        if audio = Core::Engine.instance.system_manager.audio_manager
          audio.play_sound_effect(@sound)
        end
      end
    end

    # ============================================================
    # CAMERA ACTIONS
    # ============================================================

    # Camera shake effect
    class CameraShakeAction < CutsceneAction
      property intensity : Float32
      property frequency : Float32

      def initialize(@intensity : Float32, duration : Float32, @frequency : Float32 = 10.0f32)
        super(duration)
      end

      def start
        # Use the effect manager's camera shake
        Core::Engine.instance.effect_manager.add_camera_effect(
          "shake",
          amplitude: @intensity,
          frequency: @frequency,
          duration: @duration
        )
      end

      def update_action(progress : Float32)
        # Shake is handled by effect manager
      end

      def finish
      end
    end

    # Camera pan to position
    class CameraPanAction < CutsceneAction
      property target : Raylib::Vector2?
      property from : Raylib::Vector2?
      property easing : String

      def initialize(@target : Raylib::Vector2?, duration : Float32 = 2.0f32,
                     @easing : String = "ease_in_out", @from : Raylib::Vector2? = nil)
        super(duration)
      end

      def start
        return unless target_pos = @target
        Core::Engine.instance.effect_manager.add_camera_effect(
          "pan",
          target: [target_pos.x, target_pos.y],
          duration: @duration,
          easing: @easing
        )
      end

      def update_action(progress : Float32)
        # Pan is handled by effect manager
      end

      def finish
      end
    end

    # Camera zoom
    class CameraZoomAction < CutsceneAction
      property target_zoom : Float32
      property easing : String
      property focus : Raylib::Vector2?

      def initialize(@target_zoom : Float32, duration : Float32 = 1.0f32,
                     @easing : String = "ease_in_out", @focus : Raylib::Vector2? = nil)
        super(duration)
      end

      def start
        params = {
          target:   @target_zoom,
          duration: @duration,
          easing:   @easing,
        }
        Core::Engine.instance.effect_manager.add_camera_effect("zoom", **params)
      end

      def update_action(progress : Float32)
        # Zoom is handled by effect manager
      end

      def finish
      end
    end

    # Camera follow character
    class CameraFollowAction < CutsceneAction
      property character_name : String
      property smooth : Bool
      property offset : Raylib::Vector2?

      def initialize(@character_name : String, @smooth : Bool = true,
                     @offset : Raylib::Vector2? = nil)
        super(0.0f32) # Instant
      end

      def start
        # Would set camera to follow character
      end

      def update_action(progress : Float32)
      end

      def finish
      end
    end

    # Camera focus on target
    class CameraFocusAction < CutsceneAction
      property target : String

      def initialize(@target : String, duration : Float32 = 1.0f32)
        super(duration)
      end

      def start
      end

      def update_action(progress : Float32)
      end

      def finish
      end
    end

    # ============================================================
    # VISUAL EFFECTS
    # ============================================================

    # Screen flash effect
    class ScreenFlashAction < CutsceneAction
      property color : Raylib::Color

      def initialize(@color : Raylib::Color, duration : Float32 = 0.1f32)
        super(duration)
      end

      def start
        # Use existing flash effect from scene effects
        Core::Engine.instance.effect_manager.add_scene_effect(
          "flash",
          color: [@color.r.to_i, @color.g.to_i, @color.b.to_i, @color.a.to_i],
          duration: @duration
        )
      end

      def update_action(progress : Float32)
      end

      def finish
      end
    end

    # Screen effect (vignette, rain, fog, etc.)
    class ScreenEffectAction < CutsceneAction
      property effect : String
      property intensity : Float32
      property frequency : Float32

      def initialize(@effect : String, @intensity : Float32 = 1.0f32,
                     duration : Float32 = 1.0f32, @frequency : Float32 = 5.0f32)
        super(duration)
      end

      def start
        # Use scene effects from effect_manager
        case @effect.downcase
        when "vignette", "darkness"
          Core::Engine.instance.effect_manager.add_scene_effect(
            "darkness",
            type: "vignette",
            intensity: @intensity,
            duration: @duration
          )
        when "rain"
          intensity_name = @intensity > 0.7 ? "heavy" : (@intensity > 0.4 ? "medium" : "light")
          Core::Engine.instance.effect_manager.add_scene_effect(
            "rain",
            intensity: intensity_name,
            duration: @duration
          )
        when "fog"
          Core::Engine.instance.effect_manager.add_scene_effect(
            "fog",
            density: @intensity * 0.05,
            duration: @duration
          )
        when "underwater"
          Core::Engine.instance.effect_manager.add_scene_effect(
            "underwater",
            duration: @duration
          )
        end
      end

      def update_action(progress : Float32)
      end

      def finish
        # Effects auto-finish based on duration
      end
    end

    # Particle effect - uses scene effects
    class ParticleEffectAction < CutsceneAction
      property effect_type : String
      property position : Raylib::Vector2?
      property fullscreen : Bool
      property intensity : Float32
      property color : Raylib::Color?
      property layer : String

      def initialize(
        @effect_type : String,
        @position : Raylib::Vector2? = nil,
        @fullscreen : Bool = false,
        @intensity : Float32 = 1.0f32,
        duration : Float32 = 0.0f32,
        @color : Raylib::Color? = nil,
        @layer : String = "foreground"
      )
        super(duration)
      end

      def start
        effect_mgr = Core::Engine.instance.effect_manager

        # Map particle effects to scene effects
        case @effect_type.downcase
        when "rain"
          intensity_name = @intensity > 0.7 ? "heavy" : (@intensity > 0.4 ? "medium" : "light")
          effect_mgr.add_scene_effect("rain", intensity: intensity_name, duration: @duration)
        when "fog", "mist"
          effect_mgr.add_scene_effect("fog", density: @intensity * 0.03, duration: @duration)
        when "sparkles", "magic"
          count = (@intensity * 50).to_i
          if c = @color
            effect_mgr.add_scene_effect("sparkles", count: count, duration: @duration,
                                        color: [c.r.to_i, c.g.to_i, c.b.to_i, c.a.to_i])
          else
            effect_mgr.add_scene_effect("sparkles", count: count, duration: @duration)
          end
        when "fire", "flames"
          # Fire glow - use darkness with spotlight for glow effect
          effect_mgr.add_scene_effect("darkness", type: "spotlight", intensity: 0.3, duration: @duration)
        when "smoke"
          count = (@intensity * 30).to_i
          if c = @color
            effect_mgr.add_scene_effect("smoke", count: count, duration: @duration,
                                        color: [c.r.to_i, c.g.to_i, c.b.to_i, c.a.to_i])
          else
            effect_mgr.add_scene_effect("smoke", count: count, duration: @duration)
          end
        when "dust"
          count = (@intensity * 20).to_i
          effect_mgr.add_scene_effect("smoke", count: count, duration: @duration,
                                      speed: 10.0, color: [150, 140, 120, 60])
        when "bubbles"
          effect_mgr.add_scene_effect("underwater", duration: @duration)
        end
      end

      def update_action(progress : Float32)
      end

      def finish
      end
    end

    # Stop particle effect
    class StopParticleEffectAction < CutsceneAction
      property effect : String

      def initialize(@effect : String = "all")
        super(0.0f32)
      end

      def start
        # Clear scene effects
        if @effect == "all"
          Core::Engine.instance.effect_manager.clear_scene_effects
        end
        # Individual effect stopping is handled by effect durations
      end

      def update_action(progress : Float32)
      end

      def finish
      end
    end

    # ============================================================
    # SPRITE ACTIONS
    # ============================================================

    # Show sprite on screen
    # Note: Cutscene sprites are managed by the cutscene system
    class ShowSpriteAction < CutsceneAction
      property sprite_path : String
      property position : Raylib::Vector2
      property scale : Float32
      property fade_in : Float32
      property glow : Bool
      property glow_color : Raylib::Color?
      property glow_intensity : Float32
      property glow_pulse : Bool
      property animate : Bool
      property animation_frames : Int32
      property animation_fps : Int32
      property color_tint : Raylib::Color?

      def initialize(
        @sprite_path : String,
        @position : Raylib::Vector2,
        @scale : Float32 = 1.0f32,
        @fade_in : Float32 = 0.0f32,
        @glow : Bool = false,
        @glow_color : Raylib::Color? = nil,
        @glow_intensity : Float32 = 1.0f32,
        @glow_pulse : Bool = false,
        @animate : Bool = false,
        @animation_frames : Int32 = 1,
        @animation_fps : Int32 = 8,
        @color_tint : Raylib::Color? = nil
      )
        super(@fade_in > 0 ? @fade_in : 0.0f32)
      end

      def start
        # Register sprite with cutscene manager for rendering
        if cutscene_mgr = Core::Engine.instance.cutscene_manager
          cutscene_mgr.add_sprite(@sprite_path, @position, @scale, @glow, @glow_color)
        end
      end

      def update_action(progress : Float32)
      end

      def finish
      end
    end

    # Hide sprite
    class HideSpriteAction < CutsceneAction
      property sprite : String
      property fade_out : Float32

      def initialize(@sprite : String, @fade_out : Float32 = 0.0f32)
        super(@fade_out)
      end

      def start
      end

      def update_action(progress : Float32)
      end

      def finish
        if cutscene_mgr = Core::Engine.instance.cutscene_manager
          cutscene_mgr.remove_sprite(@sprite)
        end
      end
    end

    # Move sprite
    class MoveSpriteAction < CutsceneAction
      property sprite : String
      property target : Raylib::Vector2
      property easing : String

      def initialize(@sprite : String, @target : Raylib::Vector2,
                     duration : Float32 = 1.0f32, @easing : String = "linear")
        super(duration)
      end

      def start
      end

      def update_action(progress : Float32)
        if cutscene_mgr = Core::Engine.instance.cutscene_manager
          cutscene_mgr.move_sprite(@sprite, @target, progress)
        end
      end

      def finish
      end
    end

    # Show background image
    class ShowBackgroundAction < CutsceneAction
      property image : String
      property transition : String
      property parallax_layer : Int32

      def initialize(@image : String, @transition : String = "cut",
                     duration : Float32 = 0.0f32, @parallax_layer : Int32 = 0)
        super(duration)
      end

      def start
        # Add transition effect if not a cut
        if @transition != "cut" && @duration > 0
          Core::Engine.instance.effect_manager.add_scene_effect(
            "transition",
            type: @transition,
            duration: @duration
          )
        end
        # Background change would be handled by scene system
        if cutscene_mgr = Core::Engine.instance.cutscene_manager
          cutscene_mgr.set_background(@image)
        end
      end

      def update_action(progress : Float32)
      end

      def finish
      end
    end

    # ============================================================
    # CHARACTER ACTIONS
    # ============================================================

    # Character enters scene
    class CharacterEnterAction < CutsceneAction
      property character_name : String
      property from : String
      property to : Raylib::Vector2
      property animation : String
      property from_position : Raylib::Vector2?

      def initialize(@character_name : String, @from : String, @to : Raylib::Vector2,
                     @animation : String = "walk", duration : Float32 = 2.0f32,
                     @from_position : Raylib::Vector2? = nil)
        super(duration)
      end

      def start
        if scene = Core::Engine.instance.current_scene
          if character = scene.get_character(@character_name)
            # Use explicit from_position if provided, otherwise compute from direction
            start_pos = if pos = @from_position
                          pos
                        else
                          screen_width = Raylib.get_screen_width.to_f32
                          screen_height = Raylib.get_screen_height.to_f32

                          case @from.downcase
                          when "left"
                            Raylib::Vector2.new(x: -50, y: @to.y)
                          when "right"
                            Raylib::Vector2.new(x: screen_width + 50, y: @to.y)
                          when "top"
                            Raylib::Vector2.new(x: @to.x, y: -50)
                          when "bottom"
                            Raylib::Vector2.new(x: @to.x, y: screen_height + 50)
                          else
                            Raylib::Vector2.new(x: -50, y: @to.y)
                          end
                        end

            character.position = start_pos
            character.visible = true
            character.walk_to(@to)
          end
        end
      end

      def update_action(progress : Float32)
      end

      def finish
      end
    end

    # Character exits scene
    class CharacterExitAction < CutsceneAction
      property character_name : String
      property direction : String

      def initialize(@character_name : String, @direction : String, duration : Float32 = 2.0f32)
        super(duration)
      end

      def start
        if scene = Core::Engine.instance.current_scene
          if character = scene.get_character(@character_name)
            screen_width = Raylib.get_screen_width.to_f32
            screen_height = Raylib.get_screen_height.to_f32

            exit_pos = case @direction.downcase
                       when "left"
                         Raylib::Vector2.new(x: -50, y: character.position.y)
                       when "right"
                         Raylib::Vector2.new(x: screen_width + 50, y: character.position.y)
                       when "top"
                         Raylib::Vector2.new(x: character.position.x, y: -50)
                       when "bottom"
                         Raylib::Vector2.new(x: character.position.x, y: screen_height + 50)
                       else
                         Raylib::Vector2.new(x: -50, y: character.position.y)
                       end

            character.walk_to(exit_pos)
          end
        end
      end

      def update_action(progress : Float32)
      end

      def finish
        if scene = Core::Engine.instance.current_scene
          if character = scene.get_character(@character_name)
            character.visible = false
          end
        end
      end
    end

    # Character move to position
    class CharacterMoveAction < CutsceneAction
      property character_name : String
      property target : Raylib::Vector2
      property animation : String

      def initialize(@character_name : String, @target : Raylib::Vector2,
                     @animation : String = "walk", duration : Float32 = 0.0f32)
        super(duration)
      end

      def start
        if scene = Core::Engine.instance.current_scene
          if character = scene.get_character(@character_name)
            character.walk_to(@target)
          end
        end
      end

      def update_action(progress : Float32)
        # Check if character reached destination
        if scene = Core::Engine.instance.current_scene
          if character = scene.get_character(@character_name)
            if character.state != Characters::CharacterState::Walking
              @completed = true
            end
          end
        end
      end

      def finish
      end
    end

    # Character face direction
    class CharacterFaceAction < CutsceneAction
      property character_name : String
      property direction : String?
      property target : String?

      def initialize(@character_name : String, @direction : String? = nil, @target : String? = nil)
        super(0.0f32)
      end

      def start
        if scene = Core::Engine.instance.current_scene
          if character = scene.get_character(@character_name)
            if dir_str = @direction
              # Parse direction string to Direction enum
              dir = case dir_str.downcase
                    when "left"  then Characters::Direction::Left
                    when "right" then Characters::Direction::Right
                    when "up"    then Characters::Direction::Up
                    when "down"  then Characters::Direction::Down
                    else Characters::Direction::Right
                    end
              character.direction = dir
            elsif target_name = @target
              # Face towards another character
              if target_char = scene.get_character(target_name)
                # Determine direction based on relative position
                if target_char.position.x < character.position.x
                  character.direction = Characters::Direction::Left
                else
                  character.direction = Characters::Direction::Right
                end
              end
            end
          end
        end
      end

      def update_action(progress : Float32)
      end

      def finish
      end
    end

    # Character play animation
    class CharacterAnimationAction < CutsceneAction
      property character_name : String
      property animation : String

      def initialize(@character_name : String, @animation : String, duration : Float32 = 0.0f32)
        super(duration)
      end

      def start
        if scene = Core::Engine.instance.current_scene
          if character = scene.get_character(@character_name)
            character.play_animation(@animation)
          end
        end
      end

      def update_action(progress : Float32)
      end

      def finish
      end
    end

    # ============================================================
    # DIALOG ACTIONS
    # ============================================================

    # Floating dialog bubble
    class FloatingDialogAction < CutsceneAction
      property character_name : String
      property text : String
      property style : String
      property shake : Bool
      property shake_intensity : Float32

      def initialize(
        @character_name : String,
        @text : String,
        duration : Float32 = 3.0f32,
        @style : String = "normal",
        @shake : Bool = false,
        @shake_intensity : Float32 = 2.0f32
      )
        super(duration)
      end

      def start
        if scene = Core::Engine.instance.current_scene
          if character = scene.get_character(@character_name)
            character.say(@text) { nil }
          end
        end
      end

      def update_action(progress : Float32)
      end

      def finish
      end
    end

    # ============================================================
    # UI ACTIONS
    # ============================================================

    # Letterbox (cinematic bars)
    class LetterboxAction < CutsceneAction
      property enabled : Bool
      property ratio : Float32

      @letterbox_effect : Graphics::Effects::SceneEffects::LetterboxEffect?

      def initialize(@enabled : Bool, @ratio : Float32 = 2.35f32, duration : Float32 = 0.5f32)
        super(duration)
      end

      def start
        if @enabled
          # Create and add letterbox effect
          effect = Graphics::Effects::SceneEffects::LetterboxEffect.new(@ratio, 0.0f32, true)
          effect.enable(@duration)
          @letterbox_effect = effect
          Core::Engine.instance.effect_manager.add_scene_effect(effect)
        else
          # Find and disable existing letterbox effect
          Core::Engine.instance.effect_manager.scene_effects.each do |effect|
            if letterbox = effect.as?(Graphics::Effects::SceneEffects::LetterboxEffect)
              letterbox.disable(@duration)
            end
          end
        end
      end

      def update_action(progress : Float32)
      end

      def finish
      end
    end

    # Enable/disable player control
    class EnablePlayerControlAction < CutsceneAction
      property enabled : Bool

      def initialize(@enabled : Bool)
        super(0.0f32)
      end

      def start
        Core::Engine.instance.player_control_enabled = @enabled
      end

      def update_action(progress : Float32)
      end

      def finish
      end
    end

    # ============================================================
    # GAME STATE ACTIONS
    # ============================================================

    # Set game state flags and variables
    class SetGameStateAction < CutsceneAction
      property flags : Array(String)
      property variables : Hash(String, String | Int32 | Float32 | Bool)

      def initialize(@flags : Array(String) = [] of String,
                     @variables : Hash(String, String | Int32 | Float32 | Bool) = {} of String => String | Int32 | Float32 | Bool)
        super(0.0f32)
      end

      def start
        if state = Core::Engine.instance.game_state_manager
          @flags.each do |flag|
            state.set_flag(flag, true)
          end

          @variables.each do |key, value|
            case value
            when Bool
              state.set_flag(key, value)
            when Int32
              state.set_variable(key, value)
            when Float32
              state.set_variable(key, value)
            when String
              state.set_variable(key, value)
            end
          end
        end
      end

      def update_action(progress : Float32)
      end

      def finish
      end
    end
  end
end
