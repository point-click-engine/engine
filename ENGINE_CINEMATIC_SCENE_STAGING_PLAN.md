# Engine Cinematic Scene Staging Plan

## Goal

Provide a generic declarative way for sequences to stage scenes, transition into playable scenes, and avoid leaking normal scene-enter side effects during cinematics.

This workstream should stay generic. It must not hardcode intro-specific behavior into the engine.

## Problems Confirmed By The Audits

- Cinematics need scenes that survive scene changes and can be staged without immediately acting like normal gameplay scenes.
- The current intro/lab handoff is better than before, but the overall scene/cinematic ownership model is still implicit.
- Sequence ownership, UI visibility, player control, and final playable activation are still coordinated through loosely related actions.

## Relevant Code

- `src/actions/action_executor.cr`
- `src/core/scene_manager.cr`
- `src/core/engine.cr`
- `src/scenes/scene.cr`

## Plan

### Phase 1. Lock Down The ActivationOptions Contract

Formalize what scene activation options mean:

- `call_enter`
- `load_script`
- `load_actions`
- `publish_events`
- `force_reload`

Document exactly which scene behaviors each option suppresses or permits.

Acceptance:

- the behavior of staged vs playable activation is explicit and testable

### Phase 2. Model Cinematic Staging Explicitly

Define a reusable staging model:

- sequence can load a scene in staging mode
- sequence retains control
- scene assets are available visually
- normal gameplay scripts/enter hooks do not run unless requested

Acceptance:

- a scene can be used as a cinematic backdrop without unwanted gameplay text or script behavior

### Phase 3. Model Playable Handoff Explicitly

Define the final handoff from staging to gameplay:

- optional reload or reactivation
- player visibility/control enabled at the correct point
- UI state restored at the correct point
- any desired playable scene hooks run only at the real handoff

Acceptance:

- a cinematic can end in a real playable scene without ad hoc special cases

### Phase 4. Add Optional Diagnostics

For debugging recorded playthroughs, add optional logs for:

- scene activation mode
- sequence start/end
- final handoff moment
- player-control enable/disable transitions

Keep off by default.

Acceptance:

- a future capture can be correlated with the runtime state without guesswork

## Completion Criteria

- scene staging is generic and declarative
- no intro-specific engine branches are needed
- cinematics can transition into gameplay cleanly and predictably
