# ActionLoader - Loads action sequences from YAML files
# Converts YAML data to ActionData structs for the ActionRunner
#
# Supports:
# - Basic actions with all parameters
# - Parallel action groups
# - Variables section for reusable values
# - Conditions section for conditional execution
# - Checkpoints for skip/resume points

require "yaml"
require "./action"
require "./action_runner"
require "../assets/asset_loader"
require "../core/exceptions"

module PointClickEngine
  module Actions
    # Represents a conditional action block
    struct ActionCondition
      property name : String
      property check : String
      property actions : Array(ActionData)
      property skip_to : String?

      def initialize(@name : String, @check : String, @actions : Array(ActionData) = [] of ActionData, @skip_to : String? = nil)
      end
    end

    # Represents a checkpoint in the action sequence
    struct ActionCheckpoint
      property name : String
      property time : Float32
      property action_index : Int32

      def initialize(@name : String, @time : Float32 = 0.0f32, @action_index : Int32 = 0)
      end
    end

    class ActionLoader
      # Load an action sequence from a YAML file
      def self.load(path : String) : ActionRunner
        begin
          yaml_content = PointClickEngine::AssetLoader.read_yaml(path)
          data = YAML.parse(yaml_content)
        rescue ex
          raise Core::LoadingError.new("Failed to load action sequence file '#{path}': #{ex.message}")
        end

        name = data["name"]?.try(&.as_s) || File.basename(path, ".yaml")
        runner = ActionRunner.new(name)

        # Set properties
        if skippable = data["skippable"]?
          runner.skippable = skippable.as_bool
        end

        if auto_advance = data["auto_advance"]?
          runner.auto_advance = auto_advance.as_bool
        end

        # Parse variables section first (for substitution)
        variables = parse_variables(data)
        runner.variables = variables

        # Parse checkpoints
        checkpoints = parse_checkpoints(data)
        runner.checkpoints = checkpoints

        # Parse conditions
        conditions = parse_conditions(data, variables)
        runner.conditions = conditions

        # Parse main actions
        if actions_data = data["actions"]?
          parse_actions(actions_data.as_a, runner, variables)
        end

        # Update checkpoint action indices based on parsed actions
        update_checkpoint_indices(runner)

        runner
      end

      # Parse the variables section
      private def self.parse_variables(data : YAML::Any) : Hash(String, YAML::Any)
        variables = {} of String => YAML::Any

        if vars = data["variables"]?
          vars.as_h.each do |key, value|
            variables[key.to_s] = value
          end
        end

        variables
      end

      # Parse the checkpoints section
      private def self.parse_checkpoints(data : YAML::Any) : Array(ActionCheckpoint)
        checkpoints = [] of ActionCheckpoint

        if cps = data["checkpoints"]?
          cps.as_a.each do |cp|
            name = cp["name"]?.try(&.as_s) || next
            time = get_float(cp, "time", 0.0f32)
            checkpoints << ActionCheckpoint.new(name, time)
          end
        end

        checkpoints
      end

      # Parse the conditions section
      private def self.parse_conditions(data : YAML::Any, variables : Hash(String, YAML::Any)) : Array(ActionCondition)
        conditions = [] of ActionCondition

        if conds = data["conditions"]?
          conds.as_a.each do |cond|
            name = cond["name"]?.try(&.as_s) || next
            check = cond["check"]?.try(&.as_s) || next
            skip_to = cond["skip_to"]?.try(&.as_s)

            actions = [] of ActionData
            if cond_actions = cond["actions"]?
              cond_actions.as_a.each do |action_data|
                if action = parse_action_data(action_data, variables)
                  actions << action
                end
              end
            end

            conditions << ActionCondition.new(name, check, actions, skip_to)
          end
        end

        conditions
      end

      # Parse an array of actions
      private def self.parse_actions(actions_data : Array(YAML::Any), runner : ActionRunner, variables : Hash(String, YAML::Any))
        actions_data.each do |action_data|
          parse_and_add_action(action_data, runner, variables)
        end
      end

      # Parse a single action and add it to the runner
      private def self.parse_and_add_action(data : YAML::Any, runner : ActionRunner, variables : Hash(String, YAML::Any))
        type = data["type"]?.try(&.as_s) || return

        # Handle special "parallel" type
        if type.downcase == "parallel"
          parse_parallel_action(data, runner, variables)
          return
        end

        if action_data = parse_action_data(data, variables)
          runner.add(action_data)
        end
      end

      # Parse a single action data
      private def self.parse_action_data(data : YAML::Any, variables : Hash(String, YAML::Any)) : ActionData?
        type = data["type"]?.try(&.as_s) || return nil

        # Extract duration
        duration = get_float(data, "duration", 0.0f32)

        # Build params hash from all other fields
        params = {} of String => YAML::Any
        data.as_h.each do |key, value|
          key_str = key.to_s
          next if key_str == "type" || key_str == "duration"

          # Substitute variables in values
          params[key_str] = substitute_variables(value, variables)
        end

        ActionData.new(type, params, duration)
      end

      # Parse parallel action block
      private def self.parse_parallel_action(data : YAML::Any, runner : ActionRunner, variables : Hash(String, YAML::Any))
        parallel_actions = [] of ActionData

        if actions = data["actions"]?.try(&.as_a)
          actions.each do |action_data|
            if action = parse_action_data(action_data, variables)
              parallel_actions << action
            end
          end
        end

        runner.add_parallel(parallel_actions) unless parallel_actions.empty?
      end

      # Substitute variable references in YAML values
      # Supports $variable_name syntax in strings and direct references
      private def self.substitute_variables(value : YAML::Any, variables : Hash(String, YAML::Any)) : YAML::Any
        case raw = value.raw
        when String
          # Check for $variable references in strings
          result = raw.gsub(/\$(\w+)/) do |match|
            var_name = $1
            if var_value = variables[var_name]?
              var_value.raw.to_s
            else
              match # Keep original if variable not found
            end
          end
          YAML::Any.new(result)
        when Hash
          # Recursively substitute in nested hashes
          new_hash = {} of YAML::Any => YAML::Any
          raw.each do |k, v|
            new_hash[k] = substitute_variables(v, variables)
          end
          YAML::Any.new(new_hash)
        when Array
          # Recursively substitute in arrays
          new_arr = raw.map { |v| substitute_variables(v, variables) }
          YAML::Any.new(new_arr)
        else
          value
        end
      end

      # Update checkpoint action indices after actions are parsed
      private def self.update_checkpoint_indices(runner : ActionRunner)
        # This is a placeholder - checkpoints need to be matched with
        # actual action indices based on cumulative timing or markers
        # For now, we leave indices at 0 (beginning)
      end

      # Helper to get float value from YAML::Any
      private def self.get_float(data : YAML::Any, key : String, default : Float32) : Float32
        if val = data[key]?
          case val.raw
          when Int64   then val.as_i.to_f32
          when Float64 then val.as_f.to_f32
          else default
          end
        else
          default
        end
      end

      # Helper to get int value from YAML::Any
      private def self.get_int(data : YAML::Any, key : String, default : Int32) : Int32
        if val = data[key]?
          case val.raw
          when Int64   then val.as_i.to_i32
          when Float64 then val.as_f.to_i32
          else default
          end
        else
          default
        end
      end

      # Helper to get string value from YAML::Any
      private def self.get_string(data : YAML::Any, key : String, default : String = "") : String
        data[key]?.try(&.as_s?) || default
      end

      # Helper to get bool value from YAML::Any
      private def self.get_bool(data : YAML::Any, key : String, default : Bool = false) : Bool
        data[key]?.try(&.as_bool?) || default
      end
    end
  end
end
