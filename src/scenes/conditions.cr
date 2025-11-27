# Condition system for dynamic hotspots and game logic

require "yaml"

module PointClickEngine
  module Scenes
    # Comparison operators for conditions
    enum ComparisonOperator
      Equals
      NotEquals
      Greater
      GreaterEqual
      Less
      LessEqual
    end

    # Base class for all conditions
    abstract class Condition
      include YAML::Serializable
      use_yaml_discriminator "type", {
        inventory: InventoryCondition,
        state:     StateCondition,
        combined:  CombinedCondition,
      }

      abstract def evaluate(engine : Core::Engine) : Bool
    end

    # Condition based on inventory items
    class InventoryCondition < Condition
      property item_name : String
      property has_item : Bool = true

      def initialize(@item_name : String, @has_item : Bool = true)
      end

      def evaluate(engine : Core::Engine) : Bool
        engine.inventory.has_item?(@item_name) == @has_item
      end
    end

    # Condition based on game state variables
    class StateCondition < Condition
      property variable : String
      property value : String | Int32 | Float32 | Bool
      property operator : ComparisonOperator = ComparisonOperator::Equals

      def initialize(@variable : String, @value : String | Int32 | Float32 | Bool, @operator : ComparisonOperator = ComparisonOperator::Equals)
      end

      def evaluate(engine : Core::Engine) : Bool
        # Get the game state manager from the engine
        gsm = engine.game_state_manager
        return false unless gsm

        # First check if it's a flag (boolean)
        if gsm.flags.has_key?(@variable)
          actual_value = gsm.get_flag(@variable)
          expected_bool = case @value
                          when Bool    then @value.as(Bool)
                          when String  then @value.as(String).downcase == "true"
                          when Int32   then @value.as(Int32) != 0
                          when Float32 then @value.as(Float32) != 0.0f32
                          else false
                          end
          return compare_bool(actual_value, expected_bool, @operator)
        end

        # Then check variables
        actual_value = gsm.get_variable(@variable)
        return false if actual_value.nil?

        compare_values(actual_value, @value, @operator)
      end

      private def compare_bool(actual : Bool, expected : Bool, op : ComparisonOperator) : Bool
        case op
        when .equals?     then actual == expected
        when .not_equals? then actual != expected
        else actual == expected  # Booleans only support equals/not equals
        end
      end

      private def compare_values(actual : Core::GameValue, expected : String | Int32 | Float32 | Bool, op : ComparisonOperator) : Bool
        case op
        when .equals?
          values_equal?(actual, expected)
        when .not_equals?
          !values_equal?(actual, expected)
        when .greater?
          compare_numeric(actual, expected) > 0
        when .greater_equal?
          compare_numeric(actual, expected) >= 0
        when .less?
          compare_numeric(actual, expected) < 0
        when .less_equal?
          compare_numeric(actual, expected) <= 0
        else
          false
        end
      end

      private def values_equal?(actual : Core::GameValue, expected : String | Int32 | Float32 | Bool) : Bool
        case {actual, expected}
        when {Bool, Bool}       then actual == expected
        when {Int32, Int32}     then actual == expected
        when {Float32, Float32} then actual == expected
        when {String, String}   then actual == expected
        when {Int32, Float32}   then actual.to_f32 == expected
        when {Float32, Int32}   then actual == expected.to_f32
        else
          actual.to_s == expected.to_s
        end
      end

      private def compare_numeric(actual : Core::GameValue, expected : String | Int32 | Float32 | Bool) : Int32
        actual_num = to_numeric(actual)
        expected_num = to_numeric(expected)

        if actual_num && expected_num
          if actual_num > expected_num
            1
          elsif actual_num < expected_num
            -1
          else
            0
          end
        else
          0
        end
      end

      private def to_numeric(value : Core::GameValue | String | Int32 | Float32 | Bool) : Float32?
        case value
        when Int32   then value.to_f32
        when Float32 then value
        when Bool    then value ? 1.0f32 : 0.0f32
        when String
          value.to_f32?
        else
          nil
        end
      end
    end

    # Combined conditions with AND/OR logic
    class CombinedCondition < Condition
      enum LogicType
        And
        Or
      end

      property conditions : Array(Condition)
      property logic : LogicType = LogicType::And

      def initialize(@conditions : Array(Condition), @logic : LogicType = LogicType::And)
      end

      def evaluate(engine : Core::Engine) : Bool
        case @logic
        when .and?
          @conditions.all? { |c| c.evaluate(engine) }
        when .or?
          @conditions.any? { |c| c.evaluate(engine) }
        else
          false
        end
      end
    end
  end
end
