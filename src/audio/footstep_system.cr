# Advanced footstep system with surface-based variations
# Provides realistic footstep audio based on character movement and surface types

require "raylib-cr"
require "../characters/character"

# Only require audio if explicitly enabled
{% if flag?(:with_audio) %}
  require "raylib-cr/audio"
{% end %}

module PointClickEngine
  module Audio
    # Surface types for different footstep sounds
    enum SurfaceType
      Stone
      Wood
      Grass
      Sand
      Water
      Metal
      Carpet
      Gravel
      Snow
      Mud
      Tile
    end

    # Footstep sound configuration for different surfaces
    struct FootstepConfig
      property surface : SurfaceType
      property sound_files : Array(String)
      property volume_range : Tuple(Float32, Float32) = {0.8f32, 1.0f32}
      property pitch_range : Tuple(Float32, Float32) = {0.9f32, 1.1f32}
      property step_interval : Float32 = 0.5f32 # Time between steps

      def initialize(@surface : SurfaceType, @sound_files : Array(String))
      end
    end

    # Surface mapping for world areas
    struct SurfaceArea
      property bounds : RL::Rectangle
      property surface : SurfaceType

      def initialize(@bounds : RL::Rectangle, @surface : SurfaceType)
      end

      def contains?(position : RL::Vector2) : Bool
        position.x >= @bounds.x && position.x <= @bounds.x + @bounds.width &&
          position.y >= @bounds.y && position.y <= @bounds.y + @bounds.height
      end
    end

    # Individual character footstep state
    class CharacterFootsteps
      property character : Characters::Character
      property step_timer : Float32 = 0.0f32
      property last_position : RL::Vector2
      property current_surface : SurfaceType = SurfaceType::Stone
      property moving : Bool = false
      property step_distance_threshold : Float32 = 32.0f32 # Pixels moved to trigger step
      property accumulated_distance : Float32 = 0.0f32

      def initialize(@character : Characters::Character)
        @last_position = @character.position
      end

      def update(dt : Float32, footstep_system : FootstepSystem)
        current_pos = @character.position

        # Calculate movement distance
        distance = Math.sqrt(
          (current_pos.x - @last_position.x) ** 2 +
          (current_pos.y - @last_position.y) ** 2
        )

        @moving = distance > 1.0f32 # Moving if distance > 1 pixel per frame

        if @moving
          @accumulated_distance += distance
          @step_timer += dt

          # Check if we should play a footstep
          surface_config = footstep_system.get_surface_config(@current_surface)
          if surface_config && @accumulated_distance >= @step_distance_threshold
            footstep_system.play_footstep(@character, @current_surface)
            @accumulated_distance = 0.0f32
          end
        else
          @step_timer = 0.0f32
          @accumulated_distance = 0.0f32
        end

        @last_position = current_pos
      end

      def set_surface(surface : SurfaceType)
        @current_surface = surface
      end
    end

    # Main footstep system
    class FootstepSystem
      property surface_configs : Hash(SurfaceType, FootstepConfig) = {} of SurfaceType => FootstepConfig
      property surface_areas : Array(SurfaceArea) = [] of SurfaceArea
      property character_footsteps : Hash(String, CharacterFootsteps) = {} of String => CharacterFootsteps
      {% if flag?(:with_audio) %}
        property loaded_sounds : Hash(String, RAudio::Sound) = {} of String => RAudio::Sound
      {% else %}
        property loaded_sounds : Hash(String, String) = {} of String => String
      {% end %}
      property global_volume : Float32 = 1.0f32
      property enabled : Bool = true

      def initialize
        setup_default_surfaces
      end

      # Register a character for footstep tracking
      def register_character(character : Characters::Character)
        @character_footsteps[character.name] = CharacterFootsteps.new(character)
      end

      # Remove character from footstep tracking
      def unregister_character(character_name : String)
        @character_footsteps.delete(character_name)
      end

      # Add surface configuration
      def add_surface_config(config : FootstepConfig)
        @surface_configs[config.surface] = config

        # Load sound files
        config.sound_files.each do |file|
          load_sound_file(file) unless @loaded_sounds.has_key?(file)
        end
      end

      # Add surface area mapping
      def add_surface_area(area : SurfaceArea)
        @surface_areas << area
      end

      # Get surface configuration
      def get_surface_config(surface : SurfaceType) : FootstepConfig?
        @surface_configs[surface]?
      end

      # Play footstep sound for character
      def play_footstep(character : Characters::Character, surface : SurfaceType)
        return unless @enabled
        return unless config = @surface_configs[surface]?
        return if config.sound_files.empty?

        # Choose random sound file
        sound_file = config.sound_files.sample
        return unless @loaded_sounds.has_key?(sound_file)

        # Random volume and pitch variation
        volume = Random.rand * (config.volume_range[1] - config.volume_range[0]) + config.volume_range[0]
        pitch = Random.rand * (config.pitch_range[1] - config.pitch_range[0]) + config.pitch_range[0]

        # Apply global volume
        final_volume = volume * @global_volume

        # Play sound with variations
        {% if flag?(:with_audio) %}
          if sound = @loaded_sounds[sound_file]?
            RAudio.set_sound_volume(sound, final_volume)
            RAudio.set_sound_pitch(sound, pitch)
            RAudio.play_sound(sound)
          end
        {% end %}
      end

      # Update all character footsteps
      def update(dt : Float32)
        return unless @enabled

        @character_footsteps.each_value do |char_footsteps|
          # Update surface based on character position
          surface = detect_surface_at_position(char_footsteps.character.position)
          char_footsteps.set_surface(surface)

          # Update footstep timing
          char_footsteps.update(dt, self)
        end
      end

      # Detect surface type at position
      def detect_surface_at_position(position : RL::Vector2) : SurfaceType
        # Check surface areas in reverse order (last added has priority)
        @surface_areas.reverse_each do |area|
          return area.surface if area.contains?(position)
        end

        # Default surface
        SurfaceType::Stone
      end

      # Set global volume
      def set_volume(volume : Float32)
        @global_volume = volume.clamp(0.0f32, 1.0f32)
      end

      # Enable/disable footstep system
      def set_enabled(enabled : Bool)
        @enabled = enabled
      end

      # Clear all surface areas
      def clear_surface_areas
        @surface_areas.clear
      end

      # Add convenience method for common room setup
      def setup_room_surfaces(room_bounds : RL::Rectangle, primary_surface : SurfaceType)
        clear_surface_areas
        add_surface_area(SurfaceArea.new(room_bounds, primary_surface))
      end

      # Cleanup resources
      def cleanup
        {% if flag?(:with_audio) %}
          @loaded_sounds.each_value { |sound| RAudio.unload_sound(sound) }
        {% end %}
        @loaded_sounds.clear
        @character_footsteps.clear
        @surface_areas.clear
      end

      private def setup_default_surfaces
        # Stone footsteps
        stone_config = FootstepConfig.new(
          SurfaceType::Stone,
          ["assets/sounds/footsteps/stone1.wav", "assets/sounds/footsteps/stone2.wav", "assets/sounds/footsteps/stone3.wav"]
        )
        stone_config.volume_range = {0.7f32, 0.9f32}
        stone_config.pitch_range = {0.95f32, 1.05f32}
        add_surface_config(stone_config)

        # Wood footsteps
        wood_config = FootstepConfig.new(
          SurfaceType::Wood,
          ["assets/sounds/footsteps/wood1.wav", "assets/sounds/footsteps/wood2.wav", "assets/sounds/footsteps/wood3.wav"]
        )
        wood_config.volume_range = {0.6f32, 0.8f32}
        wood_config.pitch_range = {0.9f32, 1.1f32}
        add_surface_config(wood_config)

        # Grass footsteps
        grass_config = FootstepConfig.new(
          SurfaceType::Grass,
          ["assets/sounds/footsteps/grass1.wav", "assets/sounds/footsteps/grass2.wav", "assets/sounds/footsteps/grass3.wav"]
        )
        grass_config.volume_range = {0.4f32, 0.6f32}
        grass_config.pitch_range = {0.8f32, 1.2f32}
        add_surface_config(grass_config)

        # Sand footsteps
        sand_config = FootstepConfig.new(
          SurfaceType::Sand,
          ["assets/sounds/footsteps/sand1.wav", "assets/sounds/footsteps/sand2.wav"]
        )
        sand_config.volume_range = {0.5f32, 0.7f32}
        sand_config.pitch_range = {0.85f32, 1.15f32}
        add_surface_config(sand_config)

        # Water footsteps (splashing)
        water_config = FootstepConfig.new(
          SurfaceType::Water,
          ["assets/sounds/footsteps/water1.wav", "assets/sounds/footsteps/water2.wav", "assets/sounds/footsteps/water3.wav"]
        )
        water_config.volume_range = {0.6f32, 0.8f32}
        water_config.pitch_range = {0.9f32, 1.1f32}
        add_surface_config(water_config)

        # Metal footsteps
        metal_config = FootstepConfig.new(
          SurfaceType::Metal,
          ["assets/sounds/footsteps/metal1.wav", "assets/sounds/footsteps/metal2.wav"]
        )
        metal_config.volume_range = {0.8f32, 1.0f32}
        metal_config.pitch_range = {0.95f32, 1.05f32}
        add_surface_config(metal_config)

        # Carpet footsteps (muffled)
        carpet_config = FootstepConfig.new(
          SurfaceType::Carpet,
          ["assets/sounds/footsteps/carpet1.wav", "assets/sounds/footsteps/carpet2.wav"]
        )
        carpet_config.volume_range = {0.3f32, 0.5f32}
        carpet_config.pitch_range = {0.9f32, 1.1f32}
        add_surface_config(carpet_config)
      end

      private def load_sound_file(file_path : String)
        {% if flag?(:with_audio) %}
          begin
            sound = RAudio.load_sound(file_path)
            @loaded_sounds[file_path] = sound
          rescue
            puts "Warning: Could not load footstep sound #{file_path}"
          end
        {% else %}
          @loaded_sounds[file_path] = file_path
        {% end %}
      end
    end
  end
end
