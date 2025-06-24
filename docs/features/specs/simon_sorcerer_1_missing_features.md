# Simon the Sorcerer 1 - Missing Features Specification

This document details the remaining features needed to achieve full feature parity with Simon the Sorcerer 1, a classic point-and-click adventure game from 1993.

## Table of Contents

1. [Enhanced Animation System](#1-enhanced-animation-system)
2. [Dialog Portrait System](#2-dialog-portrait-system)
3. [Floating Dialog Text](#3-floating-dialog-text)
4. [UI Improvements](#4-ui-improvements)
5. [Advanced State Management](#5-advanced-state-management)
6. [Cutscene Improvements](#6-cutscene-improvements)
7. [Sound Improvements](#7-sound-improvements)
8. [Implementation Priority](#implementation-priority)

## 1. Enhanced Animation System

### Overview
Simon the Sorcerer 1 features smooth character animations with multiple directions and context-specific animations for various actions.

### Requirements

#### 1.1 Directional Walking Animations
- **8-direction support**: N, NE, E, SE, S, SW, W, NW
- **Smooth transitions** between directions
- **Variable walk speeds** based on character state or terrain
- **Turning animations** when changing direction significantly

#### 1.2 Animation States
```crystal
enum AnimationState
  Idle
  Walking
  Talking
  PickingUp
  Using
  Pushing
  Pulling
  Climbing
  Sitting
  Standing
  Dying
  Custom
end
```

#### 1.3 Idle Animations
- **Inactivity timer**: Trigger after 5-10 seconds of no input
- **Multiple idle variations**:
  - Looking around
  - Tapping foot
  - Checking watch/inventory
  - Yawning
  - Character-specific idles (Simon adjusting his hat)
- **Interrupt on any input**

#### 1.4 Action Animations
- **Pick up**: Bend down, reach out, grab
- **Use**: Context-specific (drink potion, pull lever, turn key)
- **Push/Pull**: Lean into object, strain animation
- **Talk**: Gesture animations synchronized with dialog
- **Examine**: Lean in, peer closely

#### 1.5 Special Animations
- **Death/Game Over**: Dramatic collapse
- **Teleport**: Magical disappear/appear effects
- **Transform**: Shape-shifting sequences
- **Cutscene-specific**: One-off animations for story moments

### Implementation Details

```crystal
class EnhancedCharacter < Character
  property animation_controller : AnimationController
  property idle_timer : Float32 = 0.0
  property last_direction : Direction = Direction::South
  
  def update(dt : Float32)
    super
    
    # Update idle timer
    if @velocity.length == 0
      @idle_timer += dt
      if @idle_timer > IDLE_TRIGGER_TIME
        play_idle_animation
      end
    else
      @idle_timer = 0.0
      update_walking_animation
    end
  end
  
  private def update_walking_animation
    direction = calculate_direction_from_velocity(@velocity)
    if direction != @last_direction
      # Play turn animation first
      @animation_controller.play_turn(from: @last_direction, to: direction)
    end
    @animation_controller.play_walk(direction)
    @last_direction = direction
  end
end
```

## 2. Dialog Portrait System

### Overview
Character portraits appear during conversations to show who is speaking, with animated facial features for enhanced expressiveness.

### Requirements

#### 2.1 Portrait Display
- **Portrait frame**: Decorative border around character portrait
- **Position options**:
  - Bottom corners (left for player, right for NPCs)
  - Top of screen for narrator
  - Dynamic positioning based on character location
- **Size**: Typically 64x64 or 128x128 pixels
- **Smooth fade in/out**

#### 2.2 Portrait Animations
- **Mouth movements**: 
  - Basic: 2-3 frames (closed, partially open, fully open)
  - Advanced: Lip-sync to dialog text
- **Eye animations**:
  - Blinking (random intervals)
  - Looking at player/speaker
  - Eye rolling for sarcasm
- **Expression changes**:
  - Happy, sad, angry, surprised, thinking
  - Smooth transitions between expressions

#### 2.3 Portrait Styles
- **Standard portraits**: Front-facing character art
- **Situational portraits**: Different art for special states
  - Injured/tired
  - Transformed/disguised
  - Emotional states
- **Animated backgrounds**: Subtle effects (glow, sparkles)

### Implementation Details

```crystal
class DialogPortrait
  property character_name : String
  property portrait_textures : Hash(String, RL::Texture2D)
  property current_expression : String = "neutral"
  property mouth_frames : Array(RL::Rectangle)
  property blink_timer : Float32 = 0.0
  property is_talking : Bool = false
  
  def initialize(@character_name : String)
    @portrait_textures = {} of String => RL::Texture2D
    @mouth_frames = [] of RL::Rectangle
    load_portraits
  end
  
  def update(dt : Float32)
    # Update blinking
    @blink_timer += dt
    if @blink_timer > BLINK_INTERVAL
      trigger_blink
      @blink_timer = 0.0
    end
    
    # Update mouth animation if talking
    if @is_talking
      update_mouth_animation(dt)
    end
  end
  
  def draw(position : RL::Vector2)
    # Draw portrait background/frame
    draw_portrait_frame(position)
    
    # Draw character portrait with current expression
    texture = @portrait_textures[@current_expression]
    RL.draw_texture_ex(texture, position, 0.0, 1.0, RL::WHITE)
    
    # Draw mouth animation overlay
    if @is_talking
      draw_mouth_frame(position)
    end
    
    # Draw eye animation overlay
    draw_eye_animation(position)
  end
end
```

## 3. Floating Dialog Text

### Overview
Dialog text appears as floating speech bubbles or text above character heads, providing a more immersive conversation experience.

### Requirements

#### 3.1 Text Display
- **Position**: Centered above character's head
- **Dynamic height**: Adjust based on character position on screen
- **Word wrapping**: Intelligent breaking for long sentences
- **Maximum width**: Prevent text from extending off-screen

#### 3.2 Visual Styling
- **Background options**:
  - Speech bubble with tail pointing to speaker
  - Semi-transparent rounded rectangle
  - Color-coded by character
- **Text colors**:
  - White with black outline (standard)
  - Character-specific colors
  - Emotion-based colors (red for angry, blue for sad)
- **Font options**:
  - Readable at small sizes
  - Support for bold/italic emphasis
  - Unicode support for multiple languages

#### 3.3 Animation
- **Fade in/out**: Smooth appearance and disappearance
- **Typewriter effect**: Letters appear one by one
- **Bounce effect**: Gentle floating motion
- **Emphasis animations**: Shake for shouting, wave for singing

#### 3.4 Timing
- **Duration calculation**: Based on text length and reading speed
- **Minimum duration**: 2 seconds
- **Maximum duration**: 10 seconds
- **Skip on click**: Allow player to advance dialog

### Implementation Details

```crystal
class FloatingDialog
  property text : String
  property character : Character
  property color : RL::Color
  property duration : Float32
  property elapsed : Float32 = 0.0
  property style : DialogStyle = DialogStyle::Bubble
  
  enum DialogStyle
    Bubble
    Rectangle
    Thought
    Shout
    Whisper
  end
  
  def initialize(@text : String, @character : Character, @duration : Float32)
    @color = character.dialog_color
    calculate_text_wrapping
  end
  
  def update(dt : Float32) : Bool
    @elapsed += dt
    
    # Update floating animation
    @offset_y = Math.sin(@elapsed * 2.0) * 5.0
    
    # Return true when dialog should be removed
    @elapsed >= @duration
  end
  
  def draw
    position = calculate_position
    
    case @style
    when .bubble?
      draw_speech_bubble(position)
    when .thought?
      draw_thought_bubble(position)
    when .shout?
      draw_shout_text(position)
    end
    
    # Draw text with effects
    draw_text_with_effects(position)
  end
  
  private def calculate_position : RL::Vector2
    # Position above character's head
    char_pos = @character.position
    char_height = @character.size.y
    
    x = char_pos.x
    y = char_pos.y - char_height - 20 + @offset_y
    
    # Keep on screen
    x = Math.max(100, Math.min(x, screen_width - 100))
    y = Math.max(50, y)
    
    RL::Vector2.new(x: x, y: y)
  end
end
```

## 4. UI Improvements

### Overview
Enhanced user interface elements that provide better feedback and control options.

### Requirements

#### 4.1 Verb Coin Interface
- **Right-click activation**: Context menu appears at cursor
- **Circular design**: Verbs arranged in a circle
- **Smart verb selection**: Only show relevant verbs
- **Visual feedback**: Highlight on hover
- **Quick access**: Most common verb at top

#### 4.2 Status Bar
- **Current verb display**: Shows selected action
- **Object name**: Highlights what cursor is over
- **Inventory count**: Number of items carried
- **Score/progress**: Optional game progress indicator

#### 4.3 Subtitle System
- **Toggle option**: On/off in settings
- **Speed control**: Adjustable text speed
- **Background box**: Improves readability
- **Speaker names**: Optionally show who's talking

#### 4.4 Options Menu
- **Text speed**: Slider for dialog speed
- **Subtitle toggle**: On/off switch
- **Skip options**: Skip seen text, skip all
- **Language selection**: If multiple languages available

### Implementation Details

```crystal
class VerbCoin
  property verbs : Array(VerbType)
  property active : Bool = false
  property selected_verb : VerbType?
  property position : RL::Vector2
  
  def show(pos : RL::Vector2, applicable_verbs : Array(VerbType))
    @position = pos
    @verbs = applicable_verbs
    @active = true
    arrange_verbs_in_circle
  end
  
  def update
    return unless @active
    
    mouse_pos = RL.get_mouse_position
    angle = Math.atan2(mouse_pos.y - @position.y, 
                       mouse_pos.x - @position.x)
    
    # Select verb based on angle
    verb_index = ((angle + Math::PI) / (2 * Math::PI) * @verbs.size).to_i
    @selected_verb = @verbs[verb_index % @verbs.size]
  end
  
  def draw
    return unless @active
    
    # Draw coin background
    RL.draw_circle(@position.x.to_i, @position.y.to_i, 60, 
                   RL::Color.new(r: 0, g: 0, b: 0, a: 180))
    
    # Draw verb icons
    @verbs.each_with_index do |verb, i|
      angle = (i.to_f / @verbs.size) * 2 * Math::PI - Math::PI/2
      x = @position.x + Math.cos(angle) * 40
      y = @position.y + Math.sin(angle) * 40
      
      color = verb == @selected_verb ? RL::YELLOW : RL::WHITE
      draw_verb_icon(verb, x, y, color)
    end
  end
end
```

## 5. Advanced State Management

### Overview
Complex game state tracking for puzzles, quests, and player progress.

### Requirements

#### 5.1 Global Game Flags
- **Boolean flags**: Simple on/off states
- **Integer counters**: Track quantities, attempts
- **String variables**: Store names, passwords
- **Float timers**: Time-based puzzles

#### 5.2 Quest System
- **Quest definitions**: Start conditions, objectives, rewards
- **Progress tracking**: Current step in multi-part quests
- **Journal entries**: Automatic notes about quests
- **Completion callbacks**: Trigger events on completion

#### 5.3 Achievement System
- **Achievement definitions**: Name, description, icon
- **Unlock conditions**: Based on game state
- **Progress tracking**: Partial completion for multi-step
- **Notification display**: Pop-up when unlocked

#### 5.4 Time System
- **Game time**: Separate from real time
- **Day/night cycle**: Affects scene lighting
- **Timed events**: NPCs with schedules
- **Time-based puzzles**: Must complete within limit

### Implementation Details

```crystal
class GameStateManager
  property flags : Hash(String, Bool)
  property variables : Hash(String, Int32 | Float32 | String)
  property quests : Hash(String, Quest)
  property achievements : Hash(String, Achievement)
  property game_time : GameTime
  
  def set_flag(name : String, value : Bool)
    old_value = @flags[name]?
    @flags[name] = value
    
    # Trigger any flag-based events
    if old_value != value
      trigger_flag_change_events(name, value)
    end
  end
  
  def check_condition(condition : String) : Bool
    # Parse complex conditions
    # Examples: "has_key && door_unlocked"
    #          "gold >= 100"
    #          "quest:find_wizard == completed"
    
    parser = ConditionParser.new(condition)
    parser.evaluate(self)
  end
  
  def update_quests
    @quests.each do |name, quest|
      next if quest.completed?
      
      # Check if quest objectives are met
      if quest.check_objectives(self)
        quest.complete
        trigger_quest_completion(quest)
      end
    end
  end
end

class Quest
  property name : String
  property description : String
  property objectives : Array(QuestObjective)
  property current_objective : Int32 = 0
  property completed : Bool = false
  
  def check_objectives(state : GameStateManager) : Bool
    @objectives.all? { |obj| obj.is_complete?(state) }
  end
end
```

## 6. Cutscene Improvements

### Overview
Enhanced cutscene system with camera controls and complex scripted sequences.

### Requirements

#### 6.1 Camera Controls
- **Pan**: Smooth movement across scene
- **Zoom**: In/out for dramatic effect
- **Shake**: For explosions, earthquakes
- **Focus**: Follow specific character
- **Transitions**: Fade, wipe between shots

#### 6.2 Scripted Sequences
- **Multiple actors**: Characters moving simultaneously
- **Synchronized actions**: Timed with dialog/music
- **Props**: Animated objects in scenes
- **Weather effects**: Rain, snow, lightning
- **Particle effects**: Magic, explosions

#### 6.3 Cutscene Scripting
- **Timeline-based**: Actions at specific times
- **Event-based**: Trigger on completion
- **Conditional branches**: Different paths
- **Skippable sections**: With checkpoint saves

### Implementation Details

```crystal
class CutsceneCamera
  property position : RL::Vector2
  property zoom : Float32 = 1.0
  property rotation : Float32 = 0.0
  property shake_intensity : Float32 = 0.0
  property target : Character?
  
  def pan_to(target_pos : RL::Vector2, duration : Float32)
    @pan_start = @position
    @pan_target = target_pos
    @pan_duration = duration
    @pan_elapsed = 0.0
  end
  
  def shake(intensity : Float32, duration : Float32)
    @shake_intensity = intensity
    @shake_duration = duration
    @shake_elapsed = 0.0
  end
  
  def update(dt : Float32)
    # Update pan
    if @pan_elapsed < @pan_duration
      @pan_elapsed += dt
      t = @pan_elapsed / @pan_duration
      t = ease_in_out_cubic(t)
      @position = @pan_start.lerp(@pan_target, t)
    end
    
    # Update shake
    if @shake_elapsed < @shake_duration
      @shake_elapsed += dt
      offset_x = (rand(-1.0..1.0) * @shake_intensity).to_f32
      offset_y = (rand(-1.0..1.0) * @shake_intensity).to_f32
      @shake_offset = RL::Vector2.new(x: offset_x, y: offset_y)
    else
      @shake_offset = RL::Vector2.new(x: 0, y: 0)
    end
    
    # Follow target
    if target = @target
      @position = target.position
    end
  end
end

class CutsceneDirector
  property timeline : Array(CutsceneEvent)
  property current_time : Float32 = 0.0
  property camera : CutsceneCamera
  
  def add_event(time : Float32, action : CutsceneAction)
    @timeline << CutsceneEvent.new(time, action)
    @timeline.sort_by!(&.time)
  end
  
  def update(dt : Float32)
    @current_time += dt
    
    # Execute events at their scheduled time
    while event = @timeline.first?
      break if event.time > @current_time
      
      event.action.execute(self)
      @timeline.shift
    end
    
    # Update camera
    @camera.update(dt)
  end
end
```

## 7. Sound Improvements

### Overview
Enhanced audio system with ambient sounds and contextual audio feedback.

### Requirements

#### 7.1 Ambient Sounds
- **Scene-specific ambience**: Forest birds, city traffic
- **Layered sounds**: Multiple ambient tracks
- **Volume by distance**: Quieter when far from source
- **Smooth transitions**: Crossfade between scenes

#### 7.2 Footstep System
- **Surface detection**: Different sounds for materials
  - Stone, wood, grass, metal, water
- **Character-specific**: Heavy boots vs. bare feet
- **Speed variation**: Walk vs. run sounds
- **Echo/reverb**: In large spaces

#### 7.3 3D Audio
- **Positional sounds**: Pan based on source location
- **Distance attenuation**: Volume decreases with distance
- **Doppler effect**: For moving sound sources
- **Occlusion**: Muffled through walls

#### 7.4 Sound Variations
- **Random pitch**: Slight variation to avoid repetition
- **Multiple samples**: Random selection from pool
- **Context-aware**: Different sounds for same action
- **Dynamic mixing**: Adjust levels based on scene

### Implementation Details

```crystal
class EnhancedAudioManager < AudioManager
  property ambient_layers : Array(AmbientLayer)
  property footstep_system : FootstepSystem
  property sound_variations : Hash(String, Array(RL::Sound))
  
  def play_footstep(character : Character, surface : SurfaceType)
    sound_key = "#{character.footstep_type}_#{surface}"
    
    if sounds = @sound_variations[sound_key]?
      # Random selection with pitch variation
      sound = sounds.sample
      pitch = rand(0.9..1.1)
      volume = calculate_volume_for_position(character.position)
      
      RL.set_sound_pitch(sound, pitch)
      RL.set_sound_volume(sound, volume)
      RL.play_sound(sound)
    end
  end
  
  def update_3d_audio(listener_pos : RL::Vector2)
    @active_sounds.each do |sound_instance|
      # Calculate pan based on position
      relative_x = sound_instance.position.x - listener_pos.x
      pan = Math.clamp(relative_x / AUDIO_PAN_WIDTH, -1.0, 1.0)
      
      # Calculate volume based on distance
      distance = listener_pos.distance(sound_instance.position)
      volume = Math.max(0.0, 1.0 - (distance / MAX_AUDIO_DISTANCE))
      
      # Apply audio settings
      RL.set_sound_pan(sound_instance.sound, pan)
      RL.set_sound_volume(sound_instance.sound, volume)
    end
  end
end

class AmbientLayer
  property sound : RL::Music
  property base_volume : Float32
  property fade_speed : Float32 = 1.0
  property current_volume : Float32 = 0.0
  property target_volume : Float32 = 0.0
  
  def fade_in
    @target_volume = @base_volume
  end
  
  def fade_out
    @target_volume = 0.0
  end
  
  def update(dt : Float32)
    if @current_volume != @target_volume
      diff = @target_volume - @current_volume
      change = diff * @fade_speed * dt
      @current_volume += change
      
      RL.set_music_volume(@sound, @current_volume)
    end
  end
end
```

## Implementation Priority

### Phase 1: Core Visual Improvements (High Priority)
1. **Enhanced Animation System** - Critical for game feel
2. **Floating Dialog Text** - Major visual improvement
3. **Dialog Portrait System** - Adds character personality

### Phase 2: UI and Polish (Medium Priority)
4. **Verb Coin Interface** - Modernizes controls
5. **Status Bar Improvements** - Better player feedback
6. **Subtitle System** - Accessibility feature

### Phase 3: Advanced Features (Lower Priority)
7. **Advanced State Management** - For complex games
8. **Cutscene Improvements** - For story-heavy games
9. **Sound Improvements** - Final polish

## Testing Requirements

Each feature should include:
- Unit tests for core functionality
- Integration tests with existing systems
- Performance benchmarks
- Visual regression tests for UI elements
- Accessibility compliance checks

## Performance Considerations

- **Animation system**: Efficient sprite batching
- **Dialog rendering**: Text caching for repeated phrases
- **State management**: Fast lookup data structures
- **Audio**: Limit concurrent sounds
- **Cutscenes**: Preload assets before playback

## Conclusion

Implementing these features will bring the Point & Click Engine to full parity with Simon the Sorcerer 1's capabilities, while also adding modern improvements for better player experience and accessibility.