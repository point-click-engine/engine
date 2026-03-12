# Engine Playthrough Workstreams

This index splits the engine-side remediation from the playthrough audits into smaller tracked workstreams.

These plans are engine-focused and intentionally exclude most `crystal_mystery` content polish except where content reveals an engine contract problem.

## Workstreams

1. [ENGINE_FULLSCREEN_VIEWPORT_CONTRACT_PLAN.md](/Users/remy/dev/point_click_engine/ENGINE_FULLSCREEN_VIEWPORT_CONTRACT_PLAN.md)

- Establish one authoritative fullscreen/display/input rectangle.
- Fix the partial/cornered rendering bug across menus, scenes, overlays, dialog, and gameplay.

2. [ENGINE_CONFIGURABLE_REFERENCE_RESOLUTION_PLAN.md](/Users/remy/dev/point_click_engine/ENGINE_CONFIGURABLE_REFERENCE_RESOLUTION_PLAN.md)

- Remove the hardcoded engine-wide `1024x768` reference assumption.
- Allow each game to declare its intended logical/reference resolution cleanly.

3. [ENGINE_MENU_INPUT_COORDINATION_PLAN.md](/Users/remy/dev/point_click_engine/ENGINE_MENU_INPUT_COORDINATION_PLAN.md)

- Fix unreliable menu click activation and hover selection under fullscreen.
- Cleanly separate modal UI ownership from gameplay input/cursor behavior.

4. [ENGINE_CINEMATIC_SCENE_STAGING_PLAN.md](/Users/remy/dev/point_click_engine/ENGINE_CINEMATIC_SCENE_STAGING_PLAN.md)

- Make scene staging/playable handoff declarative and generic.
- Ensure cinematics can change scenes without leaking normal gameplay entry behavior.

5. [ENGINE_PLAYTHROUGH_REGRESSION_COVERAGE_PLAN.md](/Users/remy/dev/point_click_engine/ENGINE_PLAYTHROUGH_REGRESSION_COVERAGE_PLAN.md)

- Add the missing test/debug coverage so real playthrough regressions are caught before they ship.

## Recommended Order

1. Fullscreen viewport contract
2. Configurable reference resolution
3. Menu/input coordination
4. Cinematic scene staging
5. Regression coverage

## Why This Order

The latest capture shows that the dominant bug is no longer just sequence overlays. The main scene path, menus, and gameplay all still disagree about the active viewport and input space. Until that contract is fixed, smaller menu or intro patches are likely to be unstable or misleading.
