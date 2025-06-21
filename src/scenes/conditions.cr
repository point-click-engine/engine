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
        state: StateCondition,
        combined: CombinedCondition
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
        state_value = engine.get_state_variable(@variable)
        return false unless state_value
        
        compare_values(state_value, @value, @operator)
      end
      
      private def compare_values(actual : Core::StateValue, expected : String | Int32 | Float32 | Bool, op : ComparisonOperator) : Bool
        case op
        when .equals?
          actual.value == expected
        when .not_equals?
          actual.value != expected
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
      
      private def compare_numeric(actual : Core::StateValue, expected : String | Int32 | Float32 | Bool) : Int32
        actual_num = to_numeric(actual.value)
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
      
      private def to_numeric(value : String | Int32 | Float32 | Bool) : Float32?
        case value
        when Int32 then value.to_f32
        when Float32 then value
        when Bool then value ? 1.0f32 : 0.0f32
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