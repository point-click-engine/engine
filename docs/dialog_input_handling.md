# Dialog Input Handling

## Overview

The dialog system in the Point Click Engine properly manages input priority to prevent clicks from passing through to the game world when dialogs are displayed.

## Input Handling Priority

When a dialog is shown:

1. The dialog's `visible` property is set to `true`
2. On the first frame after showing, `ready_to_process_input` is `false` to avoid accidental clicks
3. On subsequent frames, `ready_to_process_input` becomes `true` and the dialog can handle clicks

## Engine Integration

The engine's update loop checks for active dialogs before processing scene input:

```crystal
# Update dialogs
@dialogs.each(&.update(dt))

# Check if any dialog is visible and ready to process input
dialog_handling_input = @dialogs.any? { |d| d.visible && d.ready_to_process_input }

# Process input only if no dialog is handling it
if !dialog_handling_input
  # Process scene/movement input
end
```

This ensures that:
- Dialog clicks are handled before movement/scene interaction
- Clicking on dialog choices doesn't cause the player to move
- The dialog can properly capture and respond to user input

## Dialog Tree Integration

Dialog trees use the `show_dialog_choices` method which creates a standard dialog:

```crystal
dm.show_dialog_choices(current_node.text, available_choices.map(&.text)) do |choice_index|
  make_choice(choice_index)
end
```

This ensures consistent input handling across both simple dialogs and complex dialog trees.

## Best Practices

1. Always use `show_dialog` or `show_dialog_choices` to display dialogs
2. Don't manually handle dialog input in scene or character code
3. Let the engine's input priority system manage click handling
4. Use the `ready_to_process_input` flag to prevent accidental clicks when dialogs appear