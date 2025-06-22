# Dynamic Hotspots System Specification

## Overview
Dynamic hotspots are interactive areas that can change their state, visibility, or behavior based on game conditions. This system allows for more complex puzzles and interactive environments.

## Core Features

### 1. Visibility Conditions
Hotspots can be shown or hidden based on:
- Game state variables
- Inventory items
- Character attributes
- Previous actions
- Time-based events

### 2. State Management
Each hotspot can have multiple states:
```crystal
class HotspotState
  property name : String
  property description : String
  property sprite : Texture2D?
  property interaction : Proc(Nil)?
  property visible : Bool = true
  property active : Bool = true
end
```

### 3. Condition System
```crystal
abstract class Condition
  abstract def evaluate(context : GameContext) : Bool
end

class InventoryCondition < Condition
  property item_name : String
  property has_item : Bool = true
  
  def evaluate(context : GameContext) : Bool
    context.inventory.has_item?(@item_name) == @has_item
  end
end

class StateCondition < Condition
  property variable : String
  property value : String | Int32 | Bool
  property operator : ComparisonOperator
  
  def evaluate(context : GameContext) : Bool
    # Compare game state variable with expected value
  end
end
```

## Implementation Details

### 1. Enhanced Hotspot Class
```crystal
class DynamicHotspot < Hotspot
  property states : Hash(String, HotspotState)
  property current_state : String = "default"
  property visibility_conditions : Array(Condition)
  property state_conditions : Hash(String, Array(Condition))
  
  def update(context : GameContext)
    # Check visibility
    @visible = visibility_conditions.all? { |c| c.evaluate(context) }
    
    # Check state transitions
    state_conditions.each do |state, conditions|
      if conditions.all? { |c| c.evaluate(context) }
        @current_state = state
        break
      end
    end
    
    # Update properties from current state
    if state = states[@current_state]?
      @description = state.description
      @active = state.active
    end
  end
end
```

### 2. Game Context
```crystal
class GameContext
  property inventory : Inventory::InventorySystem
  property state_variables : Hash(String, StateValue)
  property current_scene : Scene
  property player : Player
  
  def get_variable(name : String) : StateValue?
    @state_variables[name]?
  end
  
  def set_variable(name : String, value : StateValue)
    @state_variables[name] = value
  end
end
```

### 3. YAML Configuration
Enhanced hotspot definition in scene files:
```yaml
hotspots:
  - name: secret_door
    type: dynamic
    x: 500
    y: 300
    width: 100
    height: 200
    visibility_conditions:
      - type: inventory
        item: magical_key
        has_item: true
    states:
      default:
        description: "A solid wall"
        active: false
      revealed:
        description: "A hidden door"
        active: true
    state_conditions:
      revealed:
        - type: state
          variable: door_puzzle_solved
          value: true
          operator: equals
          
  - name: growing_plant
    type: dynamic
    x: 200
    y: 400
    width: 50
    height: 50
    states:
      seed:
        description: "A small seed on the ground"
      sprout:
        description: "A tiny green sprout"
      plant:
        description: "A small plant"
      flower:
        description: "A beautiful flowering plant"
    state_conditions:
      sprout:
        - type: state
          variable: plant_watered
          value: 1
          operator: equals
      plant:
        - type: state
          variable: plant_watered
          value: 2
          operator: greater_equal
      flower:
        - type: inventory
          item: growth_potion
          has_item: false  # Used the potion
```

## Use Cases

### 1. Hidden Objects
- Secret doors that appear after solving puzzles
- Items that become visible after certain actions
- Hidden switches revealed by using special items

### 2. Progressive Changes
- Plants that grow over time
- Machinery that changes state
- Doors that open/close based on switches

### 3. Context-Sensitive Areas
- Different interactions based on held items
- Areas that change based on character state
- Time-sensitive hotspots

### 4. Puzzle Integration
- Multi-step puzzles with changing hotspots
- Combination locks with visual feedback
- Environmental puzzles

## Benefits
1. **Rich Interactions** - More complex and interesting puzzles
2. **Dynamic Environments** - Worlds that feel alive and responsive
3. **Better Storytelling** - Environmental changes that reflect story progress
4. **Replayability** - Different paths through the game
5. **Memory Efficiency** - One hotspot can serve multiple purposes