# Player Movement System Debug Guide

This document provides comprehensive debugging tools and tests for the Point & Click Engine's player movement system.

## Quick Start

```bash
# Run all tests
make test-movement

# Or run individual tests
make test-simple    # Basic movement without walkable areas
make test-debug     # Comprehensive debug with walkable areas
make test-clicks    # Minimal click handling test

# Analyze the system
make analyze
```

## Debug Tests Overview

### 1. Simple Movement Test (`simple_movement_test.cr`)
- **Purpose**: Test basic player movement without any constraints
- **Features**: 
  - No walkable areas (all positions should be walkable)
  - Basic player setup with animations
  - Debug output for mouse clicks and movement commands
  - Press SPACE for debug info

### 2. Comprehensive Debug Test (`test_player_movement.cr`)
- **Purpose**: Full-featured debugging with walkable areas
- **Features**:
  - Custom debug player class with extensive logging
  - Walkable area setup with obstacles
  - Debug scene with walkable area logging
  - Custom input handler with detailed debug output
  - Visual debug rendering in debug mode

### 3. Click Debug Test (`debug_clicks.cr`)
- **Purpose**: Minimal test to isolate click handling issues
- **Features**:
  - Engine-level click debugging
  - Minimal setup to reduce complexity
  - Focus on input processing pipeline

### 4. System Analysis (`analyze_movement_issues.cr`)
- **Purpose**: Static analysis of the movement system components
- **Features**:
  - Tests class instantiation
  - Verifies method existence
  - Checks default values
  - Tests walkable area functionality

## Debug Output Explanation

### Mouse Click Debug Messages

```
🖱️  DEBUG: Mouse clicked at (x, y)           # Raw click position
🧭 DEBUG: Player current position: (x, y)     # Current player location
🚶 DEBUG: Movement enabled: true/false        # Movement state
🚶 DEBUG: Is position walkable? true/false    # Walkable area check
✅ DEBUG: Starting movement to (x, y)         # Movement initiated
🎯 DEBUG: walk_to() called successfully       # Method execution
```

### Movement Debug Messages

```
🔄 DEBUG: Walking... Distance to target: X    # Movement progress
🛑 DEBUG: stop_walking() called               # Movement completion
🎯 DEBUG: Character state set to: Walking     # State changes
```

### Input Handler Debug Messages

```
🖱️  DEBUG: InputHandler.handle_click() called # Input processing
🔧 DEBUG: handle_clicks enabled: true/false   # Click handling state
🏠 DEBUG: Scene present: Yes/No               # Scene availability
🎮 DEBUG: Player present: Yes/No              # Player availability
```

## Common Issues and Solutions

### Issue 1: Player doesn't move when clicking

**Debug Steps:**
1. Run `make test-clicks` - Check if clicks are being detected
2. Verify debug output shows:
   - ✅ Mouse clicks detected
   - ✅ handle_clicks enabled: true
   - ✅ Scene and player present
3. If clicks detected but no movement, check walkable areas

**Potential Causes:**
- `engine.handle_clicks = false` - Input handling disabled
- Player `movement_enabled = false` - Player movement disabled
- Walkable area configured incorrectly
- Input handler not processing clicks

### Issue 2: Clicks detected but walkable check fails

**Debug Steps:**
1. Run `make test-simple` - Test without walkable areas
2. If simple test works, issue is in walkable area configuration
3. Check debug output for `🚶 DEBUG: Is position walkable? false`

**Potential Causes:**
- Walkable area regions not set up correctly
- Point-in-polygon algorithm failing
- Walkable area bounds incorrect

### Issue 3: Movement starts but player doesn't actually move

**Debug Steps:**
1. Check for `🔄 DEBUG: Walking... Distance to target: X` messages
2. Verify character state changes to `Walking`
3. Check if `update()` is being called regularly

**Potential Causes:**
- Game loop not updating character movement
- Animation system interfering
- Scene update not being called

## Testing Walkable Areas

The debug tests include walkable area setups:

```crystal
# Large walkable rectangle (most of screen)
walkable_region = PolygonRegion.new("walkable_main", true)
walkable_region.vertices = [
  Vector2.new(x: 50, y: 150),   # top-left
  Vector2.new(x: 750, y: 150),  # top-right
  Vector2.new(x: 750, y: 550),  # bottom-right
  Vector2.new(x: 50, y: 550)    # bottom-left
]

# Small obstacle in the middle
obstacle_region = PolygonRegion.new("obstacle", false)
obstacle_region.vertices = [
  Vector2.new(x: 350, y: 250),  # top-left
  Vector2.new(x: 450, y: 250),  # top-right
  Vector2.new(x: 450, y: 350),  # bottom-right
  Vector2.new(x: 350, y: 350)   # bottom-left
]
```

## Keyboard Shortcuts

- **F1**: Toggle debug mode (shows walkable areas, paths, etc.)
- **SPACE**: Show current debug info (in simple test)
- **Tab**: Toggle hotspot highlighting
- **ESC**: Show pause menu
- **F5**: Toggle camera edge scrolling

## Integration with Existing Games

To add debugging to your existing game:

1. **Enable debug mode**:
   ```crystal
   PointClickEngine::Core::Engine.debug_mode = true
   ```

2. **Add debug player class**:
   ```crystal
   class DebugPlayer < PointClickEngine::Characters::Player
     def handle_click(mouse_pos : RL::Vector2, scene : PointClickEngine::Scenes::Scene)
       puts "🖱️  Click at (#{mouse_pos.x}, #{mouse_pos.y})"
       super  # Call original implementation
     end
   end
   ```

3. **Replace input handler** (temporarily):
   ```crystal
   debug_input_handler = DebugInputHandler.new  # From test files
   engine.input_handler = debug_input_handler
   ```

## Files Created

- `test_player_movement.cr` - Comprehensive debug test
- `simple_movement_test.cr` - Basic movement test
- `debug_clicks.cr` - Click handling test
- `analyze_movement_issues.cr` - System analysis
- `Makefile` - Build and run commands
- `MOVEMENT_DEBUG_README.md` - This documentation

## Next Steps

1. Run the tests to identify where the movement system is failing
2. Use the debug output to trace the issue through the call stack
3. Check the specific component that's not working as expected
4. Fix the issue and verify with the tests

The tests provide comprehensive logging at every level of the movement system, from mouse input to player movement execution.