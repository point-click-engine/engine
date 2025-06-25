# Crystal Spec Crash Investigation Report

## Executive Summary

The Point Click Engine test suite experiences a "Process terminated abnormally" crash when running `crystal spec`. This appears to be a memory management issue, likely a double-free error, that only manifests when running the full test suite.

## Symptoms

1. **Error Message**: `malloc: *** error for object 0x6000007a9700: pointer being freed was not allocated`
2. **Crash Pattern**: Always occurs after stress/resource tests complete
3. **Timing**: Happens after "Memory usage: initial=X, final=Y, growth=Z" is printed
4. **Consistency**: Reproducible with full `crystal spec` but not with subsets of tests

## What We've Discovered

### 1. The Crash is Order-Dependent
- Running individual test files: ✅ Works
- Running small combinations: ✅ Works  
- Running full suite: ❌ Crashes
- The crash happens during transition between test files, not within a single test

### 2. Crash Location Pattern
```
SimpleResourceManager initialized (many times)
...
Final state variables count: 7234
Memory usage: initial=18399232, final=7651328, growth=-10747904
....Process terminated abnormally
```

### 3. Not Related to Specific Features
- ❌ Not audio finalizers (disabled them, still crashes)
- ❌ Not Engine.instance calls (fixed those)
- ❌ Not stack size (increased it, still crashes)
- ❌ Not individual test files (all pass in isolation)

### 4. Fixes Applied (But Didn't Solve Root Cause)
1. Added safety checks to `SimpleResourceManager` cleanup
2. Added try-catch blocks around resource unloading
3. Fixed audio system finalizers
4. Fixed `DialogManager` to handle uninitialized engine
5. Added GC.collect between tests

## Current Hypothesis

The crash is likely caused by one of these scenarios:

1. **Double-Free in C Bindings**: Raylib resources are being freed twice - once by our cleanup code and once by Crystal's GC
2. **Invalid Memory Access**: We're accessing C struct fields on invalid/freed memory
3. **Finalizer Race Condition**: Multiple finalizers trying to clean up the same resources
4. **Test Runner State Corruption**: Something in the test runner's global state gets corrupted after many tests

## Detailed Investigation Plan

### Phase 1: Isolate the Trigger (Highest Priority)

1. **Binary Search the Test Suite**
   ```bash
   # Find minimum set of test files that triggers crash
   # Start with full suite, remove half, test, repeat
   ```

2. **Test Order Permutations**
   ```crystal
   # Create script to run tests in different orders
   # See if specific file transitions cause crash
   ```

3. **Memory Pattern Analysis**
   ```crystal
   # Log all resource allocations/deallocations
   # Track pointers to find double-frees
   ```

### Phase 2: Narrow Down the Component

1. **Disable All Finalizers**
   ```crystal
   # Comment out ALL finalize methods
   # If crash stops, we know it's finalizer-related
   ```

2. **Replace Raylib Calls with Stubs**
   ```crystal
   # Create mock Raylib that doesn't actually allocate
   # If crash stops, it's Raylib binding issue
   ```

3. **Track Object Lifecycle**
   ```crystal
   # Add logging to every new/finalize
   # Map object creation to destruction
   ```

### Phase 3: Create Minimal Reproduction

1. **Extract Crash Pattern**
   - Identify exact sequence of operations
   - Remove all unnecessary code
   - Create standalone reproduction

2. **Test Outside Spec Framework**
   - Run same operations in plain Crystal program
   - Determine if it's spec-specific

3. **C Binding Test**
   - Create minimal C library with alloc/free
   - Test if Crystal handles it correctly

### Phase 4: Root Cause Analysis

1. **GDB/LLDB Analysis**
   ```bash
   lldb crystal spec
   # Set breakpoint on malloc_error_break
   # Get stack trace at crash
   ```

2. **Valgrind Testing** (if available on macOS)
   ```bash
   valgrind --leak-check=full crystal spec
   ```

3. **Crystal Compiler Flags**
   ```bash
   crystal spec --debug --no-codegen
   # Try different optimization levels
   ```

## Immediate Next Steps

1. Create a test harness that can:
   - Run subsets of tests in controlled order
   - Log all resource operations with timestamps
   - Detect the exact test transition that crashes

2. Implement resource tracking:
   ```crystal
   class ResourceTracker
     @@allocations = {} of Pointer(Void) => String
     
     def self.track_alloc(ptr, source)
       @@allocations[ptr] = "#{source} at #{Time.local}"
     end
     
     def self.track_free(ptr, source)
       if !@@allocations.has_key?(ptr)
         puts "DOUBLE FREE: #{ptr} from #{source}"
       end
       @@allocations.delete(ptr)
     end
   end
   ```

3. Create bisection script to find minimal failing test set

## Questions to Answer

1. **Is this a Crystal bug or our bug?**
   - If minimal reproduction without Raylib crashes → Crystal bug
   - If only happens with Raylib calls → Our bug or binding bug

2. **Why only in full test suite?**
   - Memory pressure exposing latent bug?
   - Specific test combination?
   - Global state corruption?

3. **Is it platform-specific?**
   - Test on Linux/Docker
   - Test with different Crystal versions

## Risk Assessment

- **High Risk**: This could indicate memory corruption that might affect production
- **Medium Risk**: May only affect test suite, not runtime
- **Mitigation**: Use `run_all_safe_tests.sh` script as workaround

## Recommendations

1. **Short Term**: Use test script workarounds
2. **Medium Term**: Implement resource tracking to find root cause  
3. **Long Term**: Consider alternative resource management pattern or different testing approach

---

*Last Updated: 2025-06-25*