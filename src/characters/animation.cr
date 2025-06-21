# Enhanced animation system for 8-directional character movement
# and context-specific animations for adventure game interactions.

require "raylib-cr"
require "yaml"

module PointClickEngine
  module Characters
    # Enhanced 8-directional movement for adventure games
    enum Direction8
      North
      NorthEast
      East
      SouthEast
      South
      SouthWest
      West
      NorthWest
      
      # Convert from velocity vector to direction
      def self.from_velocity(velocity : RL::Vector2) : Direction8
        return Direction8::South if velocity.x == 0 && velocity.y == 0
        
        angle = Math.atan2(velocity.y, velocity.x)
        # Normalize angle to 0-2π
        angle = angle + 2 * Math::PI if angle < 0
        
        # Convert to 8 directions (each direction covers 45 degrees)
        direction_index = ((angle + Math::PI / 8) / (Math::PI / 4)).to_i % 8
        
        case direction_index
        when 0 then Direction8::East
        when 1 then Direction8::SouthEast
        when 2 then Direction8::South
        when 3 then Direction8::SouthWest
        when 4 then Direction8::West
        when 5 then Direction8::NorthWest
        when 6 then Direction8::North
        when 7 then Direction8::NorthEast
        else Direction8::South
        end
      end
      
      # Get opposite direction for turn animations
      def opposite : Direction8
        case self
        when .north? then Direction8::South
        when .north_east? then Direction8::SouthWest
        when .east? then Direction8::West
        when .south_east? then Direction8::NorthWest
        when .south? then Direction8::North
        when .south_west? then Direction8::NorthEast
        when .west? then Direction8::East
        when .north_west? then Direction8::SouthEast
        else Direction8::South  # Default fallback
        end
      end
      
      # Calculate angle difference for turn animations
      def angle_difference(other : Direction8) : Float32
        angles = {
          Direction8::North => 0.0f32,
          Direction8::NorthEast => 45.0f32,
          Direction8::East => 90.0f32,
          Direction8::SouthEast => 135.0f32,
          Direction8::South => 180.0f32,
          Direction8::SouthWest => 225.0f32,
          Direction8::West => 270.0f32,
          Direction8::NorthWest => 315.0f32
        }
        
        diff = (angles[other] - angles[self]).abs
        Math.min(diff, 360.0f32 - diff)
      end
    end

    # Enhanced animation states for adventure games
    enum AnimationState
      Idle
      Walking
      Talking
      PickingUp
      Using
      Pushing
      Pulling
      Climbing
      Sitting
      Standing
      Dying
      Custom
      
      # Get the animation name for a specific direction
      def with_direction(direction : Direction8) : String
        case self
        when .walking?
          "walk_#{direction.to_s.downcase}"
        when .talking?
          "talk_#{direction.to_s.downcase}"
        else
          self.to_s.downcase
        end
      end
    end

    # Animation data with enhanced features
    struct EnhancedAnimationData
      include YAML::Serializable
      
      property start_frame : Int32
      property frame_count : Int32
      property frame_speed : Float32
      property loop : Bool
      property priority : Int32 = 0
      property interruptible : Bool = true
      property auto_return_to_idle : Bool = true
      property sound_effect : String?
      
      def initialize(@start_frame : Int32 = 0, @frame_count : Int32 = 1,
                     @frame_speed : Float32 = 0.1, @loop : Bool = true,
                     @priority : Int32 = 0, @interruptible : Bool = true,
                     @auto_return_to_idle : Bool = true, @sound_effect : String? = nil)
      end
    end

    # Enhanced animation controller for adventure game characters
    class AnimationController
      property animations : Hash(String, EnhancedAnimationData)
      property current_animation : String = "idle"
      property current_direction : Direction8 = Direction8::South
      property last_direction : Direction8 = Direction8::South
      property idle_timer : Float32 = 0.0
      property idle_variations : Array(String) = [] of String
      property turn_threshold : Float32 = 45.0f32
      
      # Constants
      IDLE_TRIGGER_TIME = 8.0f32
      TURN_ANIMATION_SPEED = 2.0f32
      
      def initialize
        @animations = {} of String => EnhancedAnimationData
        setup_default_animations
      end
      
      # Add an animation with enhanced features
      def add_animation(name : String, start_frame : Int32, frame_count : Int32,
                       frame_speed : Float32 = 0.1, loop : Bool = true,
                       priority : Int32 = 0, interruptible : Bool = true,
                       auto_return_to_idle : Bool = true, sound_effect : String? = nil)
        @animations[name] = EnhancedAnimationData.new(
          start_frame, frame_count, frame_speed, loop,
          priority, interruptible, auto_return_to_idle, sound_effect
        )
      end
      
      # Add directional animations (8 directions for one animation type)
      def add_directional_animation(base_name : String, start_frame : Int32, 
                                   frames_per_direction : Int32, frame_speed : Float32 = 0.1)
        directions = [
          Direction8::North, Direction8::NorthEast, Direction8::East, Direction8::SouthEast,
          Direction8::South, Direction8::SouthWest, Direction8::West, Direction8::NorthWest
        ]
        
        directions.each_with_index do |direction, i|
          animation_name = "#{base_name}_#{direction.to_s.downcase}"
          animation_start = start_frame + (i * frames_per_direction)
          add_animation(animation_name, animation_start, frames_per_direction, frame_speed)
        end
      end
      
      # Add idle variations
      def add_idle_variation(name : String, start_frame : Int32, frame_count : Int32,
                            frame_speed : Float32 = 0.2)
        full_name = "idle_#{name}"
        add_animation(full_name, start_frame, frame_count, frame_speed, 
                     loop: false, auto_return_to_idle: true)
        @idle_variations << full_name
      end
      
      # Play animation with enhanced logic
      def play_animation(name : String, force : Bool = false) : Bool
        # Check if animation exists
        return false unless @animations.has_key?(name)
        
        current_anim = @animations[@current_animation]?
        new_anim = @animations[name]
        
        # Check if current animation can be interrupted
        if current_anim && !force
          return false if !current_anim.interruptible && new_anim.priority <= current_anim.priority
        end
        
        @current_animation = name
        @idle_timer = 0.0
        
        true
      end
      
      # Update direction-based animation
      def update_directional_animation(state : AnimationState, direction : Direction8, force : Bool = false)
        # Calculate if we need a turn animation
        angle_diff = @last_direction.angle_difference(direction)
        
        if angle_diff > @turn_threshold && !force
          # Play turn animation first
          play_turn_animation(@last_direction, direction)
        else
          # Direct animation
          animation_name = state.with_direction(direction)
          play_animation(animation_name, force)
          @current_direction = direction
          @last_direction = direction
        end
      end
      
      # Update idle system
      def update_idle(dt : Float32)
        return unless @current_animation == "idle"
        
        @idle_timer += dt
        
        if @idle_timer > IDLE_TRIGGER_TIME && !@idle_variations.empty?
          # Play random idle variation
          variation = @idle_variations.sample
          if play_animation(variation)
            @idle_timer = 0.0
          end
        end
      end
      
      # Update animation controller
      def update(dt : Float32, sprite : Graphics::AnimatedSprite?)
        return unless sprite
        
        # Update idle timer
        update_idle(dt)
        
        # Check if current animation finished and should return to idle
        current_anim = @animations[@current_animation]?
        if current_anim && !current_anim.loop && 
           sprite.current_frame >= current_anim.start_frame + current_anim.frame_count - 1
          
          if current_anim.auto_return_to_idle && @current_animation != "idle"
            play_animation("idle", force: true)
          end
        end
      end
      
      # Get current animation data
      def current_animation_data : EnhancedAnimationData?
        @animations[@current_animation]?
      end
      
      # Apply animation to sprite
      def apply_to_sprite(sprite : Graphics::AnimatedSprite)
        anim_data = current_animation_data
        return unless anim_data
        
        sprite.current_frame = anim_data.start_frame
        sprite.frame_count = anim_data.frame_count
        sprite.frame_speed = anim_data.frame_speed
        sprite.loop = anim_data.loop
        
        # Play sound effect if specified
        if sound = anim_data.sound_effect
          # TODO: Play sound through audio manager
        end
      end
      
      # Setup default animations that every character should have
      private def setup_default_animations
        # Basic idle animation
        add_animation("idle", 0, 1, 1.0, true)
        
        # Default walking animations (assuming 8-direction sprite sheet)
        add_directional_animation("walk", 8, 4, 0.15)
        
        # Basic talking animation
        add_animation("talk", 64, 2, 0.3, true)
      end
      
      # Play turn animation between directions
      private def play_turn_animation(from : Direction8, to : Direction8)
        # For now, just switch directly
        # TODO: Implement smooth turn animations
        @current_direction = to
        @last_direction = to
      end
    end
    
    # Enhanced character with 8-directional animations
    abstract class EnhancedCharacter < Character
      property animation_controller : AnimationController
      property enhanced_direction : Direction8 = Direction8::South
      property movement_state : AnimationState = AnimationState::Idle
      
      def initialize
        super()
        @animation_controller = AnimationController.new
      end
      
      def initialize(@name : String, position : RL::Vector2, size : RL::Vector2)
        super(@name, position, size)
        @animation_controller = AnimationController.new
      end
      
      # Enhanced sprite loading with direction support
      def load_enhanced_spritesheet(path : String, frame_width : Int32, frame_height : Int32,
                                   directions : Int32 = 8, frames_per_direction : Int32 = 4)
        load_spritesheet(path, frame_width, frame_height)
        
        # Setup directional walking animations
        @animation_controller.add_directional_animation("walk", 0, frames_per_direction)
        
        # Setup idle variations if enough frames
        total_walk_frames = directions * frames_per_direction
        if sprite_data.try(&.frame_count) && sprite_data.not_nil!.frame_count > total_walk_frames
          remaining_frames = sprite_data.not_nil!.frame_count - total_walk_frames
          idle_start = total_walk_frames
          
          # Add idle variations
          @animation_controller.add_idle_variation("look_around", idle_start, 4)
          @animation_controller.add_idle_variation("tap_foot", idle_start + 4, 6) if remaining_frames >= 10
        end
      end
      
      # Enhanced walk_to with directional animation
      def walk_to(target : RL::Vector2)
        super(target)
        
        # Calculate direction based on movement
        if target_pos = @target_position
          velocity = RL::Vector2.new(
            x: target_pos.x - @position.x,
            y: target_pos.y - @position.y
          )
          
          if velocity.x != 0 || velocity.y != 0
            @enhanced_direction = Direction8.from_velocity(velocity)
            @movement_state = AnimationState::Walking
            @animation_controller.update_directional_animation(@movement_state, @enhanced_direction)
          end
        end
      end
      
      # Enhanced update with animation controller
      def update(dt : Float32)
        super(dt)
        
        # Update animation controller
        @animation_controller.update(dt, @sprite_data)
        
        # Apply current animation to sprite
        if sprite = @sprite_data
          @animation_controller.apply_to_sprite(sprite)
        end
        
        # Update movement state
        if @state == CharacterState::Walking && @target_position.nil?
          @movement_state = AnimationState::Idle
          @animation_controller.play_animation("idle")
        end
      end
      
      # Play enhanced animation
      def play_enhanced_animation(state : AnimationState, direction : Direction8? = nil)
        actual_direction = direction || @enhanced_direction
        @animation_controller.update_directional_animation(state, actual_direction, force: true)
        @movement_state = state
      end
      
      # Add custom animation
      def add_custom_animation(name : String, start_frame : Int32, frame_count : Int32,
                              frame_speed : Float32 = 0.1, loop : Bool = true,
                              priority : Int32 = 0, sound_effect : String? = nil)
        @animation_controller.add_animation(name, start_frame, frame_count, frame_speed, 
                                          loop, priority, true, true, sound_effect)
      end
      
      # Perform action with animation
      def perform_action(action : AnimationState, target_position : RL::Vector2? = nil)
        if target_position
          # Calculate direction to target
          direction_vec = RL::Vector2.new(
            x: target_position.x - @position.x,
            y: target_position.y - @position.y
          )
          direction = Direction8.from_velocity(direction_vec)
          play_enhanced_animation(action, direction)
        else
          play_enhanced_animation(action)
        end
      end
    end
  end
end