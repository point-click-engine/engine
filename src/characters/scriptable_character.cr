# Scriptable character that can be controlled via Lua scripts

require "yaml"

module PointClickEngine
  module Characters
    # Scriptable character that replaces complex AI behaviors with Lua scripts
    class ScriptableCharacter < Character
      property script_file : String?
      property script_content : String?
      @[YAML::Field(ignore: true)]
      property event_handlers : Array(Scripting::EventHandler) = [] of Scripting::EventHandler
      property custom_properties : Hash(String, String) = {} of String => String

      # Script-driven behavior properties
      property auto_update : Bool = true
      property update_interval : Float32 = 1.0_f32
      property last_update : Float32 = 0.0_f32

      def initialize
        super()
        setup_default_event_handlers
      end

      def initialize(name : String, position : RL::Vector2, size : RL::Vector2)
        super(name, position, size)
        setup_default_event_handlers
      end

      def load_script(file_path : String)
        @script_file = file_path
        begin
          @script_content = File.read(file_path)
          initialize_script
        rescue ex
          puts "Failed to load script #{file_path}: #{ex.message}"
        end
      end

      def set_script(script_content : String)
        @script_content = script_content
        initialize_script
      end

      def add_event_handler(handler : Scripting::EventHandler)
        @event_handlers << handler
        Core::Engine.instance.event_system.add_handler(handler)
      end

      def set_property(key : String, value : String)
        @custom_properties[key] = value
        
        # Trigger property changed event
        Core::Engine.instance.event_system.trigger_event(
          "character_property_changed",
          {
            "character" => @name,
            "property" => key,
            "value" => value
          }
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

      private def setup_default_event_handlers
        # Add handler for when character reaches movement target
        movement_handler = Scripting::FunctionEventHandler.new(
          ->(event : Scripting::Event) {
            if event.get_string("character") == @name
              execute_script_function("on_movement_complete")
            end
            true
          },
          [Scripting::Events::CHARACTER_REACHED_TARGET]
        )
        @event_handlers << movement_handler
        
        # Add handler for animation completion
        animation_handler = Scripting::FunctionEventHandler.new(
          ->(event : Scripting::Event) {
            if event.get_string("character") == @name
              execute_script_function("on_animation_complete", event.get_string("animation"))
            end
            true
          },
          [Scripting::Events::CHARACTER_ANIMATION_COMPLETE]
        )
        @event_handlers << animation_handler
      end

      # Override movement to trigger events
      def walk_to(target : RL::Vector2)
        super(target)
        
        Core::Engine.instance.event_system.trigger_event(
          Scripting::Events::PLAYER_MOVED,
          {
            "character" => @name,
            "target_x" => target.x.to_s,
            "target_y" => target.y.to_s
          }
        )
      end

      def stop_walking
        was_walking = @state == CharacterState::Walking
        super()
        
        if was_walking
          Core::Engine.instance.event_system.trigger_event(
            Scripting::Events::CHARACTER_REACHED_TARGET,
            {
              "character" => @name,
              "position_x" => @position.x.to_s,
              "position_y" => @position.y.to_s
            }
          )
        end
      end

      # Override say to trigger events
      def say(text : String, &block : -> Nil)
        Core::Engine.instance.event_system.trigger_event(
          Scripting::Events::CHARACTER_SPEAK,
          {
            "character" => @name,
            "text" => text
          }
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
          say(@description) {}
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