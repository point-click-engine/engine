# Full Spec Suite Remediation Plan

## Purpose

Bring the full spec suite back to a trustworthy green state without introducing broad engine regressions.

This plan assumes two facts:

1. The suite currently mixes real engine regressions, spec-environment drift, and test hygiene problems.
2. "Making specs pass" is not the goal by itself. The goal is to restore a reliable signal from the suite while preserving engine behavior.

## Current Situation

### Baseline mismatch

The repository contains an older `test_results.log` showing:

- `1302 examples, 5 failures, 0 errors, 3 pending`

During the current March 11, 2026 session, a direct full-suite run produced a much larger failure surface:

- `2447 examples, 71 failures, 14 errors, 42 pending`

That means the checked-in log is stale relative to the current codebase. The first step is to rebuild the failure inventory before fixing anything.

### Known recurring failure pattern

The most common failure family observed in the current session is:

- `No player configuration found`

This appears across many preflight, validator, engine, autosave, FPS, and integration specs. That strongly suggests either:

- a validation contract changed globally, or
- many tests are relying on outdated "minimal config" fixtures.

### Other concrete failure clusters already observed

- Preflight / validator specs under `spec/core/preflight/` and `spec/core/validators/`
- Engine integration specs such as:
  - `spec/core/engine/auto_save_spec.cr`
  - `spec/core/engine/fps_display_spec.cr`
  - `spec/core/engine/game_state_integration_spec.cr`
- Scene/config-driven specs such as:
  - `spec/scenes/yaml_scene_loading_spec.cr`
  - `spec/core/validation_integration_spec.cr`
- Smaller focused failures in the older tracked log:
  - `spec/characters/movement_controller_spec.cr`
  - `spec/core/door_interaction_spec.cr`
  - `spec/core/validators/scene_validator_spec.cr`
  - `spec/scenes/transition_spec.cr`

## Safety Rules

These rules should govern all work on the suite:

1. Fix test isolation before changing engine behavior when a failure can be explained by dirty shared state, tracked fixture mutation, or stale helper assumptions.
2. Do not broaden engine validation rules and then patch dozens of specs around the new behavior unless the new behavior is explicitly desired and documented.
3. For any engine behavior change, add or tighten the smallest focused spec that proves the intended runtime contract.
4. Prefer temp directories and explicit test-only save files over repository-root fixtures.
5. Run narrow slices first, then category batches, then the full suite.

## Execution Strategy

### Phase 0: Rebuild a trustworthy failure inventory

Goal: replace stale intuition with an up-to-date failure map.

Actions:

- Run `./run_specs_safely.sh fast` and capture per-group results.
- Run `./run_specs_tracked.sh` or an equivalent grouped tracker to identify the exact failing files.
- Save a fresh artifact under `tmp/spec_audit/` with:
  - command used
  - date
  - failing files
  - failing examples
  - repeated error signatures

Deliverable:

- `tmp/spec_audit/YYYY-MM-DD-full-suite-baseline.md`

Exit criteria:

- Every failure is assigned to a concrete file and grouped by root-cause family.

### Phase 1: Stabilize the test harness and fixture hygiene

Goal: eliminate false failures caused by specs touching tracked files or leaking shared state.

Actions:

- Audit specs that write to repository-root files such as:
  - `achievements.yaml`
  - `manager_config.yaml`
  - `state_change_config.yaml`
  - `scene_load_config.yaml`
  - `test_scenes/`
- Move those specs to temp directories or test-only files under `tmp/`.
- Audit `Spec.before_each` / `Spec.after_each` behavior in `spec/spec_helper.cr`.
- Verify that engine singletons, event buses, Raylib window state, audio state, and save files are reset consistently.
- Continue using the shared-window discipline documented in:
  - `docs/SPEC_HANGING_FIX.md`
  - `docs/SHARED_WINDOW_REFACTORING_PLAN.md`

Deliverable:

- No spec run should create, delete, or modify tracked repository files.

Exit criteria:

- `git status --short` remains unchanged after running any single failing spec file.

### Phase 2: Reconcile the preflight and config contract

Goal: decide what a "minimal valid config" means now, then make helpers and tests consistent with that contract.

Main hypothesis:

- The current preflight/config pipeline now requires player data more aggressively than many legacy tests expect.

Actions:

- Inspect `src/core/game_config.cr`, `src/core/preflight_check.cr`, and validator classes for recent contract changes.
- Decide which of these is correct:
  - `GameConfig.from_file` should require player config by default
  - `GameConfig.from_file` should allow engine construction without player config in some modes
  - tests that only exercise config parsing or non-player systems should default to `skip_preflight: true`
- Standardize helper builders in:
  - `spec/core/preflight/spec_helper.cr`
  - any duplicated minimal-config helpers in engine/config specs
- Introduce one canonical set of fixtures:
  - `minimal_parseable_config`
  - `minimal_runtime_config`
  - `minimal_preflight_valid_config`

Deliverable:

- One documented config contract plus shared test builders that encode it.

Exit criteria:

- The repeated `No player configuration found` failures collapse to zero or to a small, intentional set.

### Phase 3: Clear validator and scene-loading regressions

Goal: fix the broad config/scene validation surface before touching gameplay systems.

Actions:

- Triage `spec/core/preflight/*.cr`
- Triage `spec/core/validators/*.cr`
- Triage scene/config integration specs:
  - `spec/scenes/yaml_scene_loading_spec.cr`
  - `spec/core/validation_integration_spec.cr`
  - `spec/core/validation_summary_spec.cr`
- For each failure, classify it as:
  - fixture issue
  - validator bug
  - changed intended behavior that needs doc updates

Likely hotspots:

- required scene fields
- player validation coupling
- asset path resolution
- start scene existence checks
- hotspot validation rules

Deliverable:

- Green validator/preflight category runs.

Exit criteria:

- `spec/core/preflight/*.cr`, `spec/core/validators/*.cr`, and scene validation specs pass in isolation and as a batch.

### Phase 4: Fix focused engine/runtime regressions

Goal: address behavior bugs that are not primarily fixture-related.

Initial candidates from observed failures:

- movement animation state transitions
  - `spec/characters/movement_controller_spec.cr`
- transition parsing defaults
  - `spec/core/door_interaction_spec.cr`
  - `spec/scenes/transition_spec.cr`
- scene validator hotspot semantics
  - `spec/core/validators/scene_validator_spec.cr`

Actions:

- Reproduce each failure with the individual spec file only.
- Read the production code before patching expectations.
- Prefer fixing the engine if the spec reflects user-visible behavior.
- Prefer fixing the spec if the behavior changed intentionally and is already enforced elsewhere.

Deliverable:

- Green targeted runtime slices with no collateral failures in adjacent specs.

Exit criteria:

- These focused failing files pass individually and within their category batch.

### Phase 5: Re-enable broader engine and integration confidence

Goal: verify that the earlier fixes did not break higher-level engine behavior.

Actions:

- Run category batches in this order:
  1. `spec/core/engine/*.cr`
  2. `spec/scenes/*.cr`
  3. `spec/characters/*.cr`
  4. `spec/scripting/*.cr`
  5. `spec/integration/*.cr`
- After each batch, record any newly exposed failures instead of immediately broadening the fix.
- Keep a short changelog of:
  - failing spec
  - root cause
  - fix type: harness / fixture / engine / spec expectation

Deliverable:

- Updated failure ledger with remaining blockers only.

Exit criteria:

- Remaining failures, if any, are small in number and clearly understood.

### Phase 6: Pending specs and suite policy

Goal: separate intentionally pending work from accidental neglect.

Actions:

- Review all pending examples.
- For each pending spec, decide:
  - implement now
  - keep pending with a clear reason
  - delete if obsolete
- Document pending items that represent roadmap work rather than regressions.

Deliverable:

- Reduced pending count or a justified pending list.

Exit criteria:

- Every pending example has a current, explicit reason.

### Phase 7: Lock in the recovery

Goal: make future suite drift harder.

Actions:

- Add a lightweight spec-maintenance checklist to the testing docs.
- Ensure local runners produce artifacts under `tmp/` instead of repo root.
- Consider a CI job that runs:
  - fast grouped specs on every push
  - full grouped suite on main or nightly
- Fail CI if tracked files change during spec execution.

Deliverable:

- Sustainable suite maintenance, not just a one-time cleanup.

## Recommended Work Order

1. Refresh the baseline.
2. Finish test hygiene and fixture isolation.
3. Resolve the preflight/player-config contract.
4. Clear validator and scene-loading failures.
5. Fix focused runtime regressions.
6. Re-run engine and integration batches.
7. Triage pending specs.
8. Add guardrails so the suite stays trustworthy.

## Definition of Done

The suite recovery is complete when all of the following are true:

- `./run_specs_safely.sh` passes.
- A direct full-suite run is either green or fails only in explicitly documented, intentionally pending areas.
- Running specs does not modify tracked files.
- The config/preflight contract is documented and reflected in shared test helpers.
- Engine behavior fixes are covered by focused specs, not only by broad integration fallout.

## Notes for Implementation

- Start with the largest repeated signature, not with the smallest failing file.
- Avoid mass-editing expectations before understanding whether the runtime or the tests drifted.
- Preserve narrow commits by failure family:
  - harness hygiene
  - preflight contract
  - validators
  - movement/transition/runtime bugs
  - integration cleanup

That commit structure will make it much easier to review and to revert safely if a "fix" destabilizes the engine.
