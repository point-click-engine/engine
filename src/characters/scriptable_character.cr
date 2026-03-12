# Scriptable character that can be controlled via Lua scripts

require "yaml"

module PointClickEngine
  module Characters
    # Scriptable character that replaces complex AI behaviors with Lua scripts
    class ScriptableCharacter < Character
      property script_file : String?
      property script_content : String?
      property custom_properties : Hash(String, String) = {} of String => String

      # Script-driven behavior properties
      property auto_update : Bool = true
      property update_interval : Float32 = 1.0_f32
      property last_update : Float32 = 0.0_f32

      # Event subscriptions for cleanup
      @subscription_ids : Array(UInt64) = [] of UInt64

      def initialize
        super()
        setup_event_handlers
      end

      def initialize(name : String, position : RL::Vector2, size : RL::Vector2)
        super(name, position, size)
        setup_event_handlers
      end

      def load_script(file_path : String)
        @script_file = file_path
        begin
          @script_content = AssetLoader.read_script(file_path)
          initialize_script
        rescue ex
          Core::ErrorLogger.error("Failed to load script #{file_path}: #{ex.message}")
        end
      end

      def set_script(script_content : String)
        @script_content = script_content
        initialize_script
      end

      def set_property(key : String, value : String)
        @custom_properties[key] = value

        # Trigger property changed event
        Core::Engine.instance.event_bus.publish(
          Core::Events::CharacterPropertyChangedEvent.new(@name, key, value)
        )
      end

      def get_property(key : String) : String
        @custom_properties[key]? || ""
      end

      def update(dt : Float32)
        super(dt)

        if @auto_update
          @last_update += dt
          if @last_update >= @update_interval
            execute_update_script(dt)
            @last_update = 0.0_f32
          end
        end
      end

      def on_interact(interactor : Character)
        execute_interaction_script(interactor)
      end

      def on_look
        execute_look_script
      end

      def on_talk
        execute_talk_script
      end

      # Execute custom script function
      def execute_script_function(function_name : String, *args)
        if engine = Core::Engine.instance.script_engine
          # Set character context
          engine.set_global("this_character", @name)
          engine.set_global("this_position", {"x" => @position.x, "y" => @position.y})
          engine.set_global("this_properties", @custom_properties)

          # Call the function
          engine.call_function(function_name, *args)
        end
      end

      # Cleanup event subscriptions
      def cleanup
        event_bus = Core::Engine.instance.event_bus
        @subscription_ids.each do |id|
          event_bus.unsubscribe(id)
        end
        @subscription_ids.clear
      end

      private def initialize_script
        return unless @script_content

        if engine = Core::Engine.instance.script_engine
          # Set up character-specific environment
          engine.set_global("character_name", @name)

          # Execute the script to define functions
          engine.execute_script(@script_content.not_nil!)

          # Call initialization function if it exists
          execute_script_function("on_init")
        end
      end

      private def execute_update_script(dt : Float32)
        execute_script_function("on_update", dt)
      end

      private def execute_interaction_script(interactor : Character)
        execute_script_function("on_interact", interactor.name)
      end

      private def execute_look_script
        execute_script_function("on_look")
      end

      private def execute_talk_script
        execute_script_function("on_talk")
      end

      private def setup_event_handlers
        event_bus = Core::Engine.instance.event_bus
        char_name = @name

        # Add handler for when character reaches movement target
        id = event_bus.subscribe(Core::Events::CharacterReachedTargetEvent) do |event|
          if event.character_name == char_name
            execute_script_function("on_movement_complete")
          end
        end
        @subscription_ids << id

        # Add handler for animation completion
        id = event_bus.subscribe(Core::Events::AnimationCompleteEvent) do |event|
          if event.character_name == char_name
            execute_script_function("on_animation_complete", event.animation_name)
          end
        end
        @subscription_ids << id
      end

      # Override movement to trigger events
      def walk_to(target : RL::Vector2)
        super(target)

        Core::Engine.instance.event_bus.publish(
          Core::Events::CharacterMoveStartEvent.new(@name, @position, target)
        )
      end

      def stop_walking
        was_walking = state == CharacterState::Walking
        super()

        if was_walking
          Core::Engine.instance.event_bus.publish(
            Core::Events::CharacterReachedTargetEvent.new(@name, @position)
          )
        end
      end

      # Override say to trigger events
      def say(text : String, &block : -> Nil)
        Core::Engine.instance.event_bus.publish(
          Core::Events::CharacterSpeakEvent.new(@name, text)
        )

        super(text, &block)
      end
    end

    # Simplified NPC that uses scripting instead of complex AI
    class SimpleNPC < ScriptableCharacter
      property dialogues : Array(String) = [] of String
      property current_dialogue_index : Int32 = 0
      property can_repeat_dialogues : Bool = true

      def initialize(name : String, position : RL::Vector2, size : RL::Vector2)
        super(name, position, size)
      end

      def add_dialogue(text : String)
        @dialogues << text
      end

      def set_dialogues(dialogues : Array(String))
        @dialogues = dialogues
      end

      def on_interact(interactor : Character)
        # If no script is loaded, use simple dialogue system
        if @script_content.nil? && !@dialogues.empty?
          dialogue_text = @dialogues[@current_dialogue_index]
          say(dialogue_text) { advance_dialogue }
        else
          super(interactor)
        end
      end

      def on_look
        if @script_content.nil?
          say(@description) { }
        else
          super()
        end
      end

      def on_talk
        if @script_content.nil?
          on_interact(Core::Engine.instance.current_scene.try(&.player) || Characters::Player.new("", RL::Vector2.new, RL::Vector2.new))
        else
          super()
        end
      end

      private def advance_dialogue
        @current_dialogue_index += 1
        if @current_dialogue_index >= @dialogues.size
          @current_dialogue_index = @can_repeat_dialogues ? 0 : (@dialogues.size - 1)
        end
      end
    end
  end
end
