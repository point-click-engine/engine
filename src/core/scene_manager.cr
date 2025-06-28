# Scene management system for the Point & Click Engine
#
# Handles scene loading, transitions, caching, and lifecycle management.
# Extracted from the monolithic Engine class to improve separation of concerns
# and provide better scene management capabilities.

require "./error_handling"
require "./interfaces"
require "../scenes/scene"
require "../graphics/effects/scene_effects/transition_effect"

module PointClickEngine
  module Core
    # Manages all scene-related operations including loading, transitions, and caching
    #
    # The SceneManager centralizes scene handling logic that was previously
    # scattered throughout the Engine class. It provides a clean API for
    # scene operations and handles caching, preloading, and transition effects.
    #
    # ## Features
    # - Scene loading and caching
    # - Smooth scene transitions with callbacks
    # - Scene preloading for performance
    # - Error handling for missing scenes
    # - Scene validation and integrity checking
    # - Memory management for unused scenes
    #
    # ## Usage
    # ```
    # manager = SceneManager.new
    # manager.add_scene(scene)
    # manager.change_scene("main_menu")
    # ```
    class SceneManager
      include Core::GameConstants
      include ISceneManager

      # Currently active scene
      getter current_scene : Scenes::Scene?

      # Starting scene name
      property start_scene : String?

      # Collection of all loaded scenes
      getter scenes : Hash(String, Scenes::Scene) = {} of String => Scenes::Scene

      # Scene transition callbacks
      getter transition_callbacks : Hash(String, Array(Proc(Nil))) = {} of String => Array(Proc(Nil))

      # Scene enter callbacks (called when scene becomes active)
      getter scene_enter_callbacks : Hash(String, Array(Proc(Nil))) = {} of String => Array(Proc(Nil))

      # Scene exit callbacks (called when scene becomes inactive)
      getter scene_exit_callbacks : Hash(String, Array(Proc(Nil))) = {} of String => Array(Proc(Nil))

      # Cache for preloaded scenes
      @scene_cache : Hash(String, Scenes::Scene) = {} of String => Scenes::Scene

      # Maximum number of scenes to keep in cache
      @max_cache_size : Int32 = 5

      # Track scene load times for performance monitoring
      @scene_load_times : Hash(String, Time::Span) = {} of String => Time::Span

      # Reference to engine for effect manager access
      @engine : Engine?

      def initialize(@engine : Engine? = nil)
      end

      # Add a scene to the manager
      #
      # Validates the scene and adds it to the available scenes collection.
      # Does not make the scene active - use `change_scene` for that.
      #
      # - *scene* : The scene instance to add
      #
      # Returns a Result indicating success or failure
      def add_scene(scene : Scenes::Scene) : Result(Nil, SceneError)
        validation_result = validate_scene(scene)
        return Result(Nil, SceneError).failure(validation_result.error) if validation_result.failure?

        @scenes[scene.name] = scene
        Result(Nil, SceneError).success(nil)
      end

      # Add multiple scenes at once
      #
      # Validates and adds multiple scenes to the manager. If any scene
      # fails validation, none are added.
      #
      # - *scenes* : Array of scene instances to add
      def add_scenes(scenes : Array(Scenes::Scene)) : Result(Nil, SceneError)
        # Validate all scenes first
        scenes.each do |scene|
          validation_result = validate_scene(scene)
          return Result(Nil, SceneError).failure(validation_result.error) if validation_result.failure?
        end

        # Add all scenes
        scenes.each { |scene| @scenes[scene.name] = scene }
        Result(Nil, SceneError).success(nil)
      end

      # Change to a different scene
      #
      # Transitions from the current scene to the specified scene. Handles
      # exit callbacks for the current scene, loads the new scene if needed,
      # and executes enter callbacks for the new scene.
      #
      # The force_reload parameter can be used to reload the scene from
      # cache even if it's already loaded, useful for resetting scene state.
      #
      # ## Callback Order
      # 1. Exit callbacks for current scene
      # 2. Transition callbacks
      # 3. Scene activation
      # 4. Enter callbacks for new scene
      #
      # ## Performance
      # Scenes are cached after first load for faster subsequent transitions.
      # Use `force_reload` to bypass cache when scene state needs resetting.
      #
      # - *name* : Name of the scene to activate
      # - *force_reload* : Whether to reload from disk even if cached
      #
      # Returns a Result with the activated scene or an error
      def change_scene(name : String) : Result(Scenes::Scene, SceneError)
        change_scene_with_reload(name, false)
      end

      def change_scene_with_reload(name : String, force_reload : Bool = false) : Result(Scenes::Scene, SceneError)
        # Validate scene exists
        unless @scenes.has_key?(name)
          return Result(Scenes::Scene, SceneError).failure(SceneError.new("Scene not found: #{name}", name))
        end

        # Execute exit callbacks for current scene
        if current = @current_scene
          execute_scene_exit_callbacks(current)
        end

        # Load scene from cache or create new instance
        target_scene = if force_reload
                         @scene_cache.delete(name)
                         @scenes[name].dup
                       else
                         @scene_cache[name] ||= @scenes[name].dup
                       end

        # Execute transition callbacks
        execute_transition_callbacks(name)

        # Activate new scene
        @current_scene = target_scene
        target_scene.enter

        # Execute enter callbacks
        execute_scene_enter_callbacks(target_scene)

        # Track performance
        @scene_load_times[name] = Time.monotonic - Time.monotonic

        Result(Scenes::Scene, SceneError).success(target_scene)
      end

      # Change scene with a transition effect
      #
      # Performs a scene change with a visual transition effect. The transition
      # will play, changing the scene at the midpoint of the effect.
      #
      # - *name* : Name of the scene to transition to
      # - *transition_type* : Type of transition effect (fade, dissolve, slide_left, etc.)
      # - *duration* : Duration of the transition in seconds
      # - *player_position* : Optional position to place the player in the new scene
      #
      # Returns a Result with success or error
      def change_scene_with_transition(name : String, transition_type : String = "fade", 
                                     duration : Float32 = 1.0f32, 
                                     player_position : RL::Vector2? = nil) : Result(Nil, SceneError)
        # Validate scene exists
        unless @scenes.has_key?(name)
          return Result(Nil, SceneError).failure(SceneError.new("Scene not found: #{name}", name))
        end

        # Get engine reference
        engine = @engine
        unless engine
          # If no engine reference, fall back to regular scene change
          change_scene(name)
          return Result(Nil, SceneError).success(nil)
        end

        # Parse transition type
        transition_type_enum = case transition_type.downcase
        when "fade"         then Graphics::Effects::SceneEffects::TransitionType::Fade
        when "dissolve"     then Graphics::Effects::SceneEffects::TransitionType::Dissolve
        when "slide_left"   then Graphics::Effects::SceneEffects::TransitionType::SlideLeft
        when "slide_right"  then Graphics::Effects::SceneEffects::TransitionType::SlideRight
        when "slide_up"     then Graphics::Effects::SceneEffects::TransitionType::SlideUp
        when "slide_down"   then Graphics::Effects::SceneEffects::TransitionType::SlideDown
        else Graphics::Effects::SceneEffects::TransitionType::Fade
        end
        
        # Create transition effect with midpoint callback for scene change
        transition = Graphics::Effects::SceneEffects::TransitionEffect.new(transition_type_enum, duration)
        
        # Set up the midpoint callback to change the scene
        transition.on_midpoint do
          puts "[SceneManager] Transition midpoint callback triggered for scene: #{name}"
          # Use the engine's change_scene method to ensure proper synchronization
          engine.change_scene(name)
          
          # Set player position if provided
          if player_position && (player = engine.player)
            puts "[SceneManager] Setting player position to: #{player_position}"
            player.position = player_position
          end
        end
        
        # Apply the transition effect through the engine's effect manager
        engine.effect_manager.add_scene_effect(transition)
        
        Result(Nil, SceneError).success(nil)
      end

      # Preload a scene without activating it
      #
      # Loads a scene into the cache for faster switching later. Useful
      # for preloading scenes during loading screens or idle time.
      #
      # - *name* : Name of the scene to preload
      #
      # Returns the preloaded scene or an error
      def preload_scene(name : String) : Result(Scenes::Scene, SceneError)
        unless @scenes.has_key?(name)
          return Result(Scenes::Scene, SceneError).failure(SceneError.new("Scene not found: #{name}", name))
        end

        # Don't preload if already cached
        return Result(Scenes::Scene, SceneError).success(@scene_cache[name]) if @scene_cache.has_key?(name)

        # Load and cache the scene
        scene = @scenes[name].dup
        @scene_cache[name] = scene

        # Manage cache size
        trim_cache_if_needed

        Result(Scenes::Scene, SceneError).success(scene)
      end

      # Reload a scene from its definition
      #
      # Forces a scene to reload, clearing any cached state. Useful for
      # implementing "restart level" functionality.
      #
      # - *name* : Name of the scene to reload
      def reload_scene(name : String) : Result(Scenes::Scene, SceneError)
        unless @scenes.has_key?(name)
          return Result(Scenes::Scene, SceneError).failure(SceneError.new("Scene not found: #{name}", name))
        end

        # Store reference to original scene
        original_scene = @scenes[name]

        # Clear from cache
        @scene_cache.delete(name)

        # Reload if it's the current scene
        if @current_scene.try(&.name) == name
          change_scene(name, force_reload: true)
        end

        Result(Scenes::Scene, SceneError).success(original_scene)
      end

      # Remove a scene from the manager
      #
      # Removes a scene from the available scenes. Cannot remove the
      # currently active scene.
      #
      # - *name* : Name of the scene to remove
      def remove_scene(name : String) : Result(Nil, SceneError)
        unless @scenes.has_key?(name)
          return Result(Nil, SceneError).failure(SceneError.new("Scene not found: #{name}", name))
        end

        # Don't remove active scene
        if @current_scene.try(&.name) == name
          return Result(Nil, SceneError).failure(SceneError.new("Cannot remove active scene: #{name}", name))
        end

        # Remove from collections
        @scenes.delete(name)
        @scene_cache.delete(name)
        @transition_callbacks.delete(name)
        @scene_enter_callbacks.delete(name)
        @scene_exit_callbacks.delete(name)
        @scene_load_times.delete(name)

        Result(Nil, SceneError).success(nil)
      end

      # Get a scene by name
      #
      # Returns the scene if found, or an error if not found.
      #
      # - *name* : Name of the scene to retrieve
      def get_scene(name : String) : Result(Scenes::Scene, SceneError)
        if scene = @scenes[name]?
          Result(Scenes::Scene, SceneError).success(scene)
        else
          Result(Scenes::Scene, SceneError).failure(SceneError.new("Scene not found: #{name}", name))
        end
      end

      # Check if a scene exists
      #
      # - *name* : Name of the scene to check
      def has_scene?(name : String) : Bool
        @scenes.has_key?(name)
      end

      # Get list of all scene names
      def scene_names : Array(String)
        @scenes.keys.to_a
      end

      # Add a callback to be executed during scene transition
      #
      # - *name* : Name of the scene
      # - *&block* : Callback to execute during transition
      def on_scene_transition(name : String, &block : -> Nil)
        @transition_callbacks[name] ||= [] of Proc(Nil)
        @transition_callbacks[name] << block
      end

      # Add a callback to be executed when entering a scene
      #
      # - *name* : Name of the scene
      # - *&block* : Callback to execute on enter
      def on_scene_enter(name : String, &block : -> Nil)
        @scene_enter_callbacks[name] ||= [] of Proc(Nil)
        @scene_enter_callbacks[name] << block
      end

      # Add a callback to be executed when exiting a scene
      #
      # - *name* : Name of the scene
      # - *&block* : Callback to execute on exit
      def on_scene_exit(name : String, &block : -> Nil)
        @scene_exit_callbacks[name] ||= [] of Proc(Nil)
        @scene_exit_callbacks[name] << block
      end

      # Clear all cached scenes
      def clear_cache
        @scene_cache.clear
      end

      # Get cache statistics
      def cache_stats : NamedTuple(size: Int32, scenes: Array(String))
        {
          size:   @scene_cache.size,
          scenes: @scene_cache.keys.to_a,
        }
      end

      # Set maximum cache size
      #
      # - *size* : Maximum number of scenes to keep cached
      def max_cache_size=(size : Int32)
        @max_cache_size = size
        trim_cache_if_needed
      end

      # Validate a scene before adding
      #
      # Ensures scene has required properties and doesn't conflict
      # with existing scenes.
      private def validate_scene(scene : Scenes::Scene) : Result(Scenes::Scene, SceneError)
        begin
          # Check name is not empty
          scene_name = scene.name
          if scene_name.nil? || scene_name.empty?
            return Result(Scenes::Scene, SceneError).failure(SceneError.new("Scene must have a non-empty name"))
          end

          # Check for duplicate names (only if adding new scene)
          if @scenes.has_key?(scene_name) && @scenes[scene_name] != scene
            return Result(Scenes::Scene, SceneError).failure(SceneError.new("Scene with name '#{scene_name}' already exists", scene_name))
          end

          # Return the scene as-is, without type constraint
          Result(Scenes::Scene, SceneError).success(scene.as(Scenes::Scene))
        rescue ex
          ErrorLogger.error("Failed to validate scene: #{ex.message}")
          Result(Scenes::Scene, SceneError).failure(SceneError.new("Scene validation failed: #{ex.message}"))
        end
      end

      # Execute transition callbacks for a scene
      private def execute_transition_callbacks(name : String)
        if callbacks = @transition_callbacks[name]?
          callbacks.each(&.call)
        end
      end

      # Execute enter callbacks for a scene
      private def execute_scene_enter_callbacks(scene : Scenes::Scene)
        if callbacks = @scene_enter_callbacks[scene.name]?
          callbacks.each(&.call)
        end
      end

      # Execute exit callbacks for a scene
      private def execute_scene_exit_callbacks(scene : Scenes::Scene)
        if callbacks = @scene_exit_callbacks[scene.name]?
          callbacks.each(&.call)
        end
      end

      # Trim cache to maximum size
      private def trim_cache_if_needed
        while @scene_cache.size > @max_cache_size
          # Remove least recently used scene (simple FIFO for now)
          oldest_key = @scene_cache.keys.first
          @scene_cache.delete(oldest_key)
        end
      end
    end

    # Scene-related error class
    class SceneError < LoadingError
      getter scene_name : String?

      def initialize(message : String, @scene_name : String? = nil)
        super(message, @scene_name)
      end
    end
  end
end
