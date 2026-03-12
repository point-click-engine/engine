# Playthrough Audit And Remediation Plan

## Scope

This plan is based on the recorded playthroughs and their extracted review frames:

- `tmp/crystal_mystery_intro.mp4`
- `tmp/playthrough_review/menu/*.png`
- `tmp/playthrough_review/intro/*.png`
- `tmp/playthrough_review/gameplay/*.png`
- `tmp/crystal_mystery_intro2.mp4`
- `tmp/crystal_mystery_intro2.log`
- `tmp/playthrough_review2/menu/*.png`
- `tmp/playthrough_review2/intro/*.png`
- `tmp/playthrough_review2/gameplay/*.png`

It replaces the previous, too-narrow diagnosis. The recorded problems are not a single cursor bug. They span:

1. modal UI/input ownership
2. cursor asset/configuration
3. sequence overlay rendering under `FitWithBars` / fullscreen
4. scene-transition side effects during cinematics
5. fullscreen viewport/input contract drift
6. missing regression coverage

This document is intentionally split into:

- generic engine issues
- `crystal_mystery` YAML / asset issues
- test gaps

No implementation should start from this plan without confirming the order of work.

## Fresh Capture Delta

The second capture changes the diagnosis in two important ways:

1. menu clicks are not dead, but they are unreliable enough to feel broken
2. the partial/cornered rendering bug is broader than the cinematic overlay layer and persists into normal gameplay

This means the current primary issue is a shared display/input contract bug across:

- fullscreen
- menu hit testing
- scene rendering
- sequence overlays
- dialog/UI placement

not just the action-sequence overlay path.

## What The Recording Shows

### 1. Main menu and pause/options/load menus are visually corrupted

Evidence:

- `tmp/playthrough_review/menu/frame_005.png`
- `tmp/playthrough_review/menu/frame_006.png`
- `tmp/playthrough_review/menu/frame_008.png`
- `tmp/playthrough_review/menu/frame_010.png`

Observed behavior:

- a green fallback verb cursor (`+W`) is drawn over menu text
- options text looks broken because the cursor glyph overlaps the label
- load/pause menus show the same contamination

Interpretation:

- this is not an “options menu only” bug
- modal menu rendering and gameplay cursor rendering are not isolated from each other

### 1b. Menu click hit-testing is still not in the same coordinate space as fullscreen rendering

Fresh evidence:

- `tmp/crystal_mystery_intro2.mp4`
- `tmp/playthrough_review2/menu/frame_001.png`
- `tmp/playthrough_review2/menu/frame_005.png`
- `tmp/playthrough_review2/menu/frame_021.png`
- `tmp/crystal_mystery_intro2.log`

Observed behavior:

- the game spends a long time in the menus before actually starting
- the recording detours into the options screen and back before gameplay begins
- selection movement happens, so mouse/keyboard input is not dead
- actual click activation is unreliable enough to feel broken in real use
- the selected menu row is also visually hard to read because highlight fill and highlight text are too similar

Interpretation:

- this is likely not a `MenuSystem`-only bug
- the stronger hypothesis is that menu layout and menu input are still using different fullscreen spaces:
  - menu bounds are derived from the engine display/game area
  - mouse coordinates come directly from Raylib raw screen coordinates
  - the fullscreen log still reports Raylib internal viewport offsets

### 2. Intro visuals render into only part of the window

Evidence:

- `tmp/playthrough_review/intro/frame_003.png`
- `tmp/playthrough_review/intro/frame_011.png`
- `tmp/playthrough_review/intro/frame_013.png`
- `tmp/playthrough_review/intro/frame_015.png`

Observed behavior:

- the cinematic backgrounds and overlays are drawn in a smaller rectangle instead of the full active game area
- large black unused regions remain around that rectangle
- the same symptom carries into early gameplay frames

Interpretation:

- this is a generic display/overlay composition bug
- the sequence overlay layer is not respecting the same display transform as scenes and menus

### 2b. The partial/cornered rendering bug persists into normal gameplay

Fresh evidence:

- `tmp/playthrough_review2/gameplay/frame_060.png`
- `tmp/playthrough_review2/gameplay/frame_120.png`
- `tmp/playthrough_review2/gameplay_sheet1.png`

Observed behavior:

- the game scene is still rendered into a smaller rectangle with large black unused regions
- this continues after the intro, including normal gameplay/dialog frames
- therefore this is not limited to `ActionOverlayManager`

Interpretation:

- the real issue is a broader mismatch between:
  - the engine display reference resolution
  - Raylib fullscreen/upscaling viewport state
  - the renderer final blit
  - scene/background logical dimensions
- the overlay fixes alone cannot solve this because the main scene path is still affected

Concrete likely root cause:

- the engine currently hardcodes a 4:3 display reference (`1024x768`)
- `crystal_mystery` uses predominantly 16:9 art (`320x180` backgrounds and cinematic layouts)
- the game config still declares a 4:3 display target
- this produces layered letterboxing/pillarboxing:
  - fullscreen bars from monitor vs game aspect ratio
  - internal scene bars from 16:9 backgrounds inside a 4:3 scene/display contract

### 3. Scene-enter gameplay text leaks into the intro

Evidence:

- `tmp/playthrough_review/intro/frame_009.png`
- `crystal_mystery/scenes/laboratory.yaml`

Observed behavior:

- during the intro handoff, the player gets the gameplay-style text box:
  `This is where the Crystal of Luminus was kept - and stolen.`

Interpretation:

- intro `change_scene` is triggering normal scene-enter side effects
- the engine currently has no clean generic way for a cinematic to stage a scene without also firing gameplay presentation hooks

### 3b. The intro still does not visually match the intended authored beats

Fresh evidence:

- `tmp/playthrough_review2/intro/frame_035.png`
- `tmp/playthrough_review2/intro/frame_045.png`
- `tmp/playthrough_review2/intro/frame_058.png`

Observed behavior:

- the early moon/sky section is visible
- intro text appears
- the crystal reveal does not read as a glowing mystical crystal; it reads more like a small brown rock-like sprite
- the sequence lingers visually on the sky section much longer than expected from the authored dramatic progression

Interpretation:

- part of this is still engine-side staging/render timing
- part is content-side:
  - the cinematic crystal asset is not strong enough for the intended beat
  - the intro should probably not reuse the small inventory-style crystal asset for the reveal

### 4. Intro/gameplay state still feels entangled

Evidence:

- `tmp/playthrough_review/intro/frame_011.png`
- `tmp/playthrough_review/intro/frame_013.png`
- `tmp/playthrough_review/intro/frame_015.png`
- `tmp/playthrough_review/gameplay/frame_001.png`
- `tmp/playthrough_review/gameplay/frame_016.png`

Observed behavior:

- intro dialog lines continue while the visible scene state looks like gameplay-space
- later frames show hotspot labels and dialog UI mixed with the same broken partial viewport

Interpretation:

- sequence ownership, scene activation, and gameplay UI are not cleanly separated during the handoff
- part of this is engine-side, part of it is how `crystal_mystery` uses playable scenes during the intro

### 5. The log is not sufficient for playthrough debugging

Observed behavior:

- the provided `tmp/crystal_mystery_intro.log` does not contain enough runtime sequence/scene markers to correlate most visible failures with specific actions

Interpretation:

- the engine lacks the right optional debug tracing for sequence checkpoints, scene activation mode, and modal UI ownership

## Root Causes In The Engine

### A. Modal UI does not own input and cursor rendering

Relevant code:

- `src/core/engine.cr`
- `src/core/engine/verb_input_system.cr`
- `src/ui/menu_system.cr`
- `src/ui/menu_input_handler.cr`

Current problems:

- `Engine#update` processes verb/gameplay input before menu updates
- `Engine#render` always draws the verb cursor on top of everything
- `VerbInputSystem#draw` converts raw mouse to game coordinates and then draws outside the display transform
- menus use screen-space bounds, while the verb cursor uses game-space coordinates

Practical result:

- menu text is contaminated by the gameplay cursor
- modal UI and gameplay input are active at the same time

Required engine fix:

- introduce a generic modal input/render ownership rule
- when a menu owns the frame, gameplay cursor drawing and gameplay click handling must be suspended
- do this through engine-level UI/input coordination, not through `crystal_mystery` special cases
- define one authoritative fullscreen viewport/input contract for menus:
  - menu layout
  - menu hit-testing
  - final display rect
  - raw mouse input
  must all use the same authoritative screen rectangle

### B. Cursor asset loading is hardcoded and not configurable

Relevant code:

- `src/ui/cursor_manager.cr`

Current problem:

- the engine hardcodes `assets/cursors/*.png`
- `crystal_mystery` ships cursor art under `assets/ui/cursors/`
- missing cursor assets fall back to a debug-style crosshair and verb letter

Practical result:

- a shipping example game silently degrades into debug-looking cursor rendering

Required engine fix:

- add configurable cursor theme paths in game config or UI config
- support a game-relative cursor asset directory
- make missing cursor handling safe for release builds:
  - either use a neutral default cursor
  - or hide the custom cursor layer instead of drawing debug glyphs

### C. Sequence overlays bypass the display manager contract

Relevant code:

- `src/actions/action_overlay_manager.cr`
- `src/actions/action_executor.cr`
- `src/graphics/core/display.cr`
- `src/graphics/core/renderer.cr`

Current problems:

- `ActionOverlayManager#draw_background` uses raw `Raylib.get_screen_width/height`
- `ActionOverlayManager#draw_sprite` scales against raw screen size
- `ActionExecutor#draw_show_text` also uses raw screen dimensions
- these draws happen outside the renderer/display transform used for normal scene rendering

Practical result:

- sequence backgrounds, sprites, and text do not share the same coordinate space as the main scene
- under `FitWithBars` / fullscreen, the intro is drawn into the wrong viewport

Required engine fix:

- move sequence overlay rendering onto the same display contract as the rest of the game
- either:
  - render overlays inside the renderer/display game-area transform
  - or explicitly map overlay output to `display_manager.game_area_screen_rect`
- stop using raw `get_screen_width/height` for authored overlay placement unless the draw is truly screen-space UI
- audit the entire render contract end-to-end:
  - Raylib fullscreen window size
  - render texture size
  - display reference size
  - game-area screen rect
  - transformed mouse position
  - active scene logical size
- make the display reference truly game-configurable instead of hardcoded engine-wide

### D. Scene changes during sequences have no generic staging controls

Relevant code:

- `src/actions/action_executor.cr`
- `src/core/scene_manager.cr`
- `crystal_mystery/sequences/intro_sequence.yaml`
- `crystal_mystery/scenes/laboratory.yaml`
- `crystal_mystery/scenes/garden.yaml`

Current problem:

- `change_scene` in a global sequence loads a normal playable scene
- that scene can immediately fire normal enter-time behavior:
  - `on_enter_text`
  - scripts
  - hotspot availability
  - dialog/UI state

Practical result:

- gameplay text and behaviors leak into the cinematic

Required engine fix:

- add generic declarative `change_scene` controls such as:
  - `run_on_enter_text`
  - `load_script`
  - `run_script_on_enter`
  - `activate_hotspots`
  - `activate_characters`
  - `scene_mode: staging|playable`
- keep these generic and YAML-driven
- do not reintroduce intro-specific branches in startup or engine flow

### E. Sequence-to-gameplay handoff is not explicitly modeled

Relevant code:

- `src/core/engine.cr`
- `src/actions/action_executor.cr`
- `src/core/scene_manager.cr`

Current problem:

- sequence ownership, scene activation, UI visibility, and player control are coordinated through loosely related actions
- there is no single generic handoff contract from “cinematic staging” to “playable scene”

Required engine fix:

- define a generic handoff model:
  - scene loaded in staging mode
  - sequence owns control
  - final action activates playable state
- make that model reusable for any game intro, cutscene, or in-game cinematic

### F. Playthrough diagnostics are too weak

Relevant code:

- `src/actions/action_runner.cr`
- `src/actions/action_executor.cr`
- `src/core/scene_manager.cr`

Required engine improvement:

- add optional debug logging for:
  - sequence start/end
  - checkpoint reached
  - action type start/finish for selected action classes
  - scene activation mode on `change_scene`
  - modal owner changes: gameplay/menu/dialog/sequence

This should be off by default and enabled by config or debug mode.

## Crystal Mystery Content Issues

### 1. Cursor assets are in the wrong place for the current engine contract

Current asset layout:

- `crystal_mystery/assets/ui/cursors/cursor_default.png`
- `crystal_mystery/assets/ui/cursors/cursor_hand.png`
- `crystal_mystery/assets/ui/cursors/cursor_look.png`

Problem:

- the example game has cursor art, but not where the engine currently looks

Fix after engine work:

- either move/adapt the asset layout to the new cursor config contract
- or configure `crystal_mystery` explicitly to use its `assets/ui/cursors/` set

### 2. Playable scenes are being used as cinematic staging scenes

Relevant files:

- `crystal_mystery/sequences/intro_sequence.yaml`
- `crystal_mystery/scenes/laboratory.yaml`
- `crystal_mystery/scenes/garden.yaml`

Problem:

- the intro uses playable scenes while those scenes still carry normal gameplay enter behavior
- `laboratory.yaml` and `garden.yaml` both define strong `on_enter_text`

Fix after engine work:

- once generic staging controls exist, update the intro YAML to suppress playable enter hooks during cinematic transitions
- if needed, split staging and playable scene variants only where content truly differs

### 3. Intro polish should be re-audited only after the engine fixes land

Reason:

- the current recording is dominated by engine-level display/input problems
- timing and artistic quality judgments are not reliable until:
  - menus are isolated from gameplay cursor rendering
  - overlays render in the correct viewport
  - scene-enter side effects are suppressed during staging

### 3b. `crystal_mystery` currently declares the wrong display contract for its art set

Observed mismatch:

- backgrounds are `320x180` pixel art
- the current display target is `1024x768`
- the current engine reference is also `1024x768`

Practical result:

- the example game is effectively authored as mixed 16:9 and 4:3 at the same time

Fix after engine work:

- once the engine supports a configurable reference resolution, set `crystal_mystery` to a 16:9 target appropriate for its assets
- then re-check hotspot positions, UI placement, and intro sequence coordinates against that final reference

### 4. The selected menu treatment is visually weak even when functionally correct

Observed behavior:

- selected rows become hard to read because both the fill and the selected text are bright yellow

Likely source:

- `src/ui/menu_renderer.cr`

Fix:

- choose contrasting selected text/fill colors
- keep this theme-level if possible so the engine does not hardcode one visual style

## Missing Spec Coverage

The current spec suite clearly did not model the failing behavior in the recording.

Required additions:

### 1. Modal UI ownership specs

Add integration coverage asserting:

- menu visible => verb cursor is not drawn
- menu visible => gameplay click handling does not run
- options/load/pause menus render without gameplay cursor contamination

### 2. Display-transform specs for overlays

Add integration coverage asserting:

- `ActionOverlayManager` backgrounds/sprites/text render into the same active game area used by scenes
- `FitWithBars` and fullscreen preserve correct placement
- sequence canvas coordinates are transformed consistently

### 3. Scene-staging specs

Add specs for generic `change_scene` options:

- sequence can change scene without firing `on_enter_text`
- sequence can defer or suppress scene scripts
- final handoff can activate a scene into normal playable state

### 4. Cursor asset/config specs

Add specs asserting:

- configurable cursor asset root is honored
- missing custom cursor assets do not produce release-hostile fallback glyphs by default

### 5. End-to-end capture-oriented smoke checks

Do not overbuild this into brittle GUI automation. Add a narrow engine integration layer that can assert:

- active modal owner
- active display/game area rect
- active sequence overlay canvas
- whether gameplay cursor draw is suppressed

That gives deterministic checks for the failure modes shown in the video.

## Recommended Order

1. Fix modal ownership first.
   Menus, dialogs, gameplay input, and cursor rendering must stop fighting each other.

2. Fix the fullscreen display/input contract next.
   Menus, scenes, overlays, and mouse hit-testing must share one authoritative viewport rectangle.

3. Fix the full scene render/display contract.
   As long as the main scene path can still render into a smaller sub-rectangle, intro validation is unreliable.

4. Add generic scene-staging controls.
   This removes gameplay side effects from cinematic scene changes.

5. Update `crystal_mystery` to use those generic controls.
   No engine intro special cases.

6. Add the missing regression coverage.

7. Re-record the full playthrough and do a second audit focused on cinematic quality and remaining content polish.

## Acceptance Criteria

This plan is complete when all of the following are true:

- main/options/load/pause menus render without gameplay cursor contamination
- menu clicks and hover logic work while gameplay input is suppressed
- menus use one consistent fullscreen coordinate space for layout and hit-testing
- intro overlays fill the correct active game area under `FitWithBars` / fullscreen
- normal gameplay scenes also fill the correct active game area under `FitWithBars` / fullscreen
- sequence text, sprites, and backgrounds share one coordinate/display contract
- intro scene changes do not trigger unwanted gameplay text or script side effects
- `crystal_mystery` uses declarative YAML to control cinematic behavior
- the new specs fail on the recorded regressions and pass after the fixes
- a fresh full playthrough recording looks visually coherent before any further cinematic-polish pass begins
