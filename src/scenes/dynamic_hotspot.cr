# Dynamic hotspot with state and visibility conditions

require "./hotspot"
require "./conditions"
require "yaml"

module PointClickEngine
  module Scenes
    # Hotspot state information
    class HotspotState
      include YAML::Serializable
      
      property description : String = ""
      property active : Bool = true
      property verb : UI::VerbType?
      property object_type : UI::ObjectType?
      
      def initialize(@description : String = "", @active : Bool = true)
      end
    end
    
    # Dynamic hotspot that can change based on game state
    class DynamicHotspot < Hotspot
      property states : Hash(String, HotspotState) = {} of String => HotspotState
      property current_state : String = "default"
      property visibility_conditions : Array(Condition) = [] of Condition
      property state_conditions : Hash(String, Array(Condition)) = {} of String => Array(Condition)
      
      def initialize
        super()
        @states["default"] = HotspotState.new
      end
      
      def initialize(@name : String, position : RL::Vector2, size : RL::Vector2)
        super(name, position, size)
        @states["default"] = HotspotState.new(@description)
      end
      
      # Update visibility and state based on conditions
      def update_conditions(engine : Core::Engine)
        # Check visibility conditions
        if @visibility_conditions.empty?
          @visible = true
        else
          @visible = @visibility_conditions.all? { |c| c.evaluate(engine) }
        end
        
        # Check state transitions
        @state_conditions.each do |state_name, conditions|
          if conditions.all? { |c| c.evaluate(engine) }
            set_state(state_name)
            break
          end
        end
        
        # Apply current state properties
        apply_current_state
      end
      
      # Set the current state
      def set_state(state_name : String)
        return unless @states.has_key?(state_name)
        @current_state = state_name
        apply_current_state
      end
      
      # Apply properties from current state
      private def apply_current_state
        return unless state = @states[@current_state]?
        
        @description = state.description
        @active = state.active
        
        if verb = state.verb
          @default_verb = verb
        end
        
        if obj_type = state.object_type
          @object_type = obj_type
        end
      end
      
      # Add a new state
      def add_state(name : String, state : HotspotState)
        @states[name] = state
      end
      
      # Add visibility condition
      def add_visibility_condition(condition : Condition)
        @visibility_conditions << condition
      end
      
      # Add state transition condition
      def add_state_condition(state_name : String, condition : Condition)
        @state_conditions[state_name] ||= [] of Condition
        @state_conditions[state_name] << condition
      end
      
      # Override update to check conditions
      def update(dt : Float32)
        return unless @active
        
        # Update conditions if we have access to the engine
        if engine = Core::Engine.instance
          update_conditions(engine)
        end
        
        # Only process input if visible and active
        if @visible && @active
          super(dt)
        end
      end
    end
  end
end