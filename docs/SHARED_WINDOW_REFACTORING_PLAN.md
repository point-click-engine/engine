# Shared Window Refactoring Plan

## Goal

Refactor all spec files to use a shared window through `RaylibContext` instead of calling `RL.init_window` and `RL.close_window` directly. This will allow `crystal spec` to run all specs at once without hanging.

## Current State

### Problem
- ~100+ direct calls to `RL.init_window` across spec files
- Each spec creates and destroys its own window
- Running all specs exhausts GLFW/OpenGL resources on macOS

### Affected Files (by category)

#### Core Engine Specs (highest priority)
- `spec/core/engine_integration_spec.cr` - 5 init_window calls
- `spec/core/engine_input_spec.cr` - 9 init_window calls
- `spec/core/engine_save_load_spec.cr` - 13 init_window calls
- `spec/core/engine_scene_management_spec.cr` - 11 init_window calls
- `spec/core/engine_dialog_spec.cr` - 8 init_window calls
- `spec/core/door_interaction_spec.cr` - 4 init_window calls
- `spec/core/game_config_spec.cr` - 7 init_window calls
- `spec/core/architectural_patterns_spec.cr` - 6 init_window calls
- `spec/core/renderer_registration_spec.cr` - 10 init_window calls
- `spec/core/input_keyboard_shortcuts_spec.cr` - 5 init_window calls

#### Integration Specs
- `spec/integration/render_system_integration_spec.cr` - 6 init_window calls
- `spec/integration/coordinate_system_consistency_spec.cr` - 4 init_window calls
- `spec/integration/ui_fixes_integration_spec.cr` - 6 init_window calls

#### Other Specs
- `spec/core/engine/auto_save_spec.cr` - 5 init_window calls
- `spec/core/engine/game_state_integration_spec.cr` - 4 init_window calls
- `spec/examples/minimal_game_spec.cr` - 5 init_window calls
- `spec/graphics/effects/scene_effects_spec.cr` - 1 init_window call (conditional)
- `spec/scenes/yaml_scene_loading_spec.cr` - 4 init_window calls

## Implementation Plan

### Phase 1: Enhance RaylibContext (1-2 hours)

Update `spec/spec_helper.cr` to provide a robust shared window API.

```crystal
module RaylibContext
  # Ensure a window exists with at least the requested dimensions
  def self.ensure_window(width = 800, height = 600, title = "Test")
    # Reuse existing window or create new one
    # Resize if needed (don't recreate)
  end

  # Mark that a test "wants" to close the window
  # Actually closes only at end of suite
  def self.release_window
    # Track close request but don't actually close
  end

  # Actually close (only called by Spec.after_suite)
  def self.force_cleanup
    # Really close the window
  end
end
```

**Tasks:**
1. [ ] Add `release_window` method that doesn't actually close
2. [ ] Track window "ownership" to know when it's safe to resize
3. [ ] Add `ensure_minimum_size` to handle tests needing larger windows
4. [ ] Update `Spec.after_suite` to use `force_cleanup`

### Phase 2: Create Migration Helper (30 min)

Create a helper macro/method to make migration easier:

```crystal
# In spec_helper.cr
macro with_test_window(width = 800, height = 600, title = "Test", &block)
  RaylibContext.ensure_window({{width}}, {{height}}, {{title}})
  begin
    {{block.body}}
  ensure
    RaylibContext.release_window
  end
end
```

### Phase 3: Migrate Core Engine Specs (2-3 hours)

Migrate specs in order of complexity (simplest first).

#### Pattern: Direct Replacement

**Before:**
```crystal
it "does something" do
  RL.init_window(800, 600, "Test")
  # test code
  RL.close_window
end
```

**After:**
```crystal
it "does something" do
  RaylibContext.ensure_window(800, 600, "Test")
  # test code
  # No close_window call needed
end
```

#### Pattern: With ensure block

**Before:**
```crystal
it "does something" do
  RL.init_window(800, 600, "Test")
  begin
    # test code
  ensure
    RL.close_window
  end
end
```

**After:**
```crystal
it "does something" do
  with_test_window(800, 600, "Test") do
    # test code
  end
end
```

**Migration Order:**
1. [ ] `spec/core/engine_input_spec.cr`
2. [ ] `spec/core/engine_save_load_spec.cr`
3. [ ] `spec/core/engine_scene_management_spec.cr`
4. [ ] `spec/core/engine_dialog_spec.cr`
5. [ ] `spec/core/door_interaction_spec.cr`
6. [ ] `spec/core/game_config_spec.cr`
7. [ ] `spec/core/architectural_patterns_spec.cr`
8. [ ] `spec/core/renderer_registration_spec.cr`
9. [ ] `spec/core/input_keyboard_shortcuts_spec.cr`
10. [ ] `spec/core/engine_integration_spec.cr`

### Phase 4: Migrate Engine Submodule Specs (1 hour)

1. [ ] `spec/core/engine/auto_save_spec.cr`
2. [ ] `spec/core/engine/game_state_integration_spec.cr`

### Phase 5: Migrate Integration Specs (1-2 hours)

1. [ ] `spec/integration/render_system_integration_spec.cr`
2. [ ] `spec/integration/coordinate_system_consistency_spec.cr`
3. [ ] `spec/integration/ui_fixes_integration_spec.cr`

### Phase 6: Migrate Remaining Specs (1 hour)

1. [ ] `spec/examples/minimal_game_spec.cr`
2. [ ] `spec/graphics/effects/scene_effects_spec.cr`
3. [ ] `spec/scenes/yaml_scene_loading_spec.cr`

### Phase 7: Testing and Validation (1 hour)

1. [ ] Run `crystal spec` and verify no hanging
2. [ ] Run `./run_specs_safely.sh` and compare results
3. [ ] Check for any tests that fail due to window state assumptions
4. [ ] Update documentation

## Technical Considerations

### Window Size Changes

Some tests use different window sizes. The shared window approach handles this by:
1. Tracking the maximum required dimensions
2. Resizing the window when a larger size is needed
3. Never shrinking (to avoid potential issues)

### Test Isolation

Tests that modify window state (title, size, etc.) need care:
- Window size changes are allowed (resize instead of recreate)
- Title changes may need to be mocked or ignored
- Fullscreen tests may need special handling

### Spec Ordering

With a shared window, spec execution order could matter if:
- A spec leaves the window in a bad state
- A spec depends on a fresh window

**Mitigation:** Reset window state in `Spec.after_each` or `Spec.before_each`

### Engine Singleton

The Engine class is a singleton that gets reset after each test. Ensure:
- Engine reset doesn't close the shared window
- Engine initialization uses `RaylibContext` instead of `RL.init_window`

## Rollback Plan

If issues arise:
1. Keep `run_specs_safely.sh` as the primary test runner
2. Mark problematic specs to run in isolation
3. Use `Spec.before_all` / `Spec.after_all` for specs needing fresh windows

## Success Criteria

1. `crystal spec` completes without hanging
2. All existing tests pass
3. No significant increase in test runtime
4. `run_specs_safely.sh` still works as a fallback

## Estimated Total Time

- Phase 1: 1-2 hours
- Phase 2: 30 minutes
- Phase 3: 2-3 hours
- Phase 4: 1 hour
- Phase 5: 1-2 hours
- Phase 6: 1 hour
- Phase 7: 1 hour

**Total: 7-10 hours**

## Notes

- Test after each phase to catch issues early
- Some specs may reveal hidden dependencies on window state
- Consider adding a CI check that runs `crystal spec` to prevent regression
