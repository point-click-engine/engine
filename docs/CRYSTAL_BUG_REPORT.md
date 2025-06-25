# Crystal Spec Malloc Double-Free Bug Report

## Summary
We encountered an intermittent malloc double-free error when running 55+ spec files together with Crystal 1.16.3.

## Original Error
```
crystal(41163,0x17e66b000) malloc: *** error for object 0x13f81cf00: pointer being freed was not allocated
crystal(41163,0x17e66b000) malloc: *** set a breakpoint in malloc_error_break to debug
```

## Reproduction Pattern
The crash occurred when:
1. Running 55+ spec files together (`crystal spec`)
2. Each spec file performed file/directory operations
3. `Spec.after_each { GC.collect }` was used
4. The crash happened during spec file transitions, not within tests

## Investigation Findings

### Binary Search Result
- 54 specs: PASS
- 55 specs: CRASH (intermittent)
- Critical spec: `spec/core/validators/scene_validator_spec.cr`

### Pattern Analysis
- Heavy use of `File.tempname` and `FileUtils.rm_rf`
- Multiple describe blocks across many files
- GC.collect after each test
- No direct Engine or Raylib usage in crashing specs

### Crash Characteristics
- Intermittent (sometimes passed, sometimes crashed)
- Always after "Memory usage: initial=X, final=Y, growth=Z"
- During transition between spec files
- Not reproducible with individual specs or small groups

## Attempted Fixes
1. Added safety checks to resource cleanup code
2. Fixed finalizer methods to handle errors gracefully
3. Ensured proper cleanup of temporary files

## Current Status
The crash is no longer reproducible after our fixes, suggesting it may have been related to:
- Resource cleanup timing issues
- Finalizer ordering problems
- Accumulated state across many spec modules

## Minimal Reproduction Attempt
We created a minimal reproduction with 60 spec files performing similar operations, but it does not crash consistently. The original crash may have required specific conditions that are no longer present.

## Environment
- Crystal 1.16.3 (2025-05-12)
- macOS (Darwin 24.5.0)
- Also reported on Linux systems

## Recommendation for Crystal Team
Consider investigating:
1. How spec framework handles cleanup between many spec files
2. GC behavior with frequent `GC.collect` calls across modules
3. Potential race conditions in finalizer execution order
4. Memory management when many temporary files are created/deleted

## Workaround
Created `run_specs_safely.sh` that runs specs in smaller groups to avoid accumulation issues.