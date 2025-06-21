# Game state value storage

require "yaml"

module PointClickEngine
  module Core
    # Represents a value in the game state
    class StateValue
      include YAML::Serializable

      property value : String | Int32 | Float32 | Bool

      def initialize(@value : String | Int32 | Float32 | Bool)
      end

      # Convert to string for display
      def to_s(io)
        io << @value
      end

      # Type-safe getters
      def as_string? : String?
        @value.as?(String)
      end

      def as_int? : Int32?
        case v = @value
        when Int32   then v
        when Float32 then v.to_i32
        when String  then v.to_i32?
        else              nil
        end
      end

      def as_float? : Float32?
        case v = @value
        when Float32 then v
        when Int32   then v.to_f32
        when String  then v.to_f32?
        else              nil
        end
      end

      def as_bool? : Bool?
        case v = @value
        when Bool    then v
        when Int32   then v != 0
        when Float32 then v != 0.0
        when String  then v.downcase == "true" || v == "1"
        else              nil
        end
      end
    end
  end
end
