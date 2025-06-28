# Animated Sprite system for characters and objects

require "yaml"

module PointClickEngine
  module Graphics
    module Sprites
      # # Manages frame-based sprite animations for characters and objects.
      ##
      # # `Animated` provides a flexible animation system that supports:
      # # - Sprite sheet animations with configurable frame timing
      # # - Looping and one-shot playback modes
      # # - Dynamic scaling and positioning
      # # - Automatic texture management
      ##
      # # ## Basic Usage
      ##
      # # ```crystal
      # # # Create an animated sprite
      # # sprite = Animated.new(
      # #   position: Vector2.new(400, 300),
      # #   frame_width: 64,
      # #   frame_height: 64,
      # #   frame_count: 8
      # # )
      # # sprite.load_texture("assets/character_walk.png")
      # # sprite.frame_speed = 0.1  # 10 FPS
      # # sprite.play
      # # ```
      ##
      # # ## Sprite Sheet Layout
      ##
      # # Expects horizontal sprite sheets with frames laid out left-to-right:
      # # ```
      # # [Frame0][Frame1][Frame2][Frame3]...
      # # ```
      ##
      # # ## Advanced Animation Control
      ##
      # # ```crystal
      # # # One-shot animation
      # # explosion = Animated.new(pos, 128, 128, 12)
      # # explosion.load_texture("explosion.png")
      # # explosion.loop = false
      # # explosion.frame_speed = 0.05  # Fast playback
      # # explosion.play
      ##
      # # # Check when finished
      # # if !explosion.playing && !explosion.loop
      # #   scene.remove_object(explosion)
      # # end
      # # ```
      ##
      # # ## Frame Control
      ##
      # # ```crystal
      # # # Manual frame control
      # # sprite.playing = false
      # # sprite.current_frame = 3  # Show specific frame
      ##
      # # # Reset animation
      # # sprite.current_frame = 0
      # # sprite.frame_timer = 0.0
      # # sprite.play
      # # ```
      ##
      # # ## Scaling and Positioning
      ##
      # # ```crystal
      # # # Scale sprite (affects collision box)
      # # sprite.scale = 2.0  # Double size
      ##
      # # # Position is sprite center
      # # sprite.position = Vector2.new(400, 300)
      # # # Sprite draws centered at this position
      # # ```
      ##
      # # ## Common Gotchas
      ##
      # # 1. **Texture loading timing**: Textures require window to be initialized
      # #    ```crystal
      # #    # ❌ Won't work - window not ready
      # #    sprite = Animated.new(...)
      # #    sprite.load_texture("sprite.png")  # Called before engine.init
      ##
      # #    # ✅ Correct approach
      # #    engine.init
      # #    sprite.load_texture("sprite.png")  # Window is ready
      # #    ```
      ##
      # # 2. **Frame indexing**: Frames are 0-based
      # #    ```crystal
      # #    # For 8 frames: valid indices are 0-7
      # #    sprite.current_frame = 8  # ❌ Out of bounds!
      # #    ```
      ##
      # # 3. **Scale affects collision**: Changing scale updates bounding box
      # #    ```crystal
      # #    sprite.scale = 2.0
      # #    # sprite.size is now (frame_width * 2, frame_height * 2)
      # #    ```
      ##
      # # ## Memory Management
      ##
      # # ```crystal
      # # # Textures are cached by AssetLoader
      # # sprite1.load_texture("hero.png")
      # # sprite2.load_texture("hero.png")  # Reuses loaded texture
      ##
      # # # Manual cleanup if needed
      # # AssetLoader.unload_texture("hero.png")
      # # ```
      ##
      # # ## Subclassing
      ##
      # # ```crystal
      # # class PlayerSprite < Sprites::Animated
      # #   def initialize(position)
      # #     super(position, 64, 96, 8)  # 64x96 frames, 8 total
      # #     load_texture("assets/player.png")
      # #   end
      ##
      # #   def update(dt)
      # #     super  # Update animation
      ##
      # #     # Add custom behavior
      # #     if @current_frame == 4
      # #       # Trigger footstep sound mid-animation
      # #       AudioManager.play_sound("footstep")
      # #     end
      # #   end
      # # end
      # # ```
      ##
      # # NOTE: Sprites are drawn centered on their position, not top-left aligned
      ##
      # # ## See Also
      ##
      # # - `Character` - Uses Animated for character visuals
      # # - `AssetLoader` - Texture loading and caching
      # # - `Core::GameObject` - Base class functionality
      class Animated < PointClickEngine::Core::GameObject
        # # Path to the sprite sheet texture file.
        ##
        # # Used for serialization and lazy loading. The texture is loaded
        # # when `load_texture` is called or after deserialization.
        property texture_path : String?

        # # The loaded texture resource (runtime only).
        ##
        # # Automatically managed by AssetLoader for caching and cleanup.
        @[YAML::Field(ignore: true)]
        property texture : RL::Texture2D?

        # # Width of a single frame in pixels.
        property frame_width : Int32

        # # Height of a single frame in pixels.
        property frame_height : Int32

        # # Currently displayed frame index (0-based).
        ##
        # # Automatically advances during playback. Can be set manually
        # # for specific frame display.
        property current_frame : Int32 = 0

        # # Total number of frames in the animation.
        property frame_count : Int32

        # # Time in seconds between frame changes.
        ##
        # # Lower values = faster animation. Common values:
        # # - 0.1 = 10 FPS (default)
        # # - 0.033 = ~30 FPS
        # # - 0.016 = ~60 FPS
        property frame_speed : Float32 = 0.1

        # # Internal timer for frame advancement (runtime only).
        property frame_timer : Float32 = 0.0

        # # Whether the animation repeats after the last frame.
        ##
        # # When false, animation stops on the last frame and sets
        # # `playing = false`.
        property loop : Bool = true

        # # Whether the animation is currently playing.
        ##
        # # Set to false to pause animation on current frame.
        property playing : Bool = true

        # # Scale multiplier for sprite size.
        ##
        # # Affects both visual size and collision bounds. A scale of 2.0
        # # doubles the sprite's display size.
        property scale : Float32 = 1.0

        def initialize
          super(RL::Vector2.new, RL::Vector2.new)
          @frame_width = 0
          @frame_height = 0
          @frame_count = 0
        end

        def initialize(position : RL::Vector2, @frame_width : Int32, @frame_height : Int32, @frame_count : Int32)
          scaled_width = @frame_width * @scale
          scaled_height = @frame_height * @scale
          super(position, RL::Vector2.new(x: scaled_width, y: scaled_height))
        end

        def after_yaml_deserialize(ctx : YAML::ParseContext)
          super(ctx)
          if path = @texture_path
            if RL.window_ready?
              load_texture(path)
            end
          end
          @size = RL::Vector2.new(x: @frame_width * @scale, y: @frame_height * @scale)
        end

        # # Loads a texture from the specified file path.
        ##
        # # The texture is cached by AssetLoader for efficient memory usage.
        # # Multiple sprites can share the same texture.
        ##
        # # - *path* : Path to the sprite sheet image file
        ##
        # # ```crystal
        # # sprite.load_texture("assets/player_walk.png")
        # # ```
        ##
        # # NOTE: Requires the window to be initialized. Call after `engine.init`.
        ##
        # # RAISES: `AssetError` if the texture file cannot be loaded
        def load_texture(path : String)
          @texture_path = path
          @texture = AssetLoader.load_texture(path)
        end

        # # Starts or resumes animation playback.
        ##
        # # Resets the frame timer to ensure smooth playback from the current frame.
        # # If animation was stopped on a frame, playback continues from that frame.
        ##
        # # ```crystal
        # # sprite.play
        # # # Animation now advancing through frames
        # # ```
        def play
          @playing = true
          @frame_timer = 0.0
        end

        # # Stops animation playback.
        ##
        # # The current frame remains visible. Call `play` to resume.
        ##
        # # ```crystal
        # # sprite.stop
        # # sprite.current_frame = 0  # Optionally reset to first frame
        # # ```
        def stop
          @playing = false
        end

        # # Updates the animation state.
        ##
        # # Advances the animation based on elapsed time, handling frame
        # # transitions and looping behavior. Called automatically by the
        # # scene update loop.
        ##
        # # - *dt* : Delta time in seconds since last update
        ##
        # # ## Animation Logic
        ##
        # # 1. Accumulates time in `frame_timer`
        # # 2. When timer >= `frame_speed`, advances frame
        # # 3. Handles looping or stops at last frame
        ##
        # # ## Custom Update Example
        ##
        # # ```crystal
        # # class CustomSprite < Sprites::Animated
        # #   def update(dt)
        # #     super  # Run animation logic
        ##
        # #     # Add particle effect on specific frame
        # #     if @current_frame == 5 && @playing
        # #       emit_particles(@position)
        # #     end
        # #   end
        # # end
        # # ```
        def update(dt : Float32)
          return unless @playing && @active
          @frame_timer += dt
          if @frame_timer >= @frame_speed
            @frame_timer = 0.0
            @current_frame += 1
            if @current_frame >= @frame_count
              if @loop
                @current_frame = 0
              else
                @current_frame = @frame_count - 1
                @playing = false
              end
            end
          end
        end

        # # Renders the current animation frame.
        ##
        # # Draws the sprite centered at its position with the current scale
        # # applied. Only draws if both `visible` is true and a texture is loaded.
        ##
        # # ## Rendering Details
        ##
        # # - Sprites are drawn centered on their position
        # # - Scale affects visual size but not source frame size
        # # - Uses white tint (no color modification)
        ##
        # # ## Custom Drawing
        ##
        # # ```crystal
        # # class TintedSprite < Sprites::Animated
        # #   property tint : RL::Color = RL::WHITE
        ##
        # #   def draw
        # #     return unless @visible && tex = @texture
        ##
        # #     source_rect = RL::Rectangle.new(
        # #       x: (@current_frame * @frame_width).to_f,
        # #       y: 0.0,
        # #       width: @frame_width.to_f,
        # #       height: @frame_height.to_f
        # #     )
        ##
        # #     dest_rect = RL::Rectangle.new(
        # #       x: @position.x - (@frame_width * @scale / 2),
        # #       y: @position.y - (@frame_height * @scale / 2),
        # #       width: @frame_width * @scale,
        # #       height: @frame_height * @scale
        # #     )
        ##
        # #     # Use custom tint instead of white
        # #     RL.draw_texture_pro(tex, source_rect, dest_rect,
        # #                         RL::Vector2.new(x: 0, y: 0), 0.0, @tint)
        # #   end
        # # end
        # # ```
        ##
        # # NOTE: No rotation support in base class. Override for rotation.
        def draw
          return unless @visible
          return unless tex = @texture
          source_rect = RL::Rectangle.new(
            x: (@current_frame * @frame_width).to_f,
            y: 0.0,
            width: @frame_width.to_f,
            height: @frame_height.to_f
          )
          # Center the sprite on the position
          dest_rect = RL::Rectangle.new(
            x: @position.x - (@frame_width * @scale / 2),
            y: @position.y - (@frame_height * @scale / 2),
            width: @frame_width * @scale,
            height: @frame_height * @scale
          )
          RL.draw_texture_pro(tex, source_rect, dest_rect, RL::Vector2.new(x: 0, y: 0), 0.0, RL::WHITE)
        end
      end
    end
  end
end
