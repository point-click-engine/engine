# Point & Click Engine Debugging Guide

This guide provides debugging strategies for developers working with the Point & Click Engine. It focuses on maintained specs and the current engine surfaces rather than one-off probe scripts.

## Table of Contents

1. [Quick Debugging Checklist](#quick-debugging-checklist)
2. [Common Issues and Solutions](#common-issues-and-solutions)
3. [Focused Specs](#focused-specs)
4. [Movement System Debugging](#movement-system-debugging)
5. [Debug Output Interpretation](#debug-output-interpretation)
6. [Testing Strategies](#testing-strategies)
7. [Integration with Your Game](#integration-with-your-game)
8. [Advanced Debugging Techniques](#advanced-debugging-techniques)

## Quick Debugging Checklist

When encountering issues with your Point & Click game, follow this checklist:

1. **Enable Debug Mode**
   ```crystal
   PointClickEngine::Core::Engine.debug_mode = true
   ```

2. **Check Existing Automated Coverage**
   ```bash
   ./run_specs_safely.sh fast
   ```

3. **Run A Focused Spec Slice**
   ```bash
   crystal spec spec/navigation/pathfinding_integration_spec.cr
   ```

4. **Test The Full Suite In Batches**
   ```bash
   ./run_specs_safely.sh
   ```

## Common Issues and Solutions

### Issue 1: Player Doesn't Move When Clicking

**Symptoms:**
- Clicking produces no movement
- No debug output on clicks

**Quick Diagnosis:**
```bash
crystal spec spec/integration/player_visibility_test_spec.cr spec/navigation/pathfinding_integration_spec.cr
```

**Potential Causes and Solutions:**

1. **Input handling disabled**
   ```crystal
   # Check and enable
   engine.handle_clicks = true
   ```

2. **Game window doesn't have focus**
   - Click on the game window to give it focus
   - Verify window is active in debug output

3. **Player movement disabled**
   ```crystal
   # Check player state
   player.movement_enabled = true
   ```

4. **Input handler not processing clicks**
   ```crystal
   # Verify input handler is set
   puts "Input handler present: #{!engine.input_handler.nil?}"
   ```

### Issue 2: Clicks Detected but Movement Fails

**Symptoms:**
- Debug shows "Walkable check: false" for all positions
- Click events logged but no movement initiated

**Quick Diagnosis:**
```bash
crystal spec spec/core/preflight/scene_validation_spec.cr spec/navigation/pathfinding_integration_spec.cr
```

**Potential Causes and Solutions:**

1. **Walkable area misconfigured**
   ```crystal
   # Debug walkable area setup
   scene.walkable_area.regions.each do |region|
     puts "Region: #{region.name}, Walkable: #{region.walkable}"
     puts "Vertices: #{region.vertices}"
   end
   ```

2. **Player starting position outside walkable area**
   ```crystal
   # Verify player position
   puts "Player at: (#{player.position.x}, #{player.position.y})"
   puts "Is walkable: #{scene.walkable_area.contains?(player.position)}"
   ```

3. **Point-in-polygon algorithm issues**
   ```crystal
   # Test specific positions
   test_pos = Raylib::Vector2.new(x: 400, y: 300)
   puts "Position #{test_pos} walkable: #{scene.walkable_area.contains?(test_pos)}"
   ```

### Issue 3: Movement Starts but Player Doesn't Update Position

**Symptoms:**
- State changes to "Walking"
- Target position set correctly
- Player position doesn't change

**Quick Diagnosis:**
Check update loop execution:
```crystal
# In your game loop
puts "Update called, dt: #{dt}" if Engine.debug_mode
```

**Potential Causes and Solutions:**

1. **Update loop not running**
   ```crystal
   # Ensure scene.update(dt) is called
   scene.update(dt)
   ```

2. **Character update not called**
   ```crystal
   # Verify character update chain
   class DebugScene < Scene
     def update(dt)
       puts "Scene updating with dt: #{dt}"
       super
     end
   end
   ```

3. **Animation system interference**
   ```crystal
   # Check if animation state is blocking movement
   puts "Animation state: #{player.character.current_animation}"
   ```

## Focused Specs

Use the maintained specs as the primary debugging surface.

```bash
# Pathfinding, coordinate conversion, waypoint advancement
crystal spec spec/navigation/pathfinding_integration_spec.cr

# Same-cell movement edge cases
crystal spec spec/navigation/same_cell_movement_spec.cr

# Movement controller behavior
crystal spec spec/characters/movement_controller_spec.cr

# Preflight and asset-format validation
crystal spec spec/core/preflight/audio_validation_spec.cr spec/core/preflight/scene_validation_spec.cr
```

## Movement System Debugging

### Understanding the Movement Pipeline

The movement system follows this flow:

```
Mouse Click → Input Handler → Scene → Player → Character → Movement
     ↓              ↓           ↓        ↓         ↓           ↓
  Detected?    Enabled?    Walkable?  Method?   State?    Update?
```

### Debug Output for Each Stage

#### 1. Input Detection
```
🖱️  === CLICK DEBUG ===
📍 Raw position: (450, 300)
🧭 No camera - using screen coordinates
```

#### 2. Walkable Area Check
```
🚶 Walkable check: true
🗺️  Walkable area regions: 2
   1. main_walkable: CONTAINS (walkable)
   2. obstacle: outside (blocked)
```

#### 3. Player Response
```
🎮 Attempting player movement...
   ✅ Calling player.handle_click
   ✅ Player movement command sent
   📊 Player state: Walking
   🎯 Target position: Raylib::Vector2(@x=450.0, @y=300.0)
```

#### 4. Movement Updates
```
🔄 DEBUG: Walking... Distance to target: 125.3
🔄 DEBUG: Walking... Distance to target: 62.7
🔄 DEBUG: Walking... Distance to target: 0.0
🛑 DEBUG: stop_walking() called
```

## Debug Output Interpretation

### Successful Movement Flow

A successful movement operation produces this sequence:

```
🖱️  === CLICK DEBUG ===
📍 Raw position: (450, 300)
🧭 No camera - using screen coordinates
🚶 Walkable check: true
🗺️  Walkable area regions: 2
   1. main_walkable: CONTAINS (walkable)
   2. obstacle: outside (blocked)
🎯 Hotspot clicked: None
🎮 Attempting player movement...
   ✅ Calling player.handle_click
   ✅ Player movement command sent
   📊 Player state: Walking
   🎯 Target position: Raylib::Vector2(@x=450.0, @y=300.0)
🖱️  === END CLICK DEBUG ===
```

### Common Failure Patterns

#### Click Handling Disabled
```
🖱️  DEBUG: handle_clicks enabled: false  ← Problem identified
```

#### Position Not Walkable
```
🚶 Walkable check: false  ← Problem identified
   2. obstacle: CONTAINS (blocked)  ← Clicked on obstacle
```

#### Player Method Missing
```
❌ Player does not respond to handle_click  ← Method not implemented
```

## Testing Strategies

### 1. Isolate the Problem

Start with the simplest test and add complexity:

```bash
# Level 1: Path and movement edge cases
crystal spec spec/navigation/pathfinding_integration_spec.cr
crystal spec spec/navigation/same_cell_movement_spec.cr

# Level 2: Movement controller behavior
crystal spec spec/characters/movement_controller_spec.cr

# Level 3: Full system
./run_specs_safely.sh
```

### 2. Add Custom Debug Output

Create debug versions of your classes:

```crystal
class DebugPlayer < PointClickEngine::Characters::Player
  def handle_click(mouse_pos : RL::Vector2, scene : Scene)
    puts "🖱️  DEBUG: Player.handle_click called at (#{mouse_pos.x}, #{mouse_pos.y})"
    super
  end

  def walk_to(target : RL::Vector2)
    puts "🎯 DEBUG: walk_to(#{target.x}, #{target.y}) called"
    super
  end
end
```

### 3. Verify Walkable Areas

Test walkable area setup:

```crystal
# Create test positions
test_positions = [
  {name: "Center", pos: RL::Vector2.new(x: 400, y: 300)},
  {name: "Top-left", pos: RL::Vector2.new(x: 100, y: 100)},
  {name: "Obstacle", pos: RL::Vector2.new(x: 400, y: 275)}
]

# Test each position
test_positions.each do |test|
  walkable = scene.walkable_area.contains?(test[:pos])
  puts "#{test[:name]} (#{test[:pos].x}, #{test[:pos].y}): #{walkable ? "✅" : "❌"}"
end
```

## Integration with Your Game

### Step 1: Enable Debug Mode

Add to your game initialization:

```crystal
require "point_click_engine"

class MyGame < PointClickEngine::Core::Engine
  def initialize
    super
    PointClickEngine::Core::Engine.debug_mode = true
  end
end
```

### Step 2: Add Debug Keyboard Shortcuts

```crystal
# In your game loop or input handler
if RL.key_pressed?(RL::KeyboardKey::F1)
  Engine.debug_mode = !Engine.debug_mode
  puts "Debug mode: #{Engine.debug_mode ? "ON" : "OFF"}"
end

if RL.key_pressed?(RL::KeyboardKey::F2) && Engine.debug_mode
  # Dump current state
  puts "=== Game State ==="
  puts "Player position: #{player.position}"
  puts "Player state: #{player.character.state}"
  puts "Scene: #{current_scene.name}"
  puts "================="
end
```

### Step 3: Create Debug Scene

```crystal
class DebugScene < PointClickEngine::Scenes::Scene
  def initialize(name : String)
    super
    @debug_messages = [] of String
  end

  def handle_click(mouse_pos : RL::Vector2)
    @debug_messages << "Click at (#{mouse_pos.x}, #{mouse_pos.y})"
    super
  end

  def draw
    super
    if Engine.debug_mode
      # Draw debug info
      y = 10
      @debug_messages.last(10).each do |msg|
        RL.draw_text(msg, 10, y, 12, RL::WHITE)
        y += 15
      end
    end
  end
end
```

## Advanced Debugging Techniques

### 1. Visual Debug Rendering

Enable visual debugging to see walkable areas and paths:

```crystal
# In debug mode, walkable areas are automatically rendered
# Green = walkable, Red = blocked
Engine.debug_mode = true
```

### 2. Performance Profiling

Add timing to critical sections:

```crystal
class TimedPlayer < Player
  def update(dt)
    start_time = Time.monotonic
    super
    elapsed = Time.monotonic - start_time
    
    if elapsed.total_milliseconds > 16.0  # More than one frame
      puts "⚠️  Player update took #{elapsed.total_milliseconds}ms"
    end
  end
end
```

### 3. State Machine Debugging

Track state transitions:

```crystal
class DebugCharacter < Character
  def set_state(new_state : CharacterState)
    old_state = @state
    super
    puts "State transition: #{old_state} → #{new_state}"
  end
end
```

### 4. Event Logging

Create an event logger for complex debugging:

```crystal
class DebugEventLogger
  @@events = [] of {time: Time, event: String}

  def self.log(event : String)
    @@events << {time: Time.local, event: event}
    puts "[#{Time.local}] #{event}" if Engine.debug_mode
  end

  def self.dump_recent(count = 20)
    puts "=== Recent Events ==="
    @@events.last(count).each do |entry|
      puts "[#{entry[:time]}] #{entry[:event]}"
    end
    puts "==================="
  end
end
```

## Keyboard Shortcuts Reference

When debug mode is enabled:

- **F1**: Toggle debug mode on/off
- **F2**: Dump current game state (when in debug mode)
- **Tab**: Toggle hotspot highlighting
- **SPACE**: Show debug info (in test files)
- **F5**: Toggle camera edge scrolling
- **ESC**: Show pause menu

## Expected Results

After following this debugging guide, you should be able to:

1. **Identify the exact point of failure** in any system
2. **See detailed logs** of game behavior
3. **Verify component setup** with visual debugging
4. **Test systems in isolation** to narrow down issues
5. **Add custom debugging** to your specific game code

## Summary

Effective debugging in the Point & Click Engine involves:

1. **Using the built-in debug mode** for visual feedback
2. **Running targeted tests** to isolate problems
3. **Adding custom debug output** at key points
4. **Understanding the debug messages** to trace issues
5. **Testing incrementally** from simple to complex

Remember: most issues can be quickly identified by running the appropriate test file and reading the debug output carefully. The engine provides extensive debugging information - the key is knowing where to look.
