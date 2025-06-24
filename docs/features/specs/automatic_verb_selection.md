# Automatic Verb Selection System Specification

## Overview
The automatic verb selection system provides context-sensitive cursor changes and default actions based on what the player is hovering over. This reduces the need for manual verb selection and makes the game more intuitive.

## Core Components

### 1. Verb Types
```crystal
enum VerbType
  Walk      # Move to location
  Look      # Examine object
  Talk      # Talk to character
  Use       # Use object
  Take      # Pick up item
  Open      # Open door/container
  Close     # Close door/container
  Push      # Push object
  Pull      # Pull object
  Give      # Give item to character
end
```

### 2. Cursor Manager
- Manages different cursor sprites for each verb
- Changes cursor based on context
- Provides visual feedback for actions

### 3. Object Types
```crystal
enum ObjectType
  Background  # Default walkable area
  Item        # Pickable items
  Character   # NPCs
  Door        # Openable doors
  Container   # Openable containers
  Device      # Usable devices
  Exit        # Scene exits
end
```

## Implementation Details

### 1. Hotspot Enhancement
Each hotspot will have:
- Default verb action
- Object type classification
- Custom cursor override (optional)

### 2. Cursor System
```crystal
class CursorManager
  property cursors : Hash(VerbType, RL::Texture2D)
  property current_verb : VerbType
  property hotspot_offset : RL::Vector2
  
  def update(mouse_pos : RL::Vector2, scene : Scene)
    # Determine appropriate verb based on hover
  end
  
  def draw(mouse_pos : RL::Vector2)
    # Draw current cursor at mouse position
  end
end
```

### 3. Smart Verb Detection
Rules for automatic verb selection:
- Background/no hotspot → Walk
- Item hotspot → Take (if not in inventory)
- Character → Talk
- Door → Open/Close (based on state)
- Container → Open/Look
- Device → Use
- Exit → Walk

### 4. Visual Feedback
- Cursor changes to indicate possible action
- Optional text tooltip showing verb + object name
- Highlight color changes based on verb type

## User Interaction

### 1. Left Click Behavior
- Executes the default verb action
- Falls back to walk if no hotspot

### 2. Right Click Behavior  
- Always performs "Look" action
- Shows description for any hotspot

### 3. Middle Click (optional)
- Opens verb coin/menu for manual selection

## Configuration

### 1. Cursor Assets
Store cursor images in:
```
assets/cursors/
  walk.png
  look.png
  talk.png
  use.png
  take.png
  open.png
  close.png
  push.png
  pull.png
  give.png
```

### 2. Hotspot Configuration
Enhanced YAML format:
```yaml
hotspots:
  - name: wooden_door
    type: door
    default_verb: open
    object_type: door
    states:
      - name: closed
        verb: open
      - name: open
        verb: close
    
  - name: golden_key
    type: item
    default_verb: take
    object_type: item
    cursor_offset: {x: 16, y: 16}
```

## Benefits
1. **Intuitive gameplay** - Players don't need to manually select verbs
2. **Faster interaction** - Single click to perform most actions  
3. **Visual clarity** - Cursor indicates possible actions
4. **Accessibility** - Reduces clicks needed for common tasks
5. **Modern feel** - Similar to contemporary adventure games