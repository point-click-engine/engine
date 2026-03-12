# Engine Playthrough Regression Coverage Plan

## Goal

Add just enough deterministic coverage so the real regressions seen in recorded playthroughs are caught before they reach manual QA again.

This plan is not about heavy GUI automation. It is about testing the engine contracts that the recordings exposed.

## Problems In The Current Coverage

- Unit tests passed while real fullscreen/menu behavior was still broken.
- Overlay tests passed while normal gameplay still rendered into a smaller rectangle.
- There is not enough coverage for viewport-space correctness, modal ownership, and scene staging.

## Coverage To Add

### 1. Fullscreen/View Rect Contract Specs

Add targeted specs that assert:

- active game-area screen rect is stable after init
- active game-area screen rect changes correctly after fullscreen toggle/resize
- menu layout and gameplay transforms derive from the same rect

### 2. Menu Interaction Contract Specs

Add targeted specs that assert:

- visible menu suppresses gameplay input path
- visible menu suppresses gameplay cursor path
- menu click hit-testing uses the same screen-space rectangle as menu layout

### 3. Scene/Overlay Contract Specs

Add targeted specs that assert:

- scenes and overlays both use the active logical reference contract
- sequence text/sprites/backgrounds are not using raw screen dimensions
- normal scene rendering does not collapse into a smaller unintended sub-rectangle because of a mismatched reference contract

### 4. Scene Staging Specs

Add targeted specs that assert:

- staged scene activation does not call normal enter/script/actions unless requested
- playable activation does
- transition midpoint activation preserves the requested activation mode

### 5. Optional Debug Introspection

Expose a small amount of inspectable state for tests/debug builds:

- active modal owner
- active game-area rect
- active reference resolution
- current scene logical size
- current transformed mouse position

This avoids brittle pixel-perfect screenshot assertions for every bug.

## Validation Strategy

Use a layered approach:

1. focused unit/spec assertions on the contracts above
2. grouped fast suite run
3. one real `crystal_mystery` build
4. one manual recorded playthrough check after the major rendering/input fixes land

## Completion Criteria

- a regression in viewport/input/scene-staging contract causes a deterministic spec failure
- future playthrough debugging no longer depends entirely on visual guessing from mp4 captures
