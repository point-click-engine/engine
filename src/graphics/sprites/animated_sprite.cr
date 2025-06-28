# Frame-based animated sprite class

require "raylib-cr"
require "./sprite"

module PointClickEngine
  module Graphics
    module Sprites
      # Animated sprite with frame-based animation support
      #
      # AnimatedSprite extends the base Sprite class to support sprite sheet
      # animations with configurable timing, looping, and playback control.
      #
      # ## Example
      #
      # ```
      # # Create an 8-frame walk animation
      # sprite = AnimatedSprite.new("assets/character_walk.png", 64, 64, 8)
      # sprite.frame_duration = 0.1 # 10 FPS
      # sprite.play
      #
      # # One-shot animation
      # explosion = AnimatedSprite.new("explosion.png", 128, 128, 12)
      # explosion.loop = false
      # explosion.on_complete do
      #   scene.remove_object(explosion)
      # end
      # ```
      class AnimatedSprite < Sprite
        # Animation properties
        property frame_width : Int32
        property frame_height : Int32
        property frame_count : Int32
        property current_frame : Int32 = 0
        property frame_duration : Float32 = 0.1f32 # Time per frame in seconds
        property loop : Bool = true
        property playing : Bool = false

        # Alias for frame_duration for compatibility
        def frame_speed=(value : Float32)
          @frame_duration = value
        end

        def frame_speed : Float32
          @frame_duration
        end

        # Animation state
        @frame_timer : Float32 = 0.0f32
        @animation_complete : Bool = false

        # Callbacks
        @on_complete : Proc(Nil)?
        @on_frame_change : Proc(Int32, Nil)?

        # Initialize with sprite sheet
        def initialize(texture_path : String, @frame_width : Int32,
                       @frame_height : Int32, @frame_count : Int32)
          super(texture_path)
          update_source_rect
        end

        # Initialize at position
        def initialize(x : Float32, y : Float32, texture_path : String,
                       @frame_width : Int32, @frame_height : Int32, @frame_count : Int32)
          super(x, y, texture_path)
          update_source_rect
        end

        # Start playing animation
        def play
          @playing = true
          @animation_complete = false
        end

        # Stop animation
        def stop
          @playing = false
        end

        # Reset animation to first frame
        def reset
          @current_frame = 0
          @frame_timer = 0.0f32
          @animation_complete = false
          update_source_rect
        end

        # Play animation once
        def play_once(&on_complete : ->)
          @loop = false
          @on_complete = on_complete
          play
        end

        # Set callback for frame changes
        def on_frame_change(&block : Int32 ->)
          @on_frame_change = block
        end

        # Set specific frame
        def set_frame(frame : Int32)
          @current_frame = frame.clamp(0, @frame_count - 1)
          update_source_rect
          @on_frame_change.try(&.call(@current_frame))
        end

        # Update animation
        def update(dt : Float32)
          super # Call base update (for effects when implemented)

          return unless @playing
          return if @animation_complete

          @frame_timer += dt

          if @frame_timer >= @frame_duration
            @frame_timer -= @frame_duration
            advance_frame
          end
        end

        # Get total animation duration
        def total_duration : Float32
          @frame_count * @frame_duration
        end

        # Get animation progress (0.0 to 1.0)
        def progress : Float32
          return 1.0f32 if @animation_complete
          (@current_frame + @frame_timer / @frame_duration) / @frame_count
        end

        # Check if animation finished (for non-looping)
        def finished? : Bool
          @animation_complete
        end

        # Clone the animated sprite
        def clone : AnimatedSprite
          sprite = AnimatedSprite.new(@texture_path || "", @frame_width,
            @frame_height, @frame_count)

          # Copy base sprite properties
          sprite.position = @position.dup
          sprite.origin = @origin.dup
          sprite.scale = @scale
          sprite.rotation = @rotation
          sprite.tint = @tint
          sprite.visible = @visible

          # Copy animation properties
          sprite.current_frame = @current_frame
          sprite.frame_duration = @frame_duration
          sprite.loop = @loop
          sprite.playing = @playing

          sprite
        end

        private def advance_frame
          old_frame = @current_frame
          @current_frame += 1

          if @current_frame >= @frame_count
            if @loop
              @current_frame = 0
            else
              @current_frame = @frame_count - 1
              @animation_complete = true
              @playing = false
              @on_complete.try(&.call)
            end
          end

          if @current_frame != old_frame
            update_source_rect
            @on_frame_change.try(&.call(@current_frame))
          end
        end

        private def update_source_rect
          # Calculate position in sprite sheet
          # Assumes horizontal layout (all frames in a row)
          @source_rect = RL::Rectangle.new(
            x: (@current_frame * @frame_width).to_f32,
            y: 0.0f32,
            width: @frame_width.to_f32,
            height: @frame_height.to_f32
          )
        end
      end

      # Animation definition for data-driven animations
      class AnimationDef
        property name : String
        property frames : Array(Int32)    # Frame indices
        property frame_duration : Float32 # Duration per frame
        property loop : Bool = true

        def initialize(@name : String, @frames : Array(Int32),
                       @frame_duration : Float32, @loop : Bool = true)
        end

        # Create from frame range
        def self.from_range(name : String, start_frame : Int32, end_frame : Int32,
                            frame_duration : Float32, loop : Bool = true) : AnimationDef
          frames = (start_frame..end_frame).to_a
          new(name, frames, frame_duration, loop)
        end
      end

      # Enhanced animated sprite with named animations
      class MultiAnimationSprite < AnimatedSprite
        @animations = {} of String => AnimationDef
        @current_animation : String?
        @current_animation_frame : Int32 = 0

        # Add an animation definition
        def add_animation(animation : AnimationDef)
          @animations[animation.name] = animation
        end

        # Add animation from parameters
        def add_animation(name : String, frames : Array(Int32),
                          frame_duration : Float32, loop : Bool = true)
          add_animation(AnimationDef.new(name, frames, frame_duration, loop))
        end

        # Add animation from frame range
        def add_animation_range(name : String, start_frame : Int32, end_frame : Int32,
                                frame_duration : Float32, loop : Bool = true)
          add_animation(AnimationDef.from_range(name, start_frame, end_frame,
            frame_duration, loop))
        end

        # Play a named animation
        def play_animation(name : String)
          return unless animation = @animations[name]?

          @current_animation = name
          @current_animation_frame = 0
          @frame_count = animation.frames.size
          @frame_duration = animation.frame_duration
          @loop = animation.loop

          # Set to first frame of animation
          @current_frame = animation.frames[0]
          update_source_rect

          play
        end

        # Get current animation name
        def current_animation_name : String?
          @current_animation
        end

        # Override advance frame to use animation definition
        private def advance_frame
          return super unless @current_animation
          return unless animation = @animations[@current_animation]?

          old_frame = @current_frame
          @current_animation_frame += 1

          if @current_animation_frame >= animation.frames.size
            if animation.loop
              @current_animation_frame = 0
            else
              @current_animation_frame = animation.frames.size - 1
              @animation_complete = true
              @playing = false
              @on_complete.try(&.call)
            end
          end

          @current_frame = animation.frames[@current_animation_frame]

          if @current_frame != old_frame
            update_source_rect
            @on_frame_change.try(&.call(@current_frame))
          end
        end
      end
    end
  end
end
