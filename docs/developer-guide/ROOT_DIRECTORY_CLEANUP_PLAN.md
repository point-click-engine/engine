# Root Directory Cleanup Plan

## Goal

Reduce root-level noise without breaking documented workflows, engine defaults, or spec paths.

This plan is intentionally conservative. It separates:

- items that are safe to clean up now
- items that are safe to move after small path updates
- items that should stay at the repo root for now

## Current Findings

The repository root currently mixes five different concerns:

1. public project entrypoints and metadata
2. active engine/game sources
3. historical planning documents
4. ad hoc debug probes and test fixtures
5. generated binaries and logs

The highest-value cleanup is not one big move. It is a staged reduction of the root into a small set of expected top-level items.

## Keep At Root

These are normal root-level files or directories and should stay where they are:

- `README.md`
- `LICENSE`
- `CHANGELOG.md`
- `shard.yml`
- `.gitignore`
- `.editorconfig`
- `CLAUDE.md`
- `src/`
- `spec/`
- `docs/`
- `crystal_mystery/`
- `example/`
- `examples/`
- `templates/`
- `lib/`
- `run.sh`
- `build.sh`
- `run_specs_safely.sh`

Notes:

- `run.sh` is referenced directly in [README.md](/Users/remy/dev/point_click_engine/README.md).
- `build.sh` is a simple root wrapper and is still reasonable at the top level.
- `example/` and `examples/` appear to serve different purposes:
  - `example/` is a fuller sample project with assets
  - `examples/` contains focused demos

## Safe Cleanup Now

These items can be cleaned up with low engine risk.

### 1. Remove Generated Root Binaries From Version Control

Files:

- `point_click_engine`
- `spec_runner`

Also standardize all local build outputs currently appearing in root:

- `main`
- `modular_example`
- `crystal_mystery_game`
- `crystal_mystery_test`
- `crystal_mystery_debug`
- `crystal_mystery_fixed`
- all matching `*.dwarf`

Recommended destination/policy:

- Use `bin/` for deliberate local builds
- Use `tmp/` for throwaway verification builds
- Do not keep compiled executables in git

Why this is safe:

- These are Mach-O binaries, not source assets
- root already contains a `bin/` directory
- `.gitignore` already ignores many generated binaries, but tracked files bypass that protection

Follow-up:

- extend ignore rules so `point_click_engine`, `spec_runner`, and similar local outputs do not reappear

### 2. Remove Or Archive Root Logs

Files:

- `output.log`
- `investigation_output.log`
- `test_results.log`

Recommended destination:

- `tmp/logs/` for ephemeral output
- `docs/archive/investigations/` only if a log is worth preserving as evidence

Why this is safe:

- they are not runtime dependencies
- they are not referenced by engine code

### 3. Remove Stale Root Makefile Or Archive It

File:

- `Makefile`

Reason:

- it references missing files:
  - `simple_movement_test.cr`
  - `test_player_movement.cr`
  - `debug_clicks.cr`
  - `comprehensive_movement_test.cr`
  - `analyze_movement_issues.cr`
  - `test_comprehensive.sh`

Recommended action:

- either delete it
- or archive it under `docs/archive/refactoring/` with a note that it is historical only

This is safer than keeping a misleading root command surface.

### 4. Remove Local Workspace Trash

Items:

- `.DS_Store`

Recommended action:

- delete it

## Safe To Move After Small Path Updates

These are good cleanup candidates, but moving them safely requires updating spec paths, docs, or helper scripts first.

### 1. Historical Planning And Refactor Notes

Files:

- `ARCHITECTURAL_ISSUES.md`
- `DOCUMENTATION_STATUS.md`
- `IMPLEMENTATION_CHECKLIST.md`
- `IMPROVEMENT_PLAN.md`
- `PATHFINDING_FIXES.md`
- `REFACTORING_TODO.md`
- `TODO_IMPLEMENTATION.md`
- `camera_refactor_plan.md`

Recommended destination structure:

- `docs/developer-guide/plans/` for active plans
- `docs/archive/refactoring/` for completed or historical plans
- keep only one root backlog file if desired, preferably `TODO.md`

Why this is worth doing:

- the root currently has too many planning documents competing for attention
- most of these are internal engineering notes, not top-level project entrypoints

Suggested rule:

- root gets at most one summary backlog file
- everything else becomes developer documentation or archive material

### 2. Debug And Probe Programs

Files:

- `debug_audio.cr`
- `debug_format.cr`
- `debug_simple.cr`
- `debug_spec_run.cr`
- `debug_test.cr`
- `test_first_click_issue.cr`
- `test_grid_conversion.cr`
- `test_movement_debug.cr`
- `test_movement_issue.cr`
- `test_pathfinding_issue.cr`
- `test_pathfinding_same_cell.cr`
- `test_validation_order.cr`
- `test_walkable_check.cr`
- `test_pathfinding.sh`

Recommended destination:

- `tools/debug/` for Crystal probes
- `tools/debug/` or `tools/manual/` for shell helpers

Why not root:

- these are engineering probes, not product entrypoints
- several are issue-specific and read like one-off investigations

Extra cleanup:

- evaluate each file before moving
- delete probes that are fully superseded by specs

### 3. Root Test Fixtures And Temporary Configs

Files and directories:

- `autosave_config.yaml`
- `fps_config.yaml`
- `no_fps_config.yaml`
- `scene_load_config.yaml`
- `state_change_config.yaml`
- `manager_config.yaml`
- `simple_test.yaml`
- `test_simple_config.yaml`
- `invalid.yaml`
- `test_sprite.png`
- `audio_test/`
- `test_scenes/`
- `test_quests/`
- `test_sprites/`

Recommended destination:

- `spec/fixtures/engine/`
- `spec/fixtures/preflight/`
- `spec/fixtures/assets/`

Why this needs a small migration first:

- specs still use literal repo-root paths in several places, for example:
  - `spec/core/preflight/spec_helper.cr`
  - `spec/core/engine/auto_save_spec.cr`
  - `spec/core/engine/fps_display_spec.cr`
  - `spec/characters/sprite_controller_spec.cr`

Safe migration shape:

1. create fixture directories under `spec/fixtures/`
2. update specs to build paths from the spec file location or temp directories
3. move the tracked fixture files
4. verify with `./run_specs_safely.sh`

### 4. Audio Test Fixture

Item:

- `audio_test/game.yaml`

Recommended destination:

- `spec/fixtures/preflight/audio_test/game.yaml`

Reason:

- it is used by `debug_audio.cr`
- it behaves like a test/debug fixture, not like a top-level project artifact

### 5. Redundant Root Runner

File:

- `run_crystal_mystery.sh`

Recommended action:

- remove after confirming `./run.sh crystal_mystery/main.cr` remains the documented path
- alternatively move it under `tools/`

Why:

- it duplicates an already-documented root workflow

## Do Not Move Yet

These items still have default-path behavior or user-facing expectations that make relocation riskier.

### 1. Runtime Default Data Files

Files:

- `achievements.yaml`
- `user_settings.yaml`

Why not yet:

- defaults are baked into runtime classes:
  - [achievement_manager.cr](/Users/remy/dev/point_click_engine/src/core/achievement_manager.cr)
  - [user_settings.cr](/Users/remy/dev/point_click_engine/src/core/user_settings.cr)

Safe future cleanup requires:

- configurable default storage paths
- specs updated to use temp directories consistently

### 2. Runtime Output Directories

Directories:

- `saves/`
- `screenshots/`

Why not yet:

- the engine defaults to these names:
  - [save_system.cr](/Users/remy/dev/point_click_engine/src/core/save_system.cr)
  - [screenshot.cr](/Users/remy/dev/point_click_engine/src/graphics/utils/screenshot.cr)

Recommended future direction:

- keep default names for compatibility
- ensure they are gitignored
- avoid checking in contents

### 3. Root Wrapper Scripts Used By Docs

Files:

- `run.sh`
- `build.sh`
- `run_specs_safely.sh`

Why not yet:

- `README.md` currently teaches root-level usage for these commands

## Suggested Target Structure

If cleanup work proceeds, this structure would reduce root clutter safely:

```text
docs/
  developer-guide/
    plans/
  archive/
    investigations/
    refactoring/

tools/
  debug/
  manual/

spec/
  fixtures/
    assets/
    engine/
    preflight/

bin/
  # local deliberate build outputs

tmp/
  logs/
  build-checks/
```

## Recommended Execution Order

1. Remove tracked generated binaries from git and tighten ignore rules.
2. Delete `.DS_Store` and stop keeping root logs.
3. Archive or delete the stale `Makefile`.
4. Move planning/refactor documents under `docs/`, leaving at most one root backlog file.
5. Create `tools/debug/` and move ad hoc Crystal probes there.
6. Migrate root test fixtures into `spec/fixtures/` and update spec paths.
7. Revisit runtime-default files only after adding configurable storage locations.

## Acceptance Criteria

The root is in an acceptable state when:

- the root contains only project entrypoints, core metadata, and major top-level directories
- no compiled binaries are tracked in git
- no logs live at root
- no issue-specific debug probes live at root
- most internal plans live under `docs/`
- spec fixtures no longer depend on repo-root filenames
- `README.md` still matches the actual top-level command surface

