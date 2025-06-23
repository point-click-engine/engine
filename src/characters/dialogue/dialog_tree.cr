# Dialog tree system for complex branching conversations like in adventure games

require "yaml"

module PointClickEngine
  module Characters
    module Dialogue
      # Represents a node in a dialog tree
      class DialogNode
        include YAML::Serializable

        property id : String
        property text : String
        property character_name : String?
        property choices : Array(DialogChoice) = [] of DialogChoice
        property conditions : Array(String) = [] of String # Script conditions
        property actions : Array(String) = [] of String    # Actions to execute
        property is_end : Bool = false

        def initialize(@id : String, @text : String)
        end

        def initialize
          @id = ""
          @text = ""
        end

        def add_choice(choice : DialogChoice)
          @choices << choice
        end
      end

      # Represents a choice option in a dialog
      class DialogChoice
        include YAML::Serializable

        property text : String
        property target_node_id : String
        property conditions : Array(String) = [] of String # Script conditions
        property actions : Array(String) = [] of String    # Actions to execute
        property once_only : Bool = false
        property used : Bool = false

        def initialize(@text : String, @target_node_id : String)
        end

        def initialize
          @text = ""
          @target_node_id = ""
        end

        def available? : Bool
          return false if @once_only && @used
          # TODO: Check conditions with script engine
          true
        end
      end

      # Dialog tree manager for complex conversations
      class DialogTree
        include YAML::Serializable

        property name : String
        property nodes : Hash(String, DialogNode) = {} of String => DialogNode
        property current_node_id : String?
        property variables : Hash(String, String) = {} of String => String
        @[YAML::Field(ignore: true)]
        property on_complete : Proc(Nil)?

        def initialize(@name : String)
        end

        def initialize
          @name = ""
        end

        def add_node(node : DialogNode)
          @nodes[node.id] = node
        end

        def start_conversation(starting_node_id : String)
          @current_node_id = starting_node_id
          show_current_node
        end

        def make_choice(choice_index : Int32)
          return unless current_node = get_current_node

          # Get available choices and use the index on the filtered list
          available_choices = current_node.choices.select(&.available?)
          return unless choice = available_choices[choice_index]?

          # Mark choice as used if it's once only
          if choice.once_only
            choice.used = true
          end

          # Execute choice actions
          execute_actions(choice.actions)

          # Move to target node
          @current_node_id = choice.target_node_id

          if target_node = get_current_node
            if target_node.is_end
              end_conversation
            else
              show_current_node
            end
          else
            end_conversation
          end
        end

        def get_current_node : DialogNode?
          if node_id = @current_node_id
            @nodes[node_id]?
          end
        end

        def set_variable(key : String, value : String)
          @variables[key] = value
        end

        def get_variable(key : String) : String?
          @variables[key]?
        end

        private def show_current_node
          return unless current_node = get_current_node

          # Execute node actions
          execute_actions(current_node.actions)

          # Show character's spoken line as floating text
          show_character_speech(current_node)

          # Get available choices
          available_choices = current_node.choices.select(&.available?)

          if available_choices.empty?
            # No choices, end conversation immediately
            end_conversation
            return
          end

          # Show dialog choices (without the spoken text, just choices)
          if dm = Core::Engine.instance.dialog_manager
            dm.show_dialog_choices("", available_choices.map(&.text)) do |choice_index|
              make_choice(choice_index)
            end
          end
        end

        private def show_character_speech(node : DialogNode)
          return unless dm = Core::Engine.instance.dialog_manager
          return if node.text.empty?

          # Clear any previous floating dialogs
          dm.floating_manager.clear_all

          # Find the speaking character
          character_name = node.character_name || @name

          if scene = Core::Engine.instance.current_scene
            if character = scene.get_character(character_name)
              # Position above character's head
              position = RL::Vector2.new(
                x: character.position.x + character.size.x / 2,
                y: character.position.y - 20
              )

              # Determine color based on character
              color = case character_name.downcase
                      when "butler"    then RL::Color.new(r: 200, g: 200, b: 255, a: 255) # Light blue
                      when "scientist" then RL::Color.new(r: 255, g: 200, b: 200, a: 255) # Light red
                      else                  RL::WHITE
                      end

              dm.show_floating_text(
                node.text, # Just the text, no character name prefix
                position,
                color: color,
                duration: 30.0
              )
            else
              # Fallback: show at center of screen if character not found
              dm.show_floating_text(
                node.text,
                RL::Vector2.new(x: 512, y: 100),
                duration: 30.0
              )
            end
          end
        end

        private def execute_actions(actions : Array(String))
          actions.each do |action|
            # TODO: Integrate with script engine to execute actions
            # For now, basic variable setting
            if action.starts_with?("set ")
              parts = action.split(" ", 3)
              if parts.size == 3
                set_variable(parts[1], parts[2])
              end
            end
          end
        end

        private def end_conversation
          @current_node_id = nil

          # Clear dialog manager's current dialog to ensure input processing resumes
          if dm = Core::Engine.instance.dialog_manager
            dm.close_current_dialog
          end

          @on_complete.try(&.call)
        end

        # Load dialog tree from YAML file
        def self.load_from_file(path : String) : DialogTree
          yaml_content = AssetLoader.read_yaml(path)
          DialogTree.from_yaml(yaml_content)
        end

        # Save dialog tree to YAML file
        def save_to_file(path : String)
          File.write(path, to_yaml)
        end
      end
    end
  end
end
