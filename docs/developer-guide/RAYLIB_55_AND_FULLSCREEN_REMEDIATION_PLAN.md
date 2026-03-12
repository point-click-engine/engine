# Raylib 5.5 Upgrade And Fullscreen Remediation Plan

## Goal

Upgrade the engine from the current Raylib 5.0-era Crystal binding to a maintained Raylib 5.5 binding on the `rmarronnier/raylib-cr` fork, then fix the current fullscreen/input/render mismatch using a generic engine contract instead of OS-specific workarounds.

This plan treats the fullscreen bug as a systems issue across:

- the Raylib binding version
- window/fullscreen mode switching
- screen vs render vs logical coordinate spaces
- final presentation scaling
- mouse input transformation

The explicit constraint is:

- no permanent OS-specific branching in the engine unless the binding or Raylib itself requires it and that requirement is documented upstream

## Current Situation

The engine currently depends on a Raylib 5.0 binding:

- [shard.yml](/Users/remy/dev/point_click_engine/shard.yml)
- [shard.lock](/Users/remy/dev/point_click_engine/shard.lock)
- [lib/raylib-cr/shard.yml](/Users/remy/dev/point_click_engine/lib/raylib-cr/shard.yml)
- [lib/raylib-cr/src/raylib-cr/raylib.cr](/Users/remy/dev/point_click_engine/lib/raylib-cr/src/raylib-cr/raylib.cr)

Observed runtime failures in `crystal_mystery` fullscreen mode:

- intro rendered only in a corner / partial black screen
- menu visually centered but mouse hit-testing incorrect
- alternate fullscreen attempt left dock/menu bar visible

Those symptoms strongly suggest inconsistent use of:

- `get_screen_width/height`
- `get_render_width/height`
- logical game resolution
- display scaling offsets
- raw mouse coordinates

## Principles

1. Upgrade the binding before adding more engine workarounds.
2. Keep fullscreen handling generic in the engine.
3. Separate logical game resolution from physical window/render size.
4. Ensure render and input use the same transform source.
5. Prove behavior with instrumentation and reproduction steps, not guesswork.

## Deliverables

1. Engine switched to `rmarronnier/raylib-cr`.
2. Fork updated to Raylib 5.5 and validated against this engine.
3. Fullscreen behavior fixed without engine OS-branching.
4. Mouse/menu hit-testing correct in fullscreen.
5. Intro and gameplay presentation fill the intended game area correctly.
6. A clean upstream PR from the fork if the binding changes are generic.

## Phase 1: Baseline And Isolation

### 1.1 Freeze the current failing behavior

Capture a reproducible baseline from the current engine with current binding:

- launch `crystal_mystery`
- windowed mode sanity check
- fullscreen startup check
- runtime `F11` toggle check
- menu hover/click check
- intro presentation check

Artifacts to keep in `tmp/`:

- fullscreen screenshots
- one short mp4 in fullscreen
- launch log
- values dumped for:
  - `RL.get_screen_width`
  - `RL.get_screen_height`
  - `RL.get_render_width`
  - `RL.get_render_height`
  - `RL.get_window_scale_dpi`
  - display `window_width`
  - display `window_height`
  - display `scale_factor`
  - display `offset_x`
  - display `offset_y`
  - raw mouse position
  - transformed mouse position
  - menu bounds

### 1.2 Remove temporary fullscreen detours

Before the real fix:

- remove any temporary OS-specific fullscreen logic added only as a workaround
- keep the engine on a single generic fullscreen path
- do not preserve dead branches that hide the real problem

Acceptance criteria:

- engine fullscreen code has one generic contract
- no Darwin-only fullscreen branch remains unless justified by the upgraded binding work

## Phase 2: Move Dependency To The Fork

### 2.1 Point `shard.yml` to the fork

Update dependency source in [shard.yml](/Users/remy/dev/point_click_engine/shard.yml):

- use `github: rmarronnier/raylib-cr`
- pin by `commit:` while iterating

Recommended temporary shape:

```yaml
dependencies:
  raylib-cr:
    github: rmarronnier/raylib-cr
    commit: <tested-commit>
```

Do not use a floating branch during stabilization.

### 2.2 Refresh vendored dependency state

Steps:

- `shards update raylib-cr`
- confirm `shard.lock` points to the fork
- verify `lib/raylib-cr` remote/content matches the fork, not stale workspace content

Acceptance criteria:

- local dependency tree is cleanly sourced from the fork
- no accidental mixed provenance in `lib/raylib-cr`

## Phase 3: Upgrade The Fork To Raylib 5.5

### 3.1 Compare current fork against official Raylib 5.5

In `rmarronnier/raylib-cr`:

- diff the existing generated/bound API against Raylib 5.5 headers
- identify new, changed, or removed APIs
- verify window/fullscreen/render/DPI APIs in particular

Priority APIs for this issue:

- `ToggleFullscreen`
- `ToggleBorderlessWindowed`
- `IsWindowFullscreen`
- `SetWindowMonitor`
- `SetWindowSize`
- `GetScreenWidth`
- `GetScreenHeight`
- `GetRenderWidth`
- `GetRenderHeight`
- `GetWindowScaleDPI`

### 3.2 Update binding metadata

Update in fork:

- `version`
- `raylib_version`
- README/version references
- install/build docs if they mention old Raylib assumptions

### 3.3 Regenerate or patch bindings

Depending on how the fork is maintained:

- use generator scripts if present
- otherwise patch the binding definitions carefully

Requirements:

- match Raylib 5.5 signatures exactly
- keep backward compatibility where possible
- avoid engine-specific patches inside the shard

### 3.4 Validate fork standalone

On the fork itself:

- build the shard
- run its examples or smoke tests if available
- specifically validate macOS window/fullscreen/render APIs

Acceptance criteria:

- fork builds cleanly
- binding reports Raylib 5.5
- no broken signatures for window/render APIs

## Phase 4: Instrument The Engine Against The Upgraded Binding

### 4.1 Add temporary runtime diagnostics

Add temporary debug logging in the engine around:

- startup after `init_window`
- after fullscreen enter
- after fullscreen exit
- before menu render
- before menu input handling
- before intro overlay draw

Log:

- logical game size
- display size
- Raylib screen size
- Raylib render size
- DPI scale
- display game area rect
- raw mouse
- game-space mouse
- menu bounds

These logs are for diagnosis only and should be easy to remove once fixed.

### 4.2 Reproduce with the upgraded binding

Repeat the same fullscreen recordings and screenshots from Phase 1.

Decision point:

- if the bug disappears under Raylib 5.5, remove temporary diagnostics and stabilize
- if the bug remains, fix the engine contract with the upgraded binding as source of truth

## Phase 5: Define The Correct Fullscreen Contract In The Engine

This is the key architectural step.

The engine needs one clear separation:

- logical game resolution
  - example: `1024x768`
- physical window size
  - current drawable/window size reported by Raylib
- render size
  - actual render target size used by the platform/backend
- presentation transform
  - scale and offset from logical game area to presented screen area

### 5.1 Keep logical dimensions stable

`engine.window_width` and `engine.window_height` should remain logical game dimensions, not monitor size.

Fullscreen transitions must not silently mutate logical game resolution.

### 5.2 Make `Display` authoritative for presentation

`Display` should be the single source for:

- current physical presentation size
- scale factor
- offset
- game area rectangle
- screen-to-game transform
- game-to-screen transform

No other system should invent its own fullscreen scaling logic.

### 5.3 Use the same coordinate source for render and input

Menu hit-testing, scene input, and overlay positioning must all derive from the same `Display` mapping.

That means:

- if menu renders in screen-space over the presented game area, mouse must be compared in the same screen-space
- if menu renders in logical game-space, mouse must be transformed into game-space first

Do not mix these modes.

## Phase 6: Fix The Menu Contract

Current evidence says menu rendering and menu input are using inconsistent spaces.

### 6.1 Decide menu space explicitly

Pick one of two models and keep it consistent:

1. Menu in logical game-space
   - render menu inside the logical game surface
   - transform mouse through `Display.screen_to_game`

2. Menu in screen-space
   - render menu after final presentation
   - use raw screen-space mouse
   - layout against `Display.game_area_screen_rect`

Recommendation:

- use screen-space for menus if they are intended to overlay the presented screen
- use `Display.game_area_screen_rect` as the only layout frame

### 6.2 Fix hit-testing

Ensure menu item bounds and input use the exact same coordinate basis.

Acceptance criteria:

- cursor hover matches visible highlight
- click activates the visible item under the cursor
- behavior remains correct in windowed and fullscreen modes

## Phase 7: Fix Intro And Overlay Presentation

Current evidence says intro overlays/backgrounds still rely on raw screen dimensions in some paths.

Files already implicated:

- [action_overlay_manager.cr](/Users/remy/dev/point_click_engine/src/actions/action_overlay_manager.cr)
- [action_executor.cr](/Users/remy/dev/point_click_engine/src/actions/action_executor.cr)

### 7.1 Audit all raw `get_screen_width/height` overlay math

Replace ad hoc use of raw screen dimensions where appropriate with:

- logical canvas dimensions
- `Display.game_area_screen_rect`
- or a clearly defined overlay presentation transform

### 7.2 Distinguish fullscreen screen from game area

If the display uses letterboxing/pillarboxing:

- backgrounds that should fill only the game area must use the game area rect
- only true fullscreen effects should fill the full physical screen

### 7.3 Validate intro sequence stages

Specifically confirm in fullscreen:

- opening sky fills correctly
- manor exterior fills correctly
- laboratory handoff fills correctly
- sequence text positions are correct
- sprites do not render in a corner due to wrong screen-space assumptions

Acceptance criteria:

- intro content renders inside the intended game area
- no corner-clipped or partial-screen presentation remains

## Phase 8: Fullscreen Toggle Semantics

### 8.1 Revalidate `F11`

Once the display contract is fixed:

- startup fullscreen should work
- `F11` runtime toggle should work
- returning to windowed mode should restore correct window size and input mapping

### 8.2 Avoid hidden mode switches

Do not switch between exclusive fullscreen and borderless fullscreen in arbitrary engine branches.

If Raylib 5.5 exposes better generic fullscreen behavior, use that consistently.

If a platform-specific limitation exists at the binding/Raylib layer:

- document it in the shard
- avoid leaking platform branches throughout engine code

## Phase 9: Testing Matrix

### 9.1 Engine-level checks

Run:

- targeted engine specs
- display/menu/input related specs
- full fast suite
- full grouped suite if needed

### 9.2 Manual runtime matrix

For `crystal_mystery`:

1. windowed startup
2. fullscreen startup
3. windowed -> `F11` fullscreen
4. fullscreen -> `F11` windowed
5. main menu hover/click
6. intro first minute
7. return to gameplay

Record:

- screenshots
- one mp4
- matching logs

### 9.3 Acceptance criteria

The issue is not done until all of these are true:

- menu is visually centered in fullscreen
- menu hover and click match the cursor
- intro fills the intended game area correctly
- no dock/menu-bar partial fullscreen if true fullscreen is intended
- no engine OS-specific workaround remains for the bug
- build and relevant specs pass

## Phase 10: Upstream The Binding Work

If the `rmarronnier/raylib-cr` fork changes are generic and clean:

1. squash/finalize the fork work
2. open PR(s) upstream
3. keep engine changes separate from binding changes

Recommended split:

- PR 1: Raylib 5.5 binding upgrade
- PR 2: any binding bugfix specifically related to fullscreen/render/DPI APIs

Do not bundle engine behavior changes into the binding PR.

## Risks

### Risk 1: Binding upgrade reveals additional engine bugs

Likely. That is acceptable. The upgrade may expose assumptions that were accidentally tolerated under 5.0.

### Risk 2: macOS fullscreen semantics differ between true fullscreen and borderless modes

Possible. That belongs in the binding/Raylib behavior analysis, not as scattered engine hacks.

### Risk 3: Some UI systems already depend on incorrect `engine.window_width/height` behavior

Possible. Audit and normalize those usages after the display contract is fixed.

## Recommended Execution Order

1. remove temporary OS-specific fullscreen detours
2. switch dependency to `rmarronnier/raylib-cr`
3. upgrade fork to Raylib 5.5
4. instrument live fullscreen values
5. fix display contract
6. fix menu coordinate contract
7. fix intro/overlay presentation contract
8. validate fullscreen startup and `F11`
9. upstream shard PR

## Definition Of Done

This work is complete only when:

- the engine depends on the forked Raylib 5.5 binding
- fullscreen works without engine platform hacks
- menu render and hit-testing are aligned
- intro renders correctly in fullscreen
- the root cause is documented
- the shard changes are ready for upstream contribution
