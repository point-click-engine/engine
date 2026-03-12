# Engine Menu Input Coordination Plan

## Goal

Make menu interaction reliable and readable under fullscreen and normal windowed operation.

This workstream is narrower than the fullscreen contract plan, but it depends on that contract being clear.

## Problems Confirmed By The Latest Capture

- Menu click activation feels unreliable.
- The run detours through options before the game actually starts.
- Selected menu rows are visually hard to read.
- Menu behavior is better than the original broken playthrough, but still below acceptable quality.

## Relevant Code

- `src/ui/menu_system.cr`
- `src/ui/menu_input_handler.cr`
- `src/ui/menu_renderer.cr`
- `src/core/engine.cr`
- `src/graphics/core/display.cr`

## Plan

### Phase 1. Confirm Modal Ownership

Ensure the engine owns one clear rule:

- if menu is visible, gameplay click handling is suspended
- if menu is visible, gameplay cursor behavior cannot interfere with menu interaction

Acceptance:

- no gameplay actions can fire while the menu owns the frame

### Phase 2. Anchor Menu Hit-Testing To The Authoritative Screen Rect

Menu bounds and menu hit-testing must both use the same screen-space contract.

Audit:

- menu centering
- item bounds
- current mouse position source
- click activation source

Acceptance:

- every visible menu item is clickable where it is drawn

### Phase 3. Fix Hover And Selection Reliability

Check whether hover selection and click selection are using different coordinate or timing rules.

Potential issues to verify:

- stale mouse position
- input repeat logic interfering with menu actions
- click and hover using different bounds

Acceptance:

- hover selection follows the mouse predictably
- click activates the currently hovered item predictably

### Phase 4. Improve Selected-Row Readability

Current selected-state visuals are weak.

Fix through theme-level adjustments:

- selected text color
- selection background alpha
- contrast between fill and label

Acceptance:

- the selected row is readable at a glance

## Completion Criteria

- main menu can be navigated and activated reliably with the mouse
- options menu can be entered and exited reliably
- no gameplay cursor contamination returns
- selected item visuals are readable
