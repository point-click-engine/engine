# Engine Fullscreen Viewport Contract Plan

## Goal

Define one authoritative screen rectangle and coordinate contract for:

- fullscreen
- windowed mode
- menus
- gameplay scenes
- sequence overlays
- dialog/UI
- mouse hit-testing

The current failure mode is that these systems are not all using the same effective viewport.

## Problems Confirmed By The Latest Capture

- Menu activation feels broken because visible menu placement and click hit-testing do not reliably match.
- The intro and later gameplay still render into a smaller sub-rectangle with large black unused regions.
- Dialog and hotspot labels are also trapped inside that smaller region, so this is broader than the sequence overlay layer.
- The log still shows Raylib/display viewport offsets while engine systems also maintain their own display transform.

## Likely Root Causes

1. Raw Raylib screen coordinates and engine display-transformed coordinates are being mixed.
2. The display manager owns an abstract game-area rect, but not every subsystem uses it.
3. Renderer, menu system, and input systems are not all anchored to one authoritative rectangle.
4. Fullscreen mode relies on Raylib/GLFW state that is not fully reflected back into every engine layer.

## Relevant Code

- `src/graphics/core/display.cr`
- `src/graphics/core/renderer.cr`
- `src/core/engine.cr`
- `src/ui/menu_system.cr`
- `src/ui/menu_input_handler.cr`
- `src/core/engine/verb_input_system.cr`
- `src/actions/action_overlay_manager.cr`
- `src/actions/action_executor.cr`

## Plan

### Phase 1. Instrument The Contract

Add temporary debug output or a structured debug hook for:

- window size
- render size
- fullscreen state
- display scale factor
- display offsets
- authoritative game-area rect
- raw mouse position
- transformed mouse-to-game position
- current scene logical size

Acceptance:

- one debug dump clearly shows all participating spaces during fullscreen gameplay

### Phase 2. Choose One Authoritative Rectangle

Define one source of truth, likely on `Graphics::Core::Display`, for the active game-area rectangle in screen space.

All of the following must use that rectangle:

- menu centering
- menu item hit-testing
- gameplay mouse gating
- dialog placement rules that depend on viewport bounds
- overlay placement into screen space
- renderer final presentation assumptions

Acceptance:

- there is a single public engine/display API for the active game-area rect
- no subsystem recomputes its own competing fullscreen rect

### Phase 3. Normalize Mouse Handling

Split mouse usage into two explicit paths:

- screen-space mouse for modal UI
- game-space mouse for gameplay interaction

Rules:

- menu and modal UI always use screen-space coordinates against the authoritative screen rect
- gameplay hotspot/pathfinding uses game-space coordinates derived from the same rect
- cursor drawing must be explicit about whether it is screen-space or game-space

Acceptance:

- menu hover/click works reliably in fullscreen
- gameplay hotspot hit-testing still works after the same change

### Phase 4. Reconcile Renderer And Display

Audit `Renderer#render` and `Display#with_game_coordinates` so the main scene path is not effectively letterboxed twice.

Questions to resolve:

- is the renderer already drawing into a logical reference surface?
- is the display transform adding a second level of scaling/offset?
- are scenes/backgrounds being drawn at a different logical size than the display reference?

Acceptance:

- a normal gameplay frame fills the intended active game area instead of sitting inside a smaller sub-rectangle

### Phase 5. Align Overlays And Dialog With The Same Contract

Once the scene path is correct:

- action overlays
- sequence text
- floating dialog
- hotspot labels

must all visually sit in the same game area as the scene.

Acceptance:

- intro, gameplay, dialog, and menus all occupy the same fullscreen composition area

## Do Not Do

- do not add OS-specific branches to paper over macOS symptoms
- do not add intro-specific rendering exceptions
- do not fix only `ActionOverlayManager` in isolation again

## Completion Criteria

- menu hover/click matches the visible menu items in fullscreen
- main scene rendering fills the intended active game area
- sequence overlays and gameplay dialog use the same visible playfield
- no subsystem depends on a competing fullscreen rect calculation
