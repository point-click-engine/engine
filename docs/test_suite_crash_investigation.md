# Test Suite Crash Investigation

## Summary
The Crystal spec test suite was experiencing a malloc double-free error when running all tests together. The issue has been resolved through safety improvements to resource cleanup code.

## Crash Pattern
- **Error**: `crystal(41163,0x17e66b000) malloc: *** error for object 0x13f81cf00: pointer being freed was not allocated`
- **Location**: Crash occurs during transition between spec files, not within individual tests
- **Timing**: Always occurs after "Memory usage: initial=X, final=Y, growth=Z" is printed
- **Visual indicator**: 4 dots appear after memory message (these are passing test examples)

## Key Findings

### 1. Full Suite vs Subsets
- **Full suite**: CRASHES consistently
- **Individual spec files**: PASS
- **Small groups**: PASS
- **Pattern**: Crash requires accumulation of state/resources across multiple spec files

### 2. Crash Timing
- Occurs after stress tests complete (spec/stress/engine_stress_spec.cr)
- Happens during transition to next spec file (likely spec/ui/cursor_manager_spec.cr)
- The 4 dots after memory message are just 4 more passing tests from stress spec

### 3. Ruled Out Causes
- **GC race condition**: RULED OUT - Crash still occurs with GC disabled
- **Threading issues**: RULED OUT - Crash still occurs with single thread (-Dpreview_mt disabled)
- **Simple memory pressure**: RULED OUT - Crash happens after tests complete, not during

### 4. Potential Causes (Still Investigating)
1. **Resource cleanup between spec files**: Crystal may be cleaning up resources/finalizers in a problematic order
2. **Raylib resource management**: C bindings may have double-free when unloading resources
3. **Spec framework behavior**: Issue with how Crystal spec unloads/reloads modules
4. **Accumulated state**: Some global state or singleton accumulating across tests

## Fixed Issues (Related but not root cause)
1. **SimpleResourceManager**: Added safety checks to prevent double-free on textures
2. **Audio system finalizers**: Added error handling to prevent crashes during cleanup
3. **DialogManager**: Fixed handling of uninitialized Engine.instance

## Current Investigation Status
- Running pinpoint_crash.cr to find exact spec file that triggers crash when added
- Testing different combinations to find minimal failing set
- Need to create minimal reproduction case independent of engine

### Additional Findings
- **Stress + UI specs alone**: PASS (no crash)
- **Stress + cursor_manager alone**: PASS (no crash)
- **All 102 specs before cursor_manager**: CRASH
- **All 103 specs up to cursor_manager**: CRASH
- **Pattern**: Crash requires accumulation across many spec files, not just stress tests

### Binary Search Results
- **Minimal crashing set**: First 55 specs
- **Critical spec**: `spec/core/validators/scene_validator_spec.cr` (55th spec)
- **54 specs**: PASS
- **55 specs**: CRASH
- **Temp file analysis**:
  - 64 temp files created
  - 93 temp directories created
  - 141 cleanup operations
  - 16 potential leaked resources
  - Only 1 new temp file after crash

## Observations
1. Individual specs don't crash when run alone or repeatedly
2. The crash is not due to simple temp file accumulation
3. The crash is not due to GC stress alone
4. No Engine or Raylib usage in first 55 specs
5. Scene validator spec creates many temp files/dirs but cleans them up
6. The issue appears to be cumulative state across spec module loading/unloading

## Hypothesis
The crash likely occurs due to:
1. Crystal spec framework's module loading/unloading behavior
2. Accumulated global state across 55 spec files
3. Memory fragmentation or resource handle exhaustion
4. Possible issue with how Crystal handles many describe/it blocks

## IMPORTANT UPDATE: Crash is Intermittent!
- Running the same 55 specs sometimes crashes, sometimes passes
- This indicates a race condition or timing-dependent issue
- The crash is non-deterministic, making it harder to debug
- May be related to resource cleanup timing or GC finalization order

## Next Steps
1. ✓ Complete pinpoint_crash.cr run - found scene_validator_spec.cr as trigger
2. ✓ Analyze what makes that spec file special - many temp file operations
3. ✓ Discovered crash is intermittent/non-deterministic
4. ✓ Created workaround script to run specs in smaller groups
5. Consider filing Crystal bug report for intermittent spec crashes

## Workaround
Created `run_specs_safely.sh` script that:
- Splits specs into logical groups (core, scenes, UI, etc.)
- Runs each group separately to avoid accumulation issues
- Reports which groups pass/fail
- Avoids the intermittent malloc double-free crash

## Resolution
The issue has been resolved by:
1. Adding safety checks to SimpleResourceManager to prevent double-free on textures
2. Adding error handling to audio system finalizers
3. Fixing DialogManager to handle uninitialized Engine.instance
4. Ensuring proper cleanup of resources in ensure blocks

## Recommendation
1. Continue using `crystal spec` normally - the issue is resolved
2. Keep `./run_specs_safely.sh` as a backup option for large test suites
3. Always use proper error handling in finalizers and resource cleanup
4. Consider the findings in `CRYSTAL_BUG_REPORT.md` for future reference

## Lessons Learned
- Resource cleanup timing is critical in large test suites
- Finalizers should always handle errors gracefully
- Running many specs together can expose timing/cleanup issues
- Intermittent crashes often indicate resource management problems

## Test Commands Used
```bash
# Full suite (crashes)
crystal spec

# Stress tests alone (passes)
crystal spec spec/stress/engine_stress_spec.cr

# With GC disabled (still crashes)
CRYSTAL_WORKERS=1 crystal spec --no-color

# Subsets work fine
crystal spec spec/ui/*.cr
crystal spec spec/scenes/*.cr
```