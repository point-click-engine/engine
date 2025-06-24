# Dialog Tree System

## Overview

The Point Click Engine includes a sophisticated dialog tree system for creating branching conversations, similar to classic adventure games like Monkey Island or modern RPGs.

## Features

- **Branching Conversations**: Create complex dialog trees with multiple paths
- **Floating Text Display**: Character speech appears as colored floating text above their heads
- **Choice System**: Players select from available dialog options
- **Conditional Choices**: Show/hide choices based on game state
- **Once-Only Options**: Choices can be marked to only appear once
- **Actions & Variables**: Execute actions and set variables during conversations

## Dialog Flow

1. **Character Speech**: When a character speaks, their text appears as floating text above their head in a character-specific color
2. **Player Choices**: Available responses appear in a dialog box at the bottom of the screen
3. **Choice Selection**: Clicking a choice advances to the next dialog node
4. **Repeat**: The conversation continues until reaching an end node

## YAML Dialog Format

```yaml
name: butler
nodes:
  greeting:
    id: greeting
    text: "Good evening, Detective. I trust you are finding the mansion... accommodating?"
    character_name: butler
    choices:
      - text: "I'm here about the missing crystal."
        target_node_id: crystal_inquiry
      - text: "You seem nervous. Is everything alright?"
        target_node_id: nervous_observation
        
  crystal_inquiry:
    id: crystal_inquiry
    text: "Ah yes, the scientist mentioned that unfortunate incident."
    character_name: butler
    is_end: true
```

## Character Colors

The dialog system automatically assigns colors to different characters:
- Butler: Light blue
- Scientist: Light red  
- Player: Light green
- Others: White

## Best Practices

1. **Keep Speech Concise**: Floating text should be short and readable
2. **Clear Choices**: Make dialog options clearly distinct
3. **Character Names**: Always specify the speaking character
4. **End Nodes**: Mark final nodes with `is_end: true`

## Integration

To start a dialog tree:
```crystal
dm.start_dialog_tree("butler", "greeting")
```

The system handles all presentation, input, and flow automatically.