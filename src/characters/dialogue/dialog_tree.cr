# Dialog tree system for complex branching conversations like in adventure games

require "raylib-cr"
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
          return unless choice = current_node.choices[choice_index]?
          return unless choice.available?

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

          # Get available choices
          available_choices = current_node.choices.select(&.available?)

          if available_choices.empty?
            # No choices, end conversation
            end_conversation
            return
          end

          # Build dialog with choices
          choice_tuples = available_choices.map_with_index do |choice, index|
            {choice.text, -> { make_choice(index) }}
          end

          # Show dialog using character dialogue system
          if character = Core::Engine.instance.current_scene.try(&.get_character(current_node.character_name || ""))
            character.ask(current_node.text, choice_tuples)
          else
            # Fallback to simple dialog
            dialog_pos = RL::Vector2.new(x: 100, y: Core::Engine.instance.window_height - 200)
            dialog_size = RL::Vector2.new(x: Core::Engine.instance.window_width - 200, y: 150)
            dialog = UI::Dialog.new(current_node.text, dialog_pos, dialog_size)
            dialog.character_name = current_node.character_name || "Unknown"

            choice_tuples.each do |choice_text, action|
              dialog.add_choice(choice_text, &action)
            end

            Core::Engine.instance.show_dialog(dialog)
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
