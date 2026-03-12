# Render / Display Refactor Plan

## Status

The core rebuild described here is now implemented in the live engine:

- renderer-owned logical render targets
- one top-level frame graph in `Engine`
- texture-in / texture-out shader scene effects
- final presentation handled once through `Display`
- world, cinematic, and UI composition kept in logical space before presentation

The newer [RENDER_PIPELINE_ARCHITECTURE_REBUILD_PLAN.md](/Users/remy/dev/point_click_engine/RENDER_PIPELINE_ARCHITECTURE_REBUILD_PLAN.md) remains the more specific reconstruction/audit document for remaining cleanup and validation tasks.

## Goal

Replace the current ad hoc display/render/input layering with one explicit render contract that:

- keeps world rendering, shader effects, cinematic overlays, UI, and cursor rendering in coherent spaces
- makes fullscreen and scaling behavior predictable
- keeps menu/dialog/input coordinates aligned with what is visibly rendered
- allows `crystal_mystery` to migrate cleanly to a consistent aspect/resolution contract
- is testable with specs instead of only by manual capture review

This plan is intentionally architectural. The current problems are no longer well served by one-shot local fixes.

## Current State

### The engine currently uses multiple overlapping coordinate systems

There are at least four relevant spaces in play:

1. `screen space`
   Raw Raylib window pixels and raw mouse coordinates.

2. `display logical space`
   The configured reference resolution in [display.cr](/Users/remy/dev/point_click_engine/src/graphics/core/display.cr).

3. `scene/world space`
   Scene logical coordinates, camera movement, hotspots, characters, walkable regions.

4. `cinematic overlay space`
   Action sequence canvas space in [action_overlay_manager.cr](/Users/remy/dev/point_click_engine/src/actions/action_overlay_manager.cr).

These are legitimate spaces, but they are not currently composed through a single authoritative pipeline.

### Display scaling is applied in too many places

Display scaling currently appears in all of these places:

- [display.cr](/Users/remy/dev/point_click_engine/src/graphics/core/display.cr)
  - `with_game_coordinates`
  - `screen_to_game`
  - `game_to_screen`
- [renderer.cr](/Users/remy/dev/point_click_engine/src/graphics/core/renderer.cr)
  - `render(apply_display_transform)`
- [engine.cr](/Users/remy/dev/point_click_engine/src/core/engine.cr)
  - `with_logical_render_space`
  - `render_shader_scene`
  - `draw_modal_cursor`
  - menu/dialog/UI rendering decisions
- shader scene effects
  - [rain_shader.cr](/Users/remy/dev/point_click_engine/src/graphics/effects/scene_effects/shader/rain_shader.cr)
  - [fog_shader.cr](/Users/remy/dev/point_click_engine/src/graphics/effects/scene_effects/shader/fog_shader.cr)
  - [darkness_shader.cr](/Users/remy/dev/point_click_engine/src/graphics/effects/scene_effects/shader/darkness_shader.cr)
  - [underwater_shader.cr](/Users/remy/dev/point_click_engine/src/graphics/effects/scene_effects/shader/underwater_shader.cr)
  - [transition_effect.cr](/Users/remy/dev/point_click_engine/src/graphics/effects/scene_effects/transition_effect.cr)

That is the core architectural problem.

## High-Confidence Architectural Faults

### 1. There is no single authoritative frame graph

Right now the engine conceptually does this:

- render world
- sometimes render world into a shader RT
- sometimes draw effect overlays in logical space
- sometimes draw UI in logical space
- sometimes draw menu in logical space
- sometimes convert mouse to logical space before the menu
- sometimes draw cursor in logical space

The order and coordinate ownership depend on which code path is active.

That makes regressions almost guaranteed.

### 2. `Display.reference_width/height` is acting as a global mutable singleton

[display.cr](/Users/remy/dev/point_click_engine/src/graphics/core/display.cr) exposes class-level mutable reference dimensions:

- `@@reference_width`
- `@@reference_height`

Large parts of the engine read those class globals directly:

- scene effects
- action overlay manager
- dialogs
- floating text
- inventory UI
- camera helpers
- viewport helpers

This creates hidden coupling:

- per-engine display state and global static state can diverge
- shaders and UI often size themselves from global reference values instead of the active render target or current scene/cinematic canvas

### 3. World rendering and UI rendering are not cleanly separated

The engine currently renders both world and UI through `with_logical_render_space`, but some UI is actually world-anchored:

- floating dialogs use character/world positions
- scene script overlays may be world-aware or cinematic-aware
- hotspots are world-space debug overlays

At the same time, menus and classic dialogs are screen/logical UI.

Those need different rules.

### 4. Shader scene effects own too much of the render contract

Shader effects currently:

- allocate their own render textures sized from `Display.reference_width/height`
- render the scene inside the effect object
- composite directly to `display.game_area_screen_rect`

That means the effect implementation is partially deciding:

- framebuffer size
- source texture size
- destination rectangle
- final screen composite behavior

That is renderer/display responsibility, not effect responsibility.

### 5. Menu and dialog systems still depend on display transforms indirectly

The menu system is better than before, but the architecture is still fragile:

- [menu_system.cr](/Users/remy/dev/point_click_engine/src/ui/menu_system.cr) normalizes mouse through `display.screen_to_game`
- layout is computed from engine reference dimensions
- rendering happens through the engine’s logical render wrapper

That can work, but only if menu/UI is formally defined as part of one UI stage in the pipeline.

Dialogs are worse:

- [floating_dialog.cr](/Users/remy/dev/point_click_engine/src/ui/floating_dialog.cr)
  positions dialogs from world coordinates without camera translation
- [dialog.cr](/Users/remy/dev/point_click_engine/src/ui/dialog.cr)
  also mixes raw mouse and display-transformed mouse logic

This is why dialogs can disappear even though the dialog manager is still being drawn.

## What Should Replace It

## Target Architecture

The engine should use exactly three explicit render spaces:

1. `WorldSpace`
   Scene logical coordinates, camera applied.

2. `UIScreenSpace`
   Game logical UI coordinates, no camera.
   This includes:
   - menus
   - inventory
   - classic dialogs
   - cursor
   - UI hints

3. `CinematicSpace`
   Optional sequence canvas coordinates for authored action overlays.
   This is separate from world space and separate from generic UI space.

And exactly one display composite stage:

4. `ScreenComposite`
   Final scaling from logical output texture into the actual window/fullscreen area.

## Proposed Frame Graph

Every frame should follow this order:

1. Build `FrameContext`
   - active display size
   - active logical game size
   - active scene logical size
   - active cinematic canvas if any
   - active game area rect
   - camera
   - active scene effects

2. Render world scene into `world_rt`
   - scene background
   - scene objects
   - characters
   - world-space debug overlays

3. Apply world post-processing / scene shader chain into `scene_rt`
   - effects consume and produce logical render textures
   - effects do not decide final screen destination rects

4. Render cinematic overlays into `scene_rt`
   - action overlays
   - sequence text
   - sequence-only sprite/background layers

5. Render UI into `ui_rt` or directly into `scene_rt`
   - menus
   - inventory
   - dialogs
   - cursor

6. Composite final logical frame once through the display manager
   - one destination rect
   - one scale factor
   - one offset policy

That is the architectural change that removes most of the current ambiguity.

## Concrete Refactor Plan

### Phase 1: Freeze the render contract

Create a small runtime object, for example `RenderFrameContext`, owned by the engine or renderer.

It should carry:

- `window_width`, `window_height`
- `game_width`, `game_height`
- `scene_width`, `scene_height`
- `display_scale`, `offset_x`, `offset_y`
- `game_area_rect`
- `camera`
- `cinematic_canvas_width`, `cinematic_canvas_height` if active

Rules:

- all UI code reads this context, not `Display.reference_width` globals
- all shader/effect code reads this context, not `Display.reference_width` globals

### Phase 2: Remove class-global display resolution as runtime authority

Keep defaults if needed, but stop using:

- `Display.reference_width`
- `Display.reference_height`

as live render authority across the engine.

Instead:

- `Display` instance owns active game logical size
- `Renderer` owns active render targets sized from that instance
- scene/effect/UI code receives active dimensions from context

Refactor priority files:

- [display.cr](/Users/remy/dev/point_click_engine/src/graphics/core/display.cr)
- [renderer.cr](/Users/remy/dev/point_click_engine/src/graphics/core/renderer.cr)
- [engine.cr](/Users/remy/dev/point_click_engine/src/core/engine.cr)
- [effect_manager.cr](/Users/remy/dev/point_click_engine/src/graphics/effects/effect_manager.cr)
- [action_overlay_manager.cr](/Users/remy/dev/point_click_engine/src/actions/action_overlay_manager.cr)
- [floating_dialog.cr](/Users/remy/dev/point_click_engine/src/ui/floating_dialog.cr)
- [floating_text.cr](/Users/remy/dev/point_click_engine/src/ui/floating_text.cr)

### Phase 3: Move final display scaling out of shader/effect implementations

All shader scene effects should change contract.

Current behavior:

- effect owns RT
- effect renders scene callback into RT
- effect draws directly to `display.game_area_screen_rect`

New behavior:

- renderer owns logical scene render target
- effect receives input texture and output texture
- effect returns processed logical texture
- renderer/display performs the one final scale-to-screen composite

Refactor priority files:

- [rain_shader.cr](/Users/remy/dev/point_click_engine/src/graphics/effects/scene_effects/shader/rain_shader.cr)
- [fog_shader.cr](/Users/remy/dev/point_click_engine/src/graphics/effects/scene_effects/shader/fog_shader.cr)
- [darkness_shader.cr](/Users/remy/dev/point_click_engine/src/graphics/effects/scene_effects/shader/darkness_shader.cr)
- [underwater_shader.cr](/Users/remy/dev/point_click_engine/src/graphics/effects/scene_effects/shader/underwater_shader.cr)
- [transition_effect.cr](/Users/remy/dev/point_click_engine/src/graphics/effects/scene_effects/transition_effect.cr)
- [shader_effect.cr](/Users/remy/dev/point_click_engine/src/graphics/effects/shader_effect.cr)

### Phase 4: Split world UI from screen UI explicitly

Define two categories:

- world-anchored overlays
  - floating character dialogs
  - world labels
  - hotspot highlights
- screen/logical UI
  - menus
  - inventory
  - classic bottom dialogs
  - cursor

World-anchored overlay rule:

- convert world position to UI/logical position through the current camera before drawing

Screen UI rule:

- no camera involvement at all

This should fix the current floating dialog disappearance correctly.

Refactor priority files:

- [floating_dialog.cr](/Users/remy/dev/point_click_engine/src/ui/floating_dialog.cr)
- [floating_text.cr](/Users/remy/dev/point_click_engine/src/ui/floating_text.cr)
- [dialog_manager.cr](/Users/remy/dev/point_click_engine/src/ui/dialog_manager.cr)
- [dialog.cr](/Users/remy/dev/point_click_engine/src/ui/dialog.cr)
- [engine.cr](/Users/remy/dev/point_click_engine/src/core/engine.cr)

### Phase 5: Make cinematic overlays a first-class layer

`ActionOverlayManager` should not infer its target space from global reference dimensions.

New rule:

- it renders into explicit `CinematicSpace`
- renderer maps that space into the current logical frame

Needed changes:

- make canvas dimensions explicit and local
- stop reading `Display.reference_width/height` directly
- define how cinematic backgrounds fill or fit into the logical frame

Refactor priority files:

- [action_overlay_manager.cr](/Users/remy/dev/point_click_engine/src/actions/action_overlay_manager.cr)
- [action_executor.cr](/Users/remy/dev/point_click_engine/src/actions/action_executor.cr)
- [engine.cr](/Users/remy/dev/point_click_engine/src/core/engine.cr)

### Phase 6: Stop treating scenes as if their logical size and the game logical size are interchangeable

A scene can be:

- same size as game logical output
- larger, with camera scrolling
- smaller, but still letterboxed or stretched intentionally

Today those distinctions are blurred.

Needed changes:

- renderer must know scene framebuffer size separately from game logical output size
- background renderer should scale only within scene space
- display scaling should happen only after the logical frame is complete

Refactor priority files:

- [scene.cr](/Users/remy/dev/point_click_engine/src/scenes/scene.cr)
- [background_renderer.cr](/Users/remy/dev/point_click_engine/src/scenes/background_renderer.cr)
- [camera.cr](/Users/remy/dev/point_click_engine/src/graphics/core/camera.cr)

## What Not To Do

Do not do more of these:

- patch menu mouse mapping independently from the frame graph
- add more OS-specific fullscreen branches in the engine
- let shader effects draw directly to display destination rects
- keep adding direct reads of `Display.reference_width/height`
- hide bugs with content-side darkness tuning before the render contract is fixed

Those all make the system harder to reason about.

## Spec Strategy

The current specs pass, but they do not protect the actual failure modes well enough.

Relevant specs I ran after this analysis:

- `crystal spec spec/graphics/display_spec.cr spec/ui/menu_system_spec.cr --error-trace`
- result: `34 examples, 0 failures, 0 errors, 0 pending`

That means the narrow unit checks are green, but they are not covering the real regressions from the captures.

### New spec work required

#### 1. Display contract specs

Add explicit tests for:

- one final composite rect from logical frame to window
- no direct effect code dependence on class-global reference dimensions
- fullscreen/windowed scale and offset consistency

#### 2. Render pipeline specs

Add small headless/instrumented tests for:

- world render path
- shader effect render path
- UI render path
- final display composite path

The important assertion is not "it compiles"; it is "all paths end in the same display composite contract".

#### 3. Floating dialog positioning specs

Add coverage for:

- camera at `(0,0)`
- camera moved
- floating dialog world anchor converting correctly into UI/logical position

This should directly prevent the current disappearing-dialog regression.

#### 4. Menu/input coordination specs

Current menu specs are too local. Add cases that assert:

- menu render bounds and menu hit-test bounds are in the same space
- raw screen click -> transformed logical point -> item hit is consistent

#### 5. Shader/effect integration specs

Add focused tests that assert:

- scene effect render target size matches active logical frame
- effect compositing returns logical frame output, not screen-space output

## Recommended Implementation Order

1. Introduce `RenderFrameContext` and make the renderer own it.
2. Remove runtime authority from `Display.reference_width/height`.
3. Refactor shader scene effects to consume/produce logical render textures only.
4. Split world-anchored overlays from screen UI.
5. Refactor cinematic overlays onto explicit `CinematicSpace`.
6. Update specs to cover the new contracts.
7. Only after that, retune `crystal_mystery` content such as laboratory darkness and intro hero assets.

## Expected Benefits

If this refactor is done correctly:

- fullscreen bugs become easier to reason about because scaling happens once
- menu/cursor/input alignment stays stable
- floating dialogs stop disappearing when the camera moves
- shader-heavy scenes stop having a special display path
- `crystal_mystery` can move to a clear 16:9 or 4:3 choice without fighting hidden engine defaults

## Immediate Recommendation

Do not continue with local fixes on the current render stack.

The next work should be:

- implement the render/display refactor above in phases
- keep the engine generic
- add the missing specs alongside each phase

That is the sane path to fixing the viewport collapse and disappearing dialogs without creating another round of contradictory patches.
