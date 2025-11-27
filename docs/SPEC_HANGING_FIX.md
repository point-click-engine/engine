# Spec Hanging Issue - Investigation and Fix

## Issue Description

Running `crystal spec` with all specs together causes the test suite to hang on macOS. The tests would run for a while (showing progress with dots) and then become unresponsive.

## Root Cause Analysis

### Investigation Process

1. **Explored spec structure**: Found 90+ spec files across multiple directories
2. **Identified window management patterns**: Many specs call `RL.init_window` and `RL.close_window` directly
3. **Counted window operations**: Over 100 direct `RL.init_window` calls across spec files
4. **Observed symptoms**:
   - GC finalization cycle warnings
   - Multiple "INFO: Initializing raylib 5.5" messages
   - Eventual hang after many window operations

### Root Cause

**GLFW/OpenGL context exhaustion on macOS**

When running all specs together:
1. Each spec that needs graphics calls `RL.init_window` and `RL.close_window`
2. This creates and destroys OpenGL contexts repeatedly
3. After too many init/close cycles, GLFW becomes unresponsive
4. The GLFW event loop stops responding, causing the process to hang

This is a known issue with GLFW on macOS where rapid window creation/destruction can exhaust system resources.

## Implemented Solution

### 1. Updated `spec/support/raylib_mock.cr`

Added missing methods for headless mode compatibility:
- `window_ready?` - Check if window is initialized
- `poll_input_events` - Mock event polling
- `set_target_fps`, `get_time`, `draw_fps`, etc.

### 2. Updated `spec/spec_helper.cr`

Added `TestWindowManager` module:
```crystal
module TestWindowManager
  # Tracks window operations
  # Provides shared window management
  # Includes event polling to keep GLFW responsive
end
```

Updated `Spec.after_each` to poll GLFW events:
```crystal
Spec.after_each do
  # Reset engine singleton
  # Poll GLFW events to prevent hanging
  TestWindowManager.poll_events
  RaylibContext.poll_events_if_needed
end
```

### 3. Rewrote `run_specs_safely.sh`

The script now:
- Runs specs in smaller batches by category
- Each batch runs in a separate process (proper cleanup)
- Supports `fast` mode to skip integration tests
- Provides color-coded output and summaries

## Usage

### Recommended: Run specs in batches
```bash
./run_specs_safely.sh        # Run all specs
./run_specs_safely.sh fast   # Skip integration tests
```

### Alternative: Run specific spec files
```bash
crystal spec spec/core/game_object_spec.cr  # Individual files work fine
```

### Not Recommended (may hang)
```bash
crystal spec  # Running all specs at once may hang
```

## Files Modified

| File | Changes |
|------|---------|
| `spec/support/raylib_mock.cr` | Added `window_ready?`, `poll_input_events`, and other mock methods |
| `spec/spec_helper.cr` | Added `TestWindowManager`, improved event polling |
| `run_specs_safely.sh` | Complete rewrite with batched execution |

## Future Work

To fully support `crystal spec` running all specs at once, all spec files need to be refactored to use `RaylibContext` instead of calling `RL.init_window` directly. See `docs/SHARED_WINDOW_REFACTORING_PLAN.md` for the detailed plan.

## Technical Details

### Why batching works

Each Crystal spec batch runs as a separate process. When the process ends:
1. All OpenGL contexts are properly cleaned up by the OS
2. GLFW is fully terminated
3. The next batch starts fresh

This prevents resource exhaustion that occurs when hundreds of window init/close cycles happen in a single process.

### GC Finalization Warnings

The "GC Warning: Finalization cycle involving" messages come from audio managers with finalizers. These warnings are harmless but indicate circular references during cleanup. This is a separate issue from the hanging problem.
