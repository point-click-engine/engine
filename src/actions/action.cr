# Action system - Data-driven action architecture
# Actions are data structures, not class hierarchies

require "yaml"

module PointClickEngine
  module Actions
    # Action state enum
    enum ActionState
      Pending
      Running
      Completed
      Cancelled
    end

    # Core action data - no behavior, just data
    struct ActionData
      include YAML::Serializable

      property type : String
      property params : Hash(String, YAML::Any)
      property duration : Float32

      def initialize(@type : String, @params : Hash(String, YAML::Any) = {} of String => YAML::Any, @duration : Float32 = 0.0f32)
      end

      # Convenience constructor with named params
      def self.create(type : String, duration : Float32 = 0.0f32, **kwargs) : ActionData
        params = {} of String => YAML::Any
        kwargs.each do |key, value|
          params[key.to_s] = to_yaml_any(value)
        end
        new(type, params, duration)
      end

      # Convert Crystal values to YAML::Any (public for use by ActionInstance)
      def self.to_yaml_any(value) : YAML::Any
        case value
        when String
          YAML::Any.new(value)
        when Int32, Int64
          YAML::Any.new(value.to_i64)
        when Float32, Float64
          YAML::Any.new(value.to_f64)
        when Bool
          YAML::Any.new(value)
        when Hash
          hash = {} of YAML::Any => YAML::Any
          value.each do |k, v|
            hash[YAML::Any.new(k.to_s)] = to_yaml_any(v)
          end
          YAML::Any.new(hash)
        when Array
          arr = [] of YAML::Any
          value.each { |v| arr << to_yaml_any(v) }
          YAML::Any.new(arr)
        when Nil
          YAML::Any.new(nil)
        else
          YAML::Any.new(value.to_s)
        end
      end
    end

    # Runtime action state - wraps ActionData with execution state
    class ActionInstance
      property data : ActionData
      property state : ActionState = ActionState::Pending
      property elapsed : Float32 = 0.0f32
      property started : Bool = false

      # For action-specific runtime data (e.g., tracking dialog completion)
      property custom_data : Hash(String, YAML::Any) = {} of String => YAML::Any

      # Optional callback for code-defined actions
      property callback : Proc(Nil)?

      def initialize(@data : ActionData)
      end

      def initialize(@data : ActionData, @callback : Proc(Nil)?)
      end

      # Progress from 0.0 to 1.0 based on elapsed time and duration
      def progress : Float32
        return 1.0f32 if @data.duration <= 0
        (@elapsed / @data.duration).clamp(0.0f32, 1.0f32)
      end

      # Time remaining until completion
      def remaining_time : Float32
        return 0.0f32 if @data.duration <= 0
        (@data.duration - @elapsed).clamp(0.0f32, @data.duration)
      end

      # Check if action is finished (completed or cancelled)
      def finished? : Bool
        @state == ActionState::Completed || @state == ActionState::Cancelled
      end

      # Check if action is currently running
      def running? : Bool
        @state == ActionState::Running
      end

      # Reset action to initial state for replay
      def reset
        @state = ActionState::Pending
        @elapsed = 0.0f32
        @started = false
        @custom_data.clear
      end

      # Mark as running
      def start!
        @started = true
        @state = ActionState::Running
      end

      # Mark as completed
      def complete!
        @state = ActionState::Completed
      end

      # Mark as cancelled
      def cancel!
        @state = ActionState::Cancelled
      end

      # Store custom data value
      def set_custom(key : String, value)
        @custom_data[key] = ActionData.to_yaml_any(value)
      end

      # Get custom data value
      def get_custom(key : String) : YAML::Any?
        @custom_data[key]?
      end
    end
  end
end
