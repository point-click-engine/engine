# Render Pipeline Architecture Rebuild Plan

## Goal

Rebuild the engine render pipeline so that:

- every frame goes through one authoritative render path
- world, cinematic overlays, UI, and cursor each have a clearly defined space
- scene shader effects cannot change where the game appears on screen
- fullscreen/windowed behavior uses one final presentation stage only
- input hit-testing is aligned with the visibly rendered result
- the pipeline is spec-tested at the architectural level, not only via manual captures

This plan is deliberately narrower and more concrete than the older refactor notes. It is based on the current code, the recent `crystal_mystery` captures, and the fact that the bottom-left partial render still reproduces after entering the `laboratory` scene with a shader-based darkness effect.

## Current Diagnosis

## What the latest evidence proves

From [crystal_mystery_run5.log](/Users/remy/dev/point_click_engine/tmp/crystal_mystery_run5.log):

- the intro transitions into `laboratory`
- immediately after that transition, the engine transfers `1` scene effect to the effect manager
- that scene effect is the `darkness` spotlight declared in [laboratory.yaml](/Users/remy/dev/point_click_engine/crystal_mystery/scenes/laboratory.yaml)

That means:

- the `laboratory` shader path is the trigger
- but the real bug is still engine-side, because a scene effect should not be able to alter the final display contract

## Why the current architecture still fails

The engine still has multiple render contracts active at once.

### 1. Normal scene rendering and shader scene rendering are different pipelines

In [engine.cr](/Users/remy/dev/point_click_engine/src/core/engine.cr):

- normal frames go through `render_scene_content`
- shader/effect frames go through `render_shader_scene`
- those two paths do not share one explicit frame graph

That is the central architectural fault.

### 2. Display scaling is still applied as a rendering mechanism instead of a final presentation stage

In [display.cr](/Users/remy/dev/point_click_engine/src/graphics/core/display.cr):

- `with_game_coordinates`
- `draw_logical_texture`

Both are effectively presentation operations. But the engine is still using them inside scene/effect rendering flows instead of reserving them for the final composite only.

### 3. Shader effects still partially own render target and presentation concerns

In files like:

- [darkness_shader.cr](/Users/remy/dev/point_click_engine/src/graphics/effects/scene_effects/shader/darkness_shader.cr)
- [rain_shader.cr](/Users/remy/dev/point_click_engine/src/graphics/effects/scene_effects/shader/rain_shader.cr)
- [fog_shader.cr](/Users/remy/dev/point_click_engine/src/graphics/effects/scene_effects/shader/fog_shader.cr)
- [underwater_shader.cr](/Users/remy/dev/point_click_engine/src/graphics/effects/scene_effects/shader/underwater_shader.cr)
- [transition_effect.cr](/Users/remy/dev/point_click_engine/src/graphics/effects/scene_effects/transition_effect.cr)

the effect object still:

- renders into its own offscreen texture
- runs a shader
- draws the result to a rectangle

That should not be effect responsibility. Effects should transform textures, not decide final display composition.

### 4. The renderer still combines camera, render-target ownership, and display transform too early

In [renderer.cr](/Users/remy/dev/point_click_engine/src/graphics/core/renderer.cr):

- `render(apply_display_transform)`
- `@display.with_game_coordinates`

The renderer still has a boolean branch for whether display transform is applied. That is a sign the renderer is not yet operating in one stable logical framebuffer space.

### 5. Spaces are still not explicit enough

The codebase still mixes:

- world/scene space
- logical game/UI space
- cinematic overlay space
- final screen space

The new `FrameContext` was a step in the right direction, but the engine still does not enforce those spaces through a single render graph.

## Target Architecture

The engine should render every frame through these exact stages.

### Stage 1. Build `RenderFrame`

At the start of each frame, build one runtime render object, for example:

- `RenderFrame`

It should contain:

- active `Display`
- active `Renderer`
- active `Camera`
- logical game width and height
- scene width and height
- optional cinematic canvas width and height
- active scene
- active scene effect chain
- active UI state
- authoritative final presentation rectangle

This object replaces ad hoc reads from:

- `Display.reference_width`
- `Display.reference_height`
- raw renderer/display globals

### Stage 2. Render world scene into `world_rt`

The world pass should render only world-space content:

- background
- world props
- characters
- world-space debug overlays
- hotspot highlights if they are world-space

Rules:

- camera applies here
- display scaling does not apply here
- UI does not draw here
- shader effects do not draw directly here

### Stage 3. Run scene effect chain from `world_rt` to `scene_rt`

All scene shader effects should be converted to one contract:

- input: a source logical render texture
- output: a destination logical render texture

Effects must not:

- decide destination screen rectangles
- call display transform helpers
- assume they own the final framebuffer

This applies to:

- transitions
- darkness
- rain
- fog
- underwater

The effect manager should own the chain, not the individual effect object.

### Stage 4. Composite cinematic overlays into `scene_rt`

Cinematic/action overlays should draw after the world/effect chain and before UI.

This includes:

- action overlay backgrounds
- cinematic sprites
- sequence text
- global script runner overlays
- scene script overlays that are cinematic-authorized

These should use explicit cinematic-to-logical mapping through `FrameContext`, not direct display or raw screen logic.

### Stage 5. Composite UI into `ui_rt` or directly into final logical frame

UI must be separated from world space.

This includes:

- main menu
- pause menu
- inventory
- classic dialogs
- floating dialog bubbles after world-to-UI projection
- floating text choices
- tutorial hints
- cursor
- debug HUD

Rules:

- no camera transform here
- no display transform here
- all hit-testing happens in the same UI logical space

### Stage 6. Present once through display manager

There must be one and only one final presentation step:

- source: final logical texture
- destination: active game area rect in the window/fullscreen surface

Only the display manager should know:

- scale factor
- bars/pillarboxing
- offsets
- fullscreen/windowed destination rect

No other system should draw directly to screen coordinates for game content.

## Required Refactor Work

## Workstream 1. Make presentation a strict final step

### Problem

`Display#with_game_coordinates` is currently used as a rendering mechanism.

### Change

Change the contract so:

- scene/world/effects/UI render into logical render targets only
- `Display` is used only to present the final logical texture

### Files

- [display.cr](/Users/remy/dev/point_click_engine/src/graphics/core/display.cr)
- [renderer.cr](/Users/remy/dev/point_click_engine/src/graphics/core/renderer.cr)
- [engine.cr](/Users/remy/dev/point_click_engine/src/core/engine.cr)

### Concrete steps

1. Add explicit final presentation API on `Display`, for example:
   - `present(texture : RL::Texture2D)`
2. Remove or deprecate `with_game_coordinates` from render orchestration.
3. Make `draw_logical_texture` the only final presentation helper, or replace it with a clearer `present`.
4. Ensure the renderer no longer branches on `apply_display_transform`.

### Acceptance criteria

- no world or UI draw code is wrapped in display transform helpers
- only the final present step uses the display rect/scale/offset

## Workstream 2. Replace `render_scene_content` / `render_shader_scene` split with one frame graph

### Problem

The engine still has separate normal and shader paths.

### Change

Replace them with one render function, for example:

- `render_frame(frame : RenderFrame)`

### Files

- [engine.cr](/Users/remy/dev/point_click_engine/src/core/engine.cr)
- [effect_manager.cr](/Users/remy/dev/point_click_engine/src/graphics/effects/effect_manager.cr)

### Concrete steps

1. Delete the special branching architecture:
   - `render_scene_content`
   - `render_shader_scene`
2. Replace with:
   - `render_world_pass`
   - `apply_scene_effect_chain`
   - `render_cinematic_pass`
   - `render_ui_pass`
   - `present_final_frame`
3. Keep branching only inside the effect chain itself, not at the top-level engine render method.

### Acceptance criteria

- entering a shader-based scene uses the same top-level render pipeline as any other scene
- effect activation cannot change the frame graph shape

## Workstream 3. Move shader effects to pure texture-in / texture-out operations

### Problem

Effects still render and composite internally.

### Change

Change scene effects to a standard API such as:

- `apply(source : RL::RenderTexture2D, destination : RL::RenderTexture2D, frame : RenderFrame)`

### Files

- [darkness_shader.cr](/Users/remy/dev/point_click_engine/src/graphics/effects/scene_effects/shader/darkness_shader.cr)
- [rain_shader.cr](/Users/remy/dev/point_click_engine/src/graphics/effects/scene_effects/shader/rain_shader.cr)
- [fog_shader.cr](/Users/remy/dev/point_click_engine/src/graphics/effects/scene_effects/shader/fog_shader.cr)
- [underwater_shader.cr](/Users/remy/dev/point_click_engine/src/graphics/effects/scene_effects/shader/underwater_shader.cr)
- [transition_effect.cr](/Users/remy/dev/point_click_engine/src/graphics/effects/scene_effects/transition_effect.cr)
- [shader_effect.cr](/Users/remy/dev/point_click_engine/src/graphics/effects/shader_effect.cr)
- [effect_manager.cr](/Users/remy/dev/point_click_engine/src/graphics/effects/effect_manager.cr)

### Concrete steps

1. Stop allocating per-effect render textures sized from `Display.reference_width/height` inside the effect.
2. Let the renderer or effect manager own a reusable pair of logical render targets.
3. Make effect uniforms read dimensions from the source texture or frame context.
4. Make effects output into the provided destination RT only.
5. Remove any direct draw to `display.logical_rect`, `game_area_screen_rect`, or raw window coordinates from the effects.

### Acceptance criteria

- shader effect code contains no display/presentation math
- the darkness effect cannot move the game image, only transform the pixels

## Workstream 4. Separate spaces explicitly

### Problem

The code still mixes world, UI, and cinematic coordinates in draw/update code.

### Change

Promote the spaces to first-class concepts in `FrameContext` or a new `RenderFrame`.

### Spaces

- `WorldSpace`
- `UIScreenSpace`
- `CinematicSpace`
- `ScreenSpace` only for the final present step

### Files

- [frame_context.cr](/Users/remy/dev/point_click_engine/src/graphics/core/frame_context.cr)
- [dialog_manager.cr](/Users/remy/dev/point_click_engine/src/ui/dialog_manager.cr)
- [floating_dialog.cr](/Users/remy/dev/point_click_engine/src/ui/floating_dialog.cr)
- [floating_text.cr](/Users/remy/dev/point_click_engine/src/ui/floating_text.cr)
- [action_overlay_manager.cr](/Users/remy/dev/point_click_engine/src/actions/action_overlay_manager.cr)
- [menu_system.cr](/Users/remy/dev/point_click_engine/src/ui/menu_system.cr)

### Concrete steps

1. Add explicit conversion helpers:
   - world -> ui
   - cinematic -> ui/logical
   - ui -> world only when truly needed
2. Remove direct use of raw screen coordinates from menu/dialog logic.
3. Move cursor rendering to UI space exclusively.
4. Ensure floating dialogs are positioned from world-to-UI projection every frame.

### Acceptance criteria

- menus never consult camera
- dialogs never draw in raw screen coordinates
- cinematic overlays never assume the display rect directly

## Workstream 5. Remove global runtime authority from `Display.reference_width/height`

### Problem

The class globals are still acting as hidden live state.

### Change

Keep them only as default config constants, not as runtime truth.

### Files

- [display.cr](/Users/remy/dev/point_click_engine/src/graphics/core/display.cr)
- any callers still reading `Display.reference_width/height`

### Concrete steps

1. Audit every use of `Display.reference_width` and `Display.reference_height`.
2. Replace runtime reads with:
   - active display instance
   - renderer logical size
   - frame context dimensions
3. Keep `DEFAULT_REFERENCE_WIDTH/HEIGHT` only as defaults for new displays or config fallback.

### Acceptance criteria

- runtime rendering code does not depend on display class globals
- tests can instantiate multiple displays/engines without hidden coupling

## Workstream 6. Centralize render-target ownership

### Problem

Render textures are still partially owned by effects and partially by the renderer.

### Change

Make the renderer own reusable logical render targets, for example:

- `world_rt`
- `scene_rt_a`
- `scene_rt_b`
- optional `ui_rt`

### Files

- [renderer.cr](/Users/remy/dev/point_click_engine/src/graphics/core/renderer.cr)
- [effect_manager.cr](/Users/remy/dev/point_click_engine/src/graphics/effects/effect_manager.cr)

### Concrete steps

1. Add explicit logical RT lifecycle management to the renderer.
2. Resize them only when the logical resolution changes.
3. Make effect manager consume those RTs instead of allocating its own.

### Acceptance criteria

- no scene shader effect allocates its own main scene RT
- logical RT ownership is visible in one place

## Workstream 7. Add diagnostic instrumentation before further visual debugging

### Problem

The remaining render issue has been too hard to pin down from logs alone.

### Change

Add temporary debug instrumentation that can be enabled in debug mode.

### Needed runtime diagnostics

- current frame graph stage
- source and destination sizes for each effect pass
- final present rect
- active scene logical size
- active world RT size
- active effect RT size
- whether any draw to window happens before final present

### Files

- [engine.cr](/Users/remy/dev/point_click_engine/src/core/engine.cr)
- [renderer.cr](/Users/remy/dev/point_click_engine/src/graphics/core/renderer.cr)
- [effect_manager.cr](/Users/remy/dev/point_click_engine/src/graphics/effects/effect_manager.cr)
- shader effect classes

### Acceptance criteria

- a single debug run can tell exactly where the frame became mis-sized or mis-positioned

## Workstream 8. Lock the architecture with new specs

### Problem

The old specs passed while the live frame was still wrong because they tested local behavior instead of the actual frame graph contract.

### Change

Add architectural specs.

### Required new spec categories

1. Frame graph specs
   - normal scene and shader scene go through the same top-level pipeline

2. Effect composition specs
   - effect chain never changes final present rect
   - darkness/rain/fog consume one RT and produce one RT of the same logical size

3. UI space specs
   - menus hit-test in the same logical space they render in
   - dialogs project world anchors into UI space correctly

4. Presentation specs
   - fullscreen/windowed changes only alter final display rect and scale, not logical draw positions

5. Integration smoke specs
   - entering `laboratory` with its darkness effect keeps final presentation rect unchanged

### Suggested files

- new specs under [spec/graphics](/Users/remy/dev/point_click_engine/spec/graphics)
- new specs under [spec/integration](/Users/remy/dev/point_click_engine/spec/integration)

## Migration Strategy

Do this in the following order.

### Phase A. Instrument and freeze current behavior

1. add frame-graph debug logging
2. add a failing integration spec for `laboratory` darkness presentation
3. do not attempt more local shader fixes before this exists

### Phase B. Move presentation to a final-only step

1. remove display transform wrapping from scene/effect/UI drawing
2. add final `present` step
3. keep current visuals otherwise as intact as possible

### Phase C. Unify normal and shader paths

1. replace separate top-level render branches with one frame graph
2. make shader paths use texture-in / texture-out chain

### Phase D. Clean up spaces

1. world pass
2. cinematic pass
3. UI pass
4. cursor pass

### Phase E. Remove runtime global resolution authority

1. replace `Display.reference_*` runtime reads
2. keep defaults only

### Phase F. Expand regression coverage

1. add the missing architectural specs
2. rerun grouped full suite
3. validate with a fresh `crystal_mystery` capture

## What Not To Do

Do not:

- add more one-off fixes inside `darkness_shader.cr` without changing the pipeline contract
- add more menu/dialog coordinate hacks unrelated to the frame graph
- let effect classes decide final destination rectangles
- mix fullscreen behavior into world or UI draw paths
- keep both old and new render paths alive long-term

## Success Criteria

The architecture is considered fixed when all of these are true:

- `crystal_mystery` entering `laboratory` does not visually collapse into a corner
- enabling or disabling scene shader effects does not alter the final presentation rect
- world, cinematic, and UI rendering are separable and individually testable
- menus, dialogs, and cursor remain aligned in fullscreen and windowed modes
- grouped full spec suite passes
- a new playthrough capture shows the same scene framing before and after effect activation, aside from the intended visual effect itself

## Immediate Recommendation

The next implementation pass should start with:

1. add the explicit frame-graph diagnostics
2. add one failing integration/spec for the `laboratory` darkness case
3. then rebuild the render path so `Display` only presents the final logical texture once

That is the smallest sane route to a durable fix.
