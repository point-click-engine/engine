# Engine Configurable Reference Resolution Plan

## Goal

Remove the hardcoded engine-wide reference resolution assumption and let each game declare its intended logical/reference resolution cleanly.

The latest capture strongly suggests that `crystal_mystery` is mixing:

- 16:9 art and cinematic layouts (`320x180` style assets)
- a 4:3 engine/display reference (`1024x768`)

That mismatch is creating avoidable rendering and input problems.

## Problems To Solve

- `Graphics::Core::Display` hardcodes `REFERENCE_WIDTH = 1024` and `REFERENCE_HEIGHT = 768`.
- Renderer logic and overlay logic assume those constants.
- Scene assets and sequences may be authored for a different aspect ratio.
- The game config already contains display target fields, but the engine does not fully treat them as the authoritative reference contract.

## Relevant Code

- `src/graphics/core/display.cr`
- `src/graphics/core/renderer.cr`
- `src/core/game_config.cr`
- `src/scenes/scene.cr`
- `src/actions/action_overlay_manager.cr`
- `src/actions/action_executor.cr`

## Plan

### Phase 1. Inventory Current Reference Assumptions

Find every code path that depends on:

- `REFERENCE_WIDTH`
- `REFERENCE_HEIGHT`
- implicit `1024x768`

Classify each use as:

- true engine reference usage
- UI layout default
- temporary fallback
- bug-prone hardcoding

Acceptance:

- every remaining hardcoded reference usage is intentional and documented

### Phase 2. Define A Real Reference-Resolution API

Introduce a clean runtime concept for the game’s logical/reference resolution, driven by config.

Requirements:

- available to display, renderer, scene systems, and action/overlay systems
- initialized before render/input systems depend on it
- stable across fullscreen toggles and resizes

Possible source:

- `game_config.display.target_width`
- `game_config.display.target_height`

Acceptance:

- the engine runtime exposes the configured reference resolution without depending on hardcoded global constants

### Phase 3. Migrate Display And Renderer

Update:

- display scaling
- game-area rect calculation
- renderer texture setup
- any final blit assumptions

so they use the configured reference resolution.

Acceptance:

- the renderer no longer assumes `1024x768`
- render textures match the configured logical contract

### Phase 4. Migrate Overlay And Sequence Systems

Update action/overlay systems so their default logical canvas is derived from the active game reference, not from legacy constants.

Acceptance:

- sequence text/sprites/backgrounds align correctly for games that are not 4:3

### Phase 5. Reconcile Scene Logical Size

Clarify the contract between:

- game reference resolution
- scene logical size
- background asset size

Rules should be explicit:

- when scene logical size differs from game reference size
- when backgrounds should fit, fill, or stretch
- how camera/navigation coordinates relate to both

Acceptance:

- scenes do not accidentally appear inside a smaller rectangle just because their art aspect ratio differs

## `crystal_mystery` Follow-Up

After the engine supports this properly:

- set `crystal_mystery` to a 16:9 reference resolution appropriate for its art
- re-check hotspot placement, UI placement, and intro sequence coordinates

This game-side step should happen after the engine contract exists, not before.

## Completion Criteria

- engine reference resolution is configurable per game
- display/renderer no longer hardcode `1024x768`
- a 16:9 game can render correctly without layered internal bars
