# Cutscene System Redesign: Unified Action Architecture

## Executive Summary

This document proposes a radical redesign of the cutscene system, merging it with the scene system through a unified action architecture. The goal is to eliminate ~1000+ lines of duplicate code while creating a more powerful, flexible, and maintainable system.

**Core Insight**: A cutscene is simply a scene with `player_control_enabled = false` running a scripted action sequence. By unifying the concepts, we gain:
- Single rendering pipeline (no more CutsceneManager.draw vs Scene.draw)
- Single camera system (merge CutsceneCamera into main Camera)
- Single sprite/background system
- Data-driven actions (eliminate 40+ action classes)
- Natural integration with existing EventBus, Effects, and Scripting systems

---

## Table of Contents

1. [Current Architecture Analysis](#1-current-architecture-analysis)
2. [Proposed Architecture](#2-proposed-architecture)
3. [Detailed Component Design](#3-detailed-component-design)
4. [Migration Strategy](#4-migration-strategy)
5. [Implementation Phases](#5-implementation-phases)
6. [YAML Format Evolution](#6-yaml-format-evolution)
7. [Integration Points](#7-integration-points)
8. [Risk Assessment & Mitigations](#8-risk-assessment--mitigations)
9. [Testing Strategy](#9-testing-strategy)
10. [File Changes Summary](#10-file-changes-summary)

---

## 1. Current Architecture Analysis

### 1.1 Current File Structure

```
src/cutscenes/
├── cutscene.cr              (167 lines) - Sequence container + DSL
├── cutscene_action.cr       (1461 lines) - 40+ action classes  <-- CODE SMELL
├── cutscene_loader.cr       (454 lines) - YAML parser with huge case statement
├── cutscene_manager.cr      (265 lines) - Orchestrator + duplicate rendering
├── cutscene_camera.cr       (~200 lines) - Duplicate camera system
└── cutscene_director.cr     (386 lines) - Timeline system (underutilized)
                             ─────────────
                             ~2933 lines total
```

### 1.2 Problems Identified

#### Problem 1: Massive Action File
`cutscene_action.cr` contains 40+ classes with repetitive structure:
```crystal
class SomeAction < CutsceneAction
  def start
    # Usually 1-3 lines delegating to a manager
  end
  def update_action(progress)
    # Often empty
  end
  def finish
    # Often empty
  end
end
```

**Impact**: Adding a new action requires changes in 3 files (action class, loader case, DSL method).

#### Problem 2: Parallel Rendering Systems
- `CutsceneManager.draw()` renders: background, sprites, action overlays
- `Scene.draw()` renders: background, objects, characters, effects
- During cutscenes, both systems fight for control

**Impact**: Visual inconsistencies, duplicate texture loading, complex state management.

#### Problem 3: Separate Camera Systems
- `CutsceneCamera` has: pan, zoom, shake, follow, easing
- Main `Camera` has: position, zoom, bounds
- Actions must know which camera to use

**Impact**: Camera effects don't persist across cutscene boundaries.

#### Problem 4: False Separation
Cutscenes heavily reference scene entities:
```crystal
# From CharacterMoveAction
if scene = Core::Engine.instance.current_scene
  if character = scene.get_character(@character_name)
    character.walk_to(@target)
  end
end
```

**Impact**: Cutscenes aren't truly independent - they're just awkwardly attached to scenes.

#### Problem 5: Loader Duplication
`CutsceneLoader.parse_action` has a 400-line case statement mirroring action classes.

**Impact**: Every action type requires synchronized changes in multiple locations.

### 1.3 What Works Well (Keep These)

1. **EffectManager integration** - Clean delegation to `effect_manager.add_scene_effect()`
2. **EventBus pattern** - Already has `CutsceneStartedEvent`, `CutsceneEndedEvent`
3. **YAML format** - The declarative action format is expressive and user-friendly
4. **EnhancedCutscene timeline** - Good concept for precise timing (underutilized)
5. **DSL builder** - The `cutscene.parallel { ... }` pattern is elegant

---

## 2. Proposed Architecture

### 2.1 Core Concept: Scene Script Mode

```
┌─────────────────────────────────────────────────────────────────┐
│                           SCENE                                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  Normal Mode (player_control_enabled = true)             │   │
│  │  - Input handler processes clicks                        │   │
│  │  - Player can move, interact                             │   │
│  │  - UI visible                                            │   │
│  └─────────────────────────────────────────────────────────┘   │
│                            ↕ toggle                             │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  Script Mode (player_control_enabled = false)            │   │
│  │  - ActionRunner executes action queue                    │   │
│  │  - Actions manipulate scene entities directly            │   │
│  │  - Optional: letterbox, UI hidden, cinematic camera      │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

### 2.2 New File Structure

```
src/actions/                    # NEW DIRECTORY
├── action.cr                   (~100 lines) - Base Action struct + lifecycle
├── action_runner.cr            (~200 lines) - Executes action queues
├── action_executor.cr          (~400 lines) - Single executor with all action types
├── action_loader.cr            (~200 lines) - Unified YAML/data parser
└── action_dsl.cr               (~150 lines) - Builder DSL for code-defined sequences

src/scenes/
├── scene.cr                    (MODIFIED) - Add script_runner integration
└── ...

src/cutscenes/                  # DEPRECATED (but kept for transition)
├── cutscene_compat.cr          (~100 lines) - Thin wrapper for backwards compat
└── ...

src/graphics/
├── camera.cr                   (MODIFIED) - Add cinematic features from CutsceneCamera
└── ...
```

### 2.3 Architectural Principles

1. **Actions as Data, Not Classes**
   - Actions are structs with type + params, not class hierarchies
   - Single executor interprets action data
   - Easy to add new action types (one case branch)

2. **Scene as Single Source of Truth**
   - All rendering goes through Scene
   - Cutscene "sprites" become temporary scene objects
   - One camera, one background renderer

3. **Composition Over Inheritance**
   - `ActionRunner` is a component attached to Scene
   - Can run multiple sequences (main + overlay)
   - Parallel actions are just concurrent runners

4. **Event-Driven Integration**
   - Actions emit events on start/complete
   - Lua scripts can listen and react
   - EventBus connects all systems

---

## 3. Detailed Component Design

### 3.1 Action (Data Structure)

```crystal
module PointClickEngine
  module Actions
    # Core action data - no behavior, just data
    struct ActionData
      include YAML::Serializable

      property type : String
      property params : Hash(String, YAML::Any)
      property duration : Float32 = 0.0f32
      property wait_for_completion : Bool = true

      def initialize(@type, @params = {} of String => YAML::Any, @duration = 0.0f32)
      end
    end

    # Runtime action state
    class ActionInstance
      property data : ActionData
      property state : ActionState = ActionState::Pending
      property elapsed : Float32 = 0.0f32
      property started : Bool = false
      property custom_data : Hash(String, YAML::Any)?  # For action-specific runtime data

      enum ActionState
        Pending
        Running
        Completed
        Cancelled
      end

      def initialize(@data)
      end

      def progress : Float32
        return 1.0f32 if @data.duration <= 0
        (@elapsed / @data.duration).clamp(0.0f32, 1.0f32)
      end

      def finished? : Bool
        @state == ActionState::Completed || @state == ActionState::Cancelled
      end

      def reset
        @state = ActionState::Pending
        @elapsed = 0.0f32
        @started = false
        @custom_data = nil
      end
    end
  end
end
```

### 3.2 ActionExecutor (Single Point of Execution)

```crystal
module PointClickEngine
  module Actions
    # Executes action instances - all action logic in one place
    class ActionExecutor
      def initialize(@engine : Core::Engine)
      end

      # Start an action - called once when action begins
      def start(action : ActionInstance, scene : Scenes::Scene)
        case action.data.type.downcase

        # === TIMING ===
        when "wait"
          # No-op, just waits for duration

        # === MOVEMENT ===
        when "character_move", "move_character"
          char_name = get_string(action, "character")
          target = get_vector2(action, "target") || get_vector2(action, "to")
          if char = scene.get_character(char_name)
            if target
              use_pathfinding = get_bool(action, "pathfinding", true)
              if use_pathfinding && (path = scene.find_path(char.position.x, char.position.y, target.x, target.y))
                char.walk_to_with_path(path)
              else
                char.walk_to(target)
              end
            end
          end

        when "character_enter"
          char_name = get_string(action, "character")
          from = get_string(action, "from", "left")
          to = get_vector2(action, "to")
          if char = scene.get_character(char_name)
            start_pos = calculate_entry_position(from, to, scene)
            char.position = start_pos
            char.visible = true
            char.walk_to(to) if to
          end

        when "character_exit"
          char_name = get_string(action, "character")
          direction = get_string(action, "direction", "left")
          if char = scene.get_character(char_name)
            exit_pos = calculate_exit_position(direction, char.position, scene)
            char.walk_to(exit_pos)
            # Store char ref to hide on finish
            action.custom_data = {"hide_character" => char_name}
          end

        when "character_face"
          char_name = get_string(action, "character")
          direction = get_string(action, "direction")
          if char = scene.get_character(char_name)
            char.direction = parse_direction(direction)
          end

        when "character_animation"
          char_name = get_string(action, "character")
          anim = get_string(action, "animation")
          if char = scene.get_character(char_name)
            char.play_animation(anim)
          end

        # === DIALOG ===
        when "dialog", "floating_dialog"
          char_name = get_string(action, "character")
          text = get_string(action, "text")
          if char = scene.get_character(char_name)
            # Store completion flag in custom_data
            action.custom_data = {"dialog_complete" => false}
            char.say(text) do
              if cd = action.custom_data
                cd["dialog_complete"] = true
              end
              nil
            end
          end

        # === CAMERA ===
        when "camera_shake"
          intensity = get_float(action, "intensity", 5.0f32)
          frequency = get_float(action, "frequency", 10.0f32)
          @engine.effect_manager.add_camera_effect("shake",
            amplitude: intensity,
            frequency: frequency,
            duration: action.data.duration
          )

        when "camera_pan"
          target = get_vector2(action, "target") || get_vector2(action, "to")
          easing = get_string(action, "easing", "ease_in_out")
          if target
            @engine.effect_manager.add_camera_effect("pan",
              target: [target.x, target.y],
              duration: action.data.duration,
              easing: easing
            )
          end

        when "camera_zoom"
          target_zoom = get_float(action, "target", 1.0f32)
          easing = get_string(action, "easing", "ease_in_out")
          @engine.effect_manager.add_camera_effect("zoom",
            target: target_zoom,
            duration: action.data.duration,
            easing: easing
          )

        # === VISUAL EFFECTS ===
        when "fade_in"
          color = get_color(action, "color") || Raylib::BLACK
          @engine.effect_manager.add_scene_effect("fade",
            direction: "in",
            color: [color.r.to_i, color.g.to_i, color.b.to_i, color.a.to_i],
            duration: action.data.duration
          )

        when "fade_out", "fade_to_color", "fade_to_black"
          color = get_color(action, "color") || Raylib::BLACK
          @engine.effect_manager.add_scene_effect("fade",
            direction: "out",
            color: [color.r.to_i, color.g.to_i, color.b.to_i, color.a.to_i],
            duration: action.data.duration
          )

        when "screen_flash"
          color = get_color(action, "color") || Raylib::WHITE
          @engine.effect_manager.add_scene_effect("flash",
            color: [color.r.to_i, color.g.to_i, color.b.to_i, color.a.to_i],
            duration: action.data.duration
          )

        when "particle_effect", "weather_effect"
          effect_type = get_string(action, "effect")
          intensity = get_float(action, "intensity", 1.0f32)
          add_particle_effect(effect_type, intensity, action.data.duration)

        when "letterbox", "set_letterbox"
          enabled = get_bool(action, "enabled", true)
          ratio = get_float(action, "ratio", 2.35f32)
          if enabled
            effect = Graphics::Effects::SceneEffects::LetterboxEffect.new(ratio, 0.0f32, true)
            effect.enable(action.data.duration)
            @engine.effect_manager.add_scene_effect(effect)
          else
            # Find and disable existing letterbox
            @engine.effect_manager.scene_effects.each do |effect|
              if lb = effect.as?(Graphics::Effects::SceneEffects::LetterboxEffect)
                lb.disable(action.data.duration)
              end
            end
          end

        # === AUDIO ===
        when "play_music"
          track = get_string(action, "track")
          volume = get_float(action, "volume", 0.7f32)
          loop_music = get_bool(action, "loop", true)
          if audio = @engine.system_manager.audio_manager
            audio.play_music(track, loop_music)
            audio.set_music_volume(volume)
          end

        when "stop_music"
          if audio = @engine.system_manager.audio_manager
            # Fade handled by update if duration > 0
            if action.data.duration <= 0
              audio.stop_music
            else
              action.custom_data = {"start_volume" => audio.music_volume}
            end
          end

        when "sound_effect", "play_sound"
          sound = get_string(action, "sound")
          if audio = @engine.system_manager.audio_manager
            audio.play_sound_effect(sound)
          end

        # === UI ===
        when "hide_ui"
          @engine.render_manager.hide_ui

        when "show_ui"
          @engine.render_manager.show_ui

        when "show_text"
          # Create text overlay effect
          text = get_string(action, "text")
          font_size = get_int(action, "font_size", 24)
          color = get_color(action, "color") || Raylib::WHITE
          position = get_string(action, "position", "center")
          # Store in custom_data for draw
          action.custom_data = {
            "text" => text,
            "font_size" => font_size,
            "color" => color,
            "position" => position,
            "alpha" => 0.0f32
          }

        # === GAME STATE ===
        when "set_game_state", "set_flag", "set_variable"
          if state = @engine.game_state_manager
            if flags = action.data.params["flags"]?.try(&.as_a)
              flags.each { |f| state.set_flag(f.as_s, true) }
            end
            if vars = action.data.params["variables"]?.try(&.as_h)
              vars.each do |k, v|
                case v.raw
                when Bool then state.set_flag(k.as_s, v.as_bool)
                when Int64 then state.set_variable(k.as_s, v.as_i.to_i32)
                when Float64 then state.set_variable(k.as_s, v.as_f.to_f32)
                when String then state.set_variable(k.as_s, v.as_s)
                end
              end
            end
          end

        # === SCENE ===
        when "change_scene"
          target = get_string(action, "target")
          transition = get_string(action, "transition", "fade")
          @engine.change_scene_with_transition(target, transition, action.data.duration)

        # === CONTROL ===
        when "enable_player_control"
          @engine.player_control_enabled = true

        when "disable_player_control"
          @engine.player_control_enabled = false

        when "callback", "run"
          # Handled specially by ActionRunner for code-defined callbacks

        else
          puts "[ActionExecutor] Unknown action type: #{action.data.type}"
        end

        action.started = true
        action.state = ActionInstance::ActionState::Running
      end

      # Update an action - called every frame while running
      # Returns true if action is complete
      def update(action : ActionInstance, scene : Scenes::Scene, dt : Float32) : Bool
        action.elapsed += dt
        progress = action.progress

        case action.data.type.downcase

        when "character_move", "move_character", "character_enter"
          char_name = get_string(action, "character")
          if char = scene.get_character(char_name)
            # Complete when character stops walking
            return char.state != Characters::CharacterState::Walking
          end
          return true  # Character not found, complete immediately

        when "character_exit"
          char_name = get_string(action, "character")
          if char = scene.get_character(char_name)
            return char.state != Characters::CharacterState::Walking
          end
          return true

        when "dialog", "floating_dialog"
          # Check completion flag or duration
          if cd = action.custom_data
            return cd["dialog_complete"]?.try(&.as_bool) || false
          end
          return action.data.duration > 0 && progress >= 1.0

        when "stop_music"
          if action.data.duration > 0
            if audio = @engine.system_manager.audio_manager
              start_vol = action.custom_data.try(&.["start_volume"]?.try(&.as_f32)) || 1.0f32
              audio.set_music_volume(start_vol * (1.0f32 - progress))
            end
          end
          return progress >= 1.0

        when "show_text"
          # Update alpha for fade in/out
          if cd = action.custom_data
            fade_in = get_float(action, "fade_in", 0.5f32)
            fade_out = get_float(action, "fade_out", 0.5f32)
            total = action.data.duration

            alpha = if action.elapsed < fade_in
              action.elapsed / fade_in
            elsif action.elapsed > total - fade_out
              (total - action.elapsed) / fade_out
            else
              1.0f32
            end
            cd["alpha"] = alpha.clamp(0.0f32, 1.0f32)
          end
          return progress >= 1.0

        else
          # Most actions complete based on duration
          return action.data.duration <= 0 || progress >= 1.0
        end
      end

      # Finish an action - called once when action completes
      def finish(action : ActionInstance, scene : Scenes::Scene)
        case action.data.type.downcase

        when "character_exit"
          if cd = action.custom_data
            if char_name = cd["hide_character"]?.try(&.as_s)
              if char = scene.get_character(char_name)
                char.visible = false
              end
            end
          end

        when "stop_music"
          if audio = @engine.system_manager.audio_manager
            audio.stop_music
            # Restore volume for next track
            start_vol = action.custom_data.try(&.["start_volume"]?.try(&.as_f32)) || 1.0f32
            audio.set_music_volume(start_vol)
          end

        end

        action.state = ActionInstance::ActionState::Completed
      end

      # Draw action overlays (for text, custom visuals)
      def draw(action : ActionInstance)
        case action.data.type.downcase
        when "show_text"
          draw_text_overlay(action)
        end
      end

      # === HELPER METHODS ===

      private def get_string(action : ActionInstance, key : String, default : String = "") : String
        action.data.params[key]?.try(&.as_s) || default
      end

      private def get_float(action : ActionInstance, key : String, default : Float32 = 0.0f32) : Float32
        action.data.params[key]?.try(&.as_f.to_f32) || default
      end

      private def get_int(action : ActionInstance, key : String, default : Int32 = 0) : Int32
        action.data.params[key]?.try(&.as_i.to_i32) || default
      end

      private def get_bool(action : ActionInstance, key : String, default : Bool = false) : Bool
        action.data.params[key]?.try(&.as_bool) || default
      end

      private def get_vector2(action : ActionInstance, key : String) : Raylib::Vector2?
        if data = action.data.params[key]?
          if data.as_h?
            x = data["x"]?.try(&.as_f.to_f32) || 0f32
            y = data["y"]?.try(&.as_f.to_f32) || 0f32
            return Raylib::Vector2.new(x: x, y: y)
          end
        end
        nil
      end

      private def get_color(action : ActionInstance, key : String) : Raylib::Color?
        if data = action.data.params[key]?
          if arr = data.as_a?
            return Raylib::Color.new(
              r: arr[0]?.try(&.as_i.to_u8) || 0u8,
              g: arr[1]?.try(&.as_i.to_u8) || 0u8,
              b: arr[2]?.try(&.as_i.to_u8) || 0u8,
              a: arr[3]?.try(&.as_i.to_u8) || 255u8
            )
          end
        end
        nil
      end

      private def parse_direction(dir : String) : Characters::Direction
        case dir.downcase
        when "left" then Characters::Direction::Left
        when "right" then Characters::Direction::Right
        when "up" then Characters::Direction::Up
        when "down" then Characters::Direction::Down
        else Characters::Direction::Right
        end
      end

      private def calculate_entry_position(from : String, to : Raylib::Vector2?, scene : Scenes::Scene) : Raylib::Vector2
        target_y = to.try(&.y) || 300f32
        case from.downcase
        when "left" then Raylib::Vector2.new(x: -50f32, y: target_y)
        when "right" then Raylib::Vector2.new(x: scene.logical_width.to_f32 + 50, y: target_y)
        when "top" then Raylib::Vector2.new(x: to.try(&.x) || 400f32, y: -50f32)
        when "bottom" then Raylib::Vector2.new(x: to.try(&.x) || 400f32, y: scene.logical_height.to_f32 + 50)
        else Raylib::Vector2.new(x: -50f32, y: target_y)
        end
      end

      private def calculate_exit_position(direction : String, current : Raylib::Vector2, scene : Scenes::Scene) : Raylib::Vector2
        case direction.downcase
        when "left" then Raylib::Vector2.new(x: -50f32, y: current.y)
        when "right" then Raylib::Vector2.new(x: scene.logical_width.to_f32 + 50, y: current.y)
        when "top" then Raylib::Vector2.new(x: current.x, y: -50f32)
        when "bottom" then Raylib::Vector2.new(x: current.x, y: scene.logical_height.to_f32 + 50)
        else Raylib::Vector2.new(x: -50f32, y: current.y)
        end
      end

      private def add_particle_effect(effect_type : String, intensity : Float32, duration : Float32)
        case effect_type.downcase
        when "sparkles", "magic"
          count = (intensity * 50).to_i
          @engine.effect_manager.add_scene_effect("sparkles", count: count, duration: duration)
        when "rain"
          intensity_name = intensity > 0.7 ? "heavy" : (intensity > 0.4 ? "medium" : "light")
          @engine.effect_manager.add_scene_effect("rain", intensity: intensity_name, duration: duration)
        when "fog", "mist"
          @engine.effect_manager.add_scene_effect("fog", density: intensity * 0.03, duration: duration)
        when "snow"
          count = (intensity * 100).to_i
          @engine.effect_manager.add_scene_effect("snow", count: count, duration: duration)
        end
      end

      private def draw_text_overlay(action : ActionInstance)
        return unless cd = action.custom_data

        text = cd["text"]?.try(&.as_s) || ""
        font_size = cd["font_size"]?.try(&.as_i) || 24
        alpha = cd["alpha"]?.try(&.as_f32) || 1.0f32
        position = cd["position"]?.try(&.as_s) || "center"

        return if alpha <= 0

        color = Raylib::WHITE
        color.a = (alpha * 255).to_u8

        screen_width = Raylib.get_screen_width
        screen_height = Raylib.get_screen_height
        text_width = Raylib.measure_text(text, font_size)

        x, y = case position
        when "center"
          {(screen_width - text_width) // 2, screen_height // 2}
        when "top"
          {(screen_width - text_width) // 2, screen_height // 6}
        when "bottom"
          {(screen_width - text_width) // 2, (screen_height * 5) // 6}
        else
          {(screen_width - text_width) // 2, screen_height // 2}
        end

        Raylib.draw_text(text, x, y, font_size, color)
      end
    end
  end
end
```

### 3.3 ActionRunner (Sequence Executor)

```crystal
module PointClickEngine
  module Actions
    # Runs a sequence of actions
    class ActionRunner
      property actions : Array(ActionInstance)
      property current_index : Int32 = 0
      property running : Bool = false
      property completed : Bool = false
      property skippable : Bool = true
      property name : String

      # Callbacks
      property on_complete : Proc(Nil)?
      property on_action_start : Proc(ActionInstance, Nil)?
      property on_action_complete : Proc(ActionInstance, Nil)?

      # Parallel action groups (run concurrently)
      @parallel_runners : Array(ActionRunner) = [] of ActionRunner

      @executor : ActionExecutor
      @engine : Core::Engine

      def initialize(@name : String, @engine : Core::Engine)
        @actions = [] of ActionInstance
        @executor = ActionExecutor.new(@engine)
      end

      # Add action from data
      def add(data : ActionData)
        @actions << ActionInstance.new(data)
      end

      # Add action directly
      def add(action : ActionInstance)
        @actions << action
      end

      # Add parallel action group
      def add_parallel(actions : Array(ActionData))
        runner = ActionRunner.new("#{@name}_parallel_#{@parallel_runners.size}", @engine)
        actions.each { |data| runner.add(data) }
        # Add marker action to main sequence
        marker = ActionData.new("_parallel_marker")
        marker_instance = ActionInstance.new(marker)
        marker_instance.custom_data = {"parallel_runner_index" => @parallel_runners.size}
        @actions << marker_instance
        @parallel_runners << runner
      end

      def play
        return if @actions.empty?

        @running = true
        @completed = false
        @current_index = 0
        @actions.each(&.reset)
        @parallel_runners.each(&.reset)

        # Disable player control
        @engine.player_control_enabled = false

        # Publish event
        @engine.system_manager.event_bus.try(&.publish(
          Core::Events::CutsceneStartedEvent.new(@name)
        ))
      end

      def stop
        @running = false
        @engine.player_control_enabled = true
        @on_complete.try(&.call)

        # Publish event
        @engine.system_manager.event_bus.try(&.publish(
          Core::Events::CutsceneEndedEvent.new(@name, skipped: false)
        ))
      end

      def skip
        return unless @skippable

        # Fast-forward all remaining actions
        while @current_index < @actions.size
          action = @actions[@current_index]
          unless action.finished?
            @executor.start(action, current_scene) unless action.started
            @executor.finish(action, current_scene)
          end
          @current_index += 1
        end

        @running = false
        @completed = true
        @engine.player_control_enabled = true
        @on_complete.try(&.call)

        # Publish event
        @engine.system_manager.event_bus.try(&.publish(
          Core::Events::CutsceneEndedEvent.new(@name, skipped: true)
        ))
      end

      def reset
        @running = false
        @completed = false
        @current_index = 0
        @actions.each(&.reset)
        @parallel_runners.each(&.reset)
      end

      def update(dt : Float32)
        return unless @running
        return if @completed

        scene = current_scene
        return unless scene

        # Update any active parallel runners
        @parallel_runners.each do |runner|
          runner.update(dt) if runner.running
        end

        # Process current action
        if @current_index < @actions.size
          action = @actions[@current_index]

          # Handle parallel marker
          if action.data.type == "_parallel_marker"
            if idx = action.custom_data.try(&.["parallel_runner_index"]?.try(&.as_i))
              parallel_runner = @parallel_runners[idx]
              unless parallel_runner.running || parallel_runner.completed
                parallel_runner.play
              end
              # Wait for parallel runner to complete
              if parallel_runner.completed
                action.state = ActionInstance::ActionState::Completed
                @current_index += 1
              end
            else
              @current_index += 1
            end
            return
          end

          # Start action if not started
          unless action.started
            @executor.start(action, scene)
            @on_action_start.try(&.call(action))
          end

          # Update action
          if @executor.update(action, scene, dt)
            # Action completed
            @executor.finish(action, scene)
            @on_action_complete.try(&.call(action))
            @current_index += 1
          end
        else
          # All actions completed
          @completed = true
          @running = false
          @engine.player_control_enabled = true
          @on_complete.try(&.call)

          # Publish event
          @engine.system_manager.event_bus.try(&.publish(
            Core::Events::CutsceneEndedEvent.new(@name, skipped: false)
          ))
        end
      end

      def draw
        return unless @running

        # Draw current action overlays
        if @current_index < @actions.size
          @executor.draw(@actions[@current_index])
        end

        # Draw parallel runner overlays
        @parallel_runners.each do |runner|
          runner.draw if runner.running
        end
      end

      private def current_scene : Scenes::Scene?
        @engine.current_scene
      end
    end
  end
end
```

### 3.4 ActionLoader (YAML Parser)

```crystal
module PointClickEngine
  module Actions
    class ActionLoader
      # Load action sequence from YAML file
      def self.load(path : String) : ActionRunner
        yaml_content = AssetLoader.read_yaml(path)
        data = YAML.parse(yaml_content)

        name = data["name"]?.try(&.as_s) || File.basename(path, ".yaml")
        runner = ActionRunner.new(name, Core::Engine.instance)

        # Set properties
        if skippable = data["skippable"]?
          runner.skippable = skippable.as_bool
        end

        # Parse actions
        if actions_data = data["actions"]?
          parse_actions(actions_data.as_a, runner)
        end

        runner
      end

      private def self.parse_actions(actions_data : Array(YAML::Any), runner : ActionRunner)
        actions_data.each do |action_data|
          if action = parse_action(action_data)
            runner.add(action)
          end
        end
      end

      private def self.parse_action(data : YAML::Any) : ActionData?
        type = data["type"]?.try(&.as_s) || return nil

        # Extract duration
        duration = data["duration"]?.try(&.as_f.to_f32) || 0.0f32

        # Build params hash from all other fields
        params = {} of String => YAML::Any
        data.as_h.each do |key, value|
          next if key == "type" || key == "duration"
          params[key.as_s] = value
        end

        ActionData.new(type, params, duration)
      end
    end
  end
end
```

### 3.5 Scene Integration

```crystal
# Additions to src/scenes/scene.cr

module PointClickEngine
  module Scenes
    class Scene
      # ... existing code ...

      # Script runner for cutscenes/sequences
      @[YAML::Field(ignore: true)]
      property script_runner : Actions::ActionRunner?

      # Run an action sequence (cutscene)
      def run_script(runner : Actions::ActionRunner)
        @script_runner = runner
        runner.play
      end

      # Run actions from YAML file
      def run_script_file(path : String)
        runner = Actions::ActionLoader.load(path)
        run_script(runner)
      end

      # Check if script is running
      def script_running? : Bool
        @script_runner.try(&.running) || false
      end

      # Stop current script
      def stop_script
        @script_runner.try(&.stop)
        @script_runner = nil
      end

      # Skip current script
      def skip_script
        @script_runner.try(&.skip)
      end

      # Modified update method
      def update(dt : Float32)
        # Update script runner if active
        @script_runner.try(&.update(dt))

        # Clear completed script runner
        if runner = @script_runner
          if runner.completed
            @script_runner = nil
          end
        end

        # ... existing update code ...
      end

      # Modified draw method
      def draw(camera : Graphics::Camera? = nil)
        # ... existing draw code ...

        # Draw script overlays
        @script_runner.try(&.draw)
      end
    end
  end
end
```

---

## 4. Migration Strategy

### 4.1 Backwards Compatibility Layer

```crystal
# src/cutscenes/cutscene_compat.cr
# Thin wrapper for existing code that uses CutsceneManager

module PointClickEngine
  module Cutscenes
    # Legacy compatibility - wraps new ActionRunner
    class LegacyCutscene
      def initialize(@name : String)
        @runner = Actions::ActionRunner.new(@name, Core::Engine.instance)
      end

      # DSL methods that add to runner
      def wait(duration : Float32)
        @runner.add(Actions::ActionData.new("wait", duration: duration))
      end

      def dialog(character : Characters::Character, text : String, duration : Float32 = 0.0f32)
        @runner.add(Actions::ActionData.new("dialog", {
          "character" => YAML::Any.new(character.name),
          "text" => YAML::Any.new(text)
        }, duration))
      end

      # ... other legacy DSL methods ...

      def to_runner : Actions::ActionRunner
        @runner
      end
    end

    # Legacy CutsceneManager compatibility
    class CutsceneManagerCompat
      @runners : Hash(String, Actions::ActionRunner) = {} of String => Actions::ActionRunner
      @current : Actions::ActionRunner?

      def add_cutscene(runner : Actions::ActionRunner)
        @runners[runner.name] = runner
      end

      def play_cutscene(name : String, on_complete : Proc(Nil)? = nil) : Bool
        if runner = @runners[name]?
          @current = runner
          runner.on_complete = on_complete
          runner.play
          true
        else
          false
        end
      end

      def is_playing? : Bool
        @current.try(&.running) || false
      end

      def update(dt : Float32)
        @current.try(&.update(dt))
        if @current.try(&.completed)
          @current = nil
        end
      end

      def draw
        @current.try(&.draw)
      end
    end
  end
end
```

### 4.2 Migration Phases

| Phase | Duration | Focus |
|-------|----------|-------|
| 1 | Week 1 | Create new `src/actions/` structure alongside existing |
| 2 | Week 2 | Implement ActionExecutor with core action types |
| 3 | Week 3 | Add Scene integration, test with simple sequences |
| 4 | Week 4 | Create compatibility layer, migrate existing cutscenes |
| 5 | Week 5 | Remove old cutscene system, cleanup |

---

## 5. Implementation Phases

### Phase 1: Foundation - COMPLETED

All files created, 34 tests passing.

### Phase 2: Core Executor - COMPLETED

ActionExecutor with 40+ action types, 46 tests passing.

### Phase 3: Scene Integration - COMPLETED

Scene integration with ActionRunner, 62 tests passing. Added `script_runner` property, `run_script()`, `run_script_file()`, `script_running?`, `stop_script()`, `skip_script()` methods to Scene. Also added `ActionLoader` class for YAML parsing.

### Phase 4: YAML Loader - COMPLETED

ActionLoader enhanced with variables, conditions (delegating to GameStateManager), and checkpoints support. 62 tests passing.

### Phase 5: Compatibility Layer - COMPLETED

Created `ActionRunnerAdapter` to wrap ActionRunner with Cutscene interface. Extended CutsceneManager with `play_action_sequence()`, `add_action_sequence()`, `load_action_file()`. Added `CutsceneFactory` for DSL creation. 54 cutscene tests passing.

### Phase 6: Cleanup & Deprecation - COMPLETED

Marked all legacy cutscene files with deprecation notices:
- `cutscene.cr` - Use ActionRunner
- `cutscene_action.cr` - Use ActionData + ActionExecutor
- `cutscene_loader.cr` - Use ActionLoader
- `cutscene_manager.cr` - Partial deprecation, use new methods
- `cutscene_camera.cr` - Camera actions in ActionExecutor

Added ActionExecutor optimizations:
- Custom action handler registry for extensibility (O(1) lookup)
- `register_action()` / `unregister_action()` for game-specific actions
- Handler type aliases for type safety

116 tests passing (62 action + 54 cutscene).

---

## 6. YAML Format Evolution

### 6.1 Current Format (Preserved)

```yaml
name: "ending_sequence"
skippable: true
actions:
  - type: fade_in
    duration: 2.0
    color: [0, 0, 0, 255]
  - type: character_move
    character: "player"
    target: {x: 400, y: 300}
  - type: floating_dialog
    character: "Detective"
    text: "The mystery is solved!"
    duration: 3.0
```

The new system parses this **exactly as before** - no changes to existing YAML files required.

### 6.2 New Features (Optional)

```yaml
name: "advanced_sequence"
skippable: true

# NEW: Variables for reuse
variables:
  fountain_pos: {x: 500, y: 350}

actions:
  - type: fade_in
    duration: 1.0

  # NEW: Parallel block
  - type: parallel
    actions:
      - type: character_move
        character: "alice"
        to: {x: 300, y: 400}
      - type: character_move
        character: "bob"
        to: {x: 500, y: 400}
      - type: camera_pan
        to: $fountain_pos  # Variable reference
        duration: 2.0

  # NEW: Conditional (future)
  - type: conditional
    condition: "has_flag:found_clue"
    then:
      - type: dialog
        character: "player"
        text: "I found the clue!"
    else:
      - type: dialog
        character: "player"
        text: "I should search more."

  # NEW: Loop (future)
  - type: loop
    count: 3
    actions:
      - type: screen_flash
        duration: 0.1
      - type: wait
        duration: 0.2
```

### 6.3 DSL Comparison

**Old DSL:**
```crystal
cutscene = Cutscene.new("intro")
cutscene.fade_in(1.0)
cutscene.move_character(player, target_pos)
cutscene.dialog(player, "Hello!")
cutscene.parallel do
  move_character(alice, pos1)
  move_character(bob, pos2)
end
```

**New DSL:**
```crystal
runner = Actions::ActionRunner.new("intro", engine)
runner.add(Actions::ActionData.new("fade_in", duration: 1.0f32))
runner.add(Actions::ActionData.new("character_move", {
  "character" => "player",
  "to" => {x: target_pos.x, y: target_pos.y}
}))

# Or use builder pattern
runner = Actions::DSL.build("intro", engine) do
  fade_in 1.0
  move "player", to: {x: 400, y: 300}
  say "player", "Hello!"
  parallel do
    move "alice", to: pos1
    move "bob", to: pos2
  end
end
```

---

## 7. Integration Points

### 7.1 Engine Integration

```crystal
# src/core/engine.cr changes

class Engine
  # Keep for compatibility
  property cutscene_manager : Cutscenes::CutsceneManagerCompat?

  def initialize
    # ... existing init ...
    @cutscene_manager = Cutscenes::CutsceneManagerCompat.new
  end

  def update(dt)
    # ... existing updates ...

    # Update via scene's script runner (new way)
    @current_scene.try(&.update(dt))

    # Or via compat manager (legacy way)
    @cutscene_manager.try(&.update(dt))
  end

  def draw
    # ... existing draws ...

    # Draw scene (includes script overlays)
    @current_scene.try(&.draw(@camera))

    # Legacy compat draws
    @cutscene_manager.try(&.draw)
  end

  # New method for running scripts
  def run_script(path : String)
    @current_scene.try(&.run_script_file(path))
  end

  def script_running? : Bool
    @current_scene.try(&.script_running?) ||
    @cutscene_manager.try(&.is_playing?) ||
    false
  end
end
```

### 7.2 EventBus Integration

Events already exist and will be published:
- `CutsceneStartedEvent` - when ActionRunner.play is called
- `CutsceneEndedEvent` - when ActionRunner completes (includes `skipped` flag)

New events (optional):
- `ActionStartedEvent` - when individual action starts
- `ActionCompletedEvent` - when individual action completes

### 7.3 Scripting (Lua) Integration

```lua
-- Existing API remains unchanged
start_cutscene("ending_sequence", function(event, skipped)
  if event == "ended" then
    show_message("Cutscene finished!")
  end
end)

-- New: Run inline action sequence
run_actions({
  {type = "fade_out", duration = 1.0},
  {type = "change_scene", target = "forest"},
  {type = "fade_in", duration = 1.0}
})

-- New: Direct action execution
execute_action("camera_shake", {intensity = 5.0, duration = 0.5})
```

### 7.4 Effect System Integration

The ActionExecutor delegates to EffectManager:

```crystal
# Camera effects
@engine.effect_manager.add_camera_effect("shake", ...)
@engine.effect_manager.add_camera_effect("pan", ...)
@engine.effect_manager.add_camera_effect("zoom", ...)

# Scene effects
@engine.effect_manager.add_scene_effect("fade", ...)
@engine.effect_manager.add_scene_effect("flash", ...)
@engine.effect_manager.add_scene_effect("rain", ...)
@engine.effect_manager.add_scene_effect("letterbox", ...)
```

This is exactly how the current CutsceneActions work - no change needed.

---

## 8. Risk Assessment & Mitigations

### 8.1 Risks

| Risk | Severity | Likelihood | Mitigation |
|------|----------|------------|------------|
| Breaking existing cutscenes | High | Medium | Compatibility layer + thorough testing |
| Performance regression | Medium | Low | Action pooling, profiling |
| Missing action types | Medium | Medium | Map all 40+ existing actions first |
| Timeline feature loss | Low | Low | Port EnhancedCutscene concepts |
| Parallel action bugs | Medium | Medium | Comprehensive unit tests |

### 8.2 Rollback Plan

1. Keep old `src/cutscenes/` intact during transition
2. Feature flag to switch between old/new systems
3. Full test coverage before removing old code
4. Git tags at each phase for easy rollback

### 8.3 Success Criteria

- [ ] All existing YAML cutscenes work unchanged
- [ ] All existing DSL code works via compat layer
- [ ] No visual differences in cutscene playback
- [ ] Line count reduced by >50% (target: ~1000 lines for new system)
- [ ] Adding new action type requires only ActionExecutor change

---

## 9. Testing Strategy

### 9.1 Unit Tests

```crystal
# spec/actions/action_spec.cr
describe Actions::ActionData do
  it "creates with type and params" do
    data = Actions::ActionData.new("wait", duration: 1.0f32)
    data.type.should eq("wait")
    data.duration.should eq(1.0f32)
  end
end

describe Actions::ActionInstance do
  it "tracks progress correctly" do
    data = Actions::ActionData.new("wait", duration: 2.0f32)
    instance = Actions::ActionInstance.new(data)
    instance.elapsed = 1.0f32
    instance.progress.should eq(0.5f32)
  end
end

# spec/actions/action_runner_spec.cr
describe Actions::ActionRunner do
  it "executes actions sequentially" do
    runner = create_test_runner
    runner.add(Actions::ActionData.new("wait", duration: 0.1f32))
    runner.add(Actions::ActionData.new("wait", duration: 0.1f32))
    runner.play

    runner.running.should be_true
    simulate_time(0.15)
    runner.current_index.should eq(1)
    simulate_time(0.1)
    runner.completed.should be_true
  end

  it "handles parallel actions" do
    runner = create_test_runner
    runner.add_parallel([
      Actions::ActionData.new("wait", duration: 0.2f32),
      Actions::ActionData.new("wait", duration: 0.1f32)
    ])
    runner.play

    simulate_time(0.25)
    runner.completed.should be_true
  end
end

# spec/actions/action_executor_spec.cr
describe Actions::ActionExecutor do
  it "executes character_move action" do
    executor = create_test_executor
    scene = create_test_scene_with_character("player")
    action = create_action("character_move", {
      "character" => "player",
      "to" => {"x" => 400, "y" => 300}
    })

    executor.start(action, scene)
    action.started.should be_true

    # Character should be walking
    scene.get_character("player").not_nil!.state.should eq(Characters::CharacterState::Walking)
  end
end
```

### 9.2 Integration Tests

```crystal
# spec/integration/cutscene_integration_spec.cr
describe "Cutscene Integration" do
  it "plays YAML cutscene correctly" do
    engine = create_test_engine
    engine.run_script("spec/fixtures/test_cutscene.yaml")

    engine.script_running?.should be_true
    simulate_frames(60)  # 1 second at 60fps
    # Verify expected state changes
  end

  it "maintains backwards compatibility" do
    # Load cutscene using old API
    cutscene = Cutscenes::CutsceneLoader.load_from_yaml("spec/fixtures/legacy_cutscene.yaml")

    # Should work via compat layer
    engine.cutscene_manager.not_nil!.add_cutscene(cutscene.to_runner)
    engine.cutscene_manager.not_nil!.play_cutscene("legacy_cutscene")

    engine.script_running?.should be_true
  end
end
```

### 9.3 Visual Regression Tests

For each existing cutscene in crystal_mystery:
1. Record screenshots at key frames with old system
2. Compare with new system output
3. Differences should be pixel-identical or intentionally improved

---

## 10. File Changes Summary

### 10.1 New Files

| File | Lines (est.) | Purpose |
|------|--------------|---------|
| `src/actions/action.cr` | ~80 | ActionData, ActionInstance |
| `src/actions/action_runner.cr` | ~200 | Sequence execution |
| `src/actions/action_executor.cr` | ~500 | All action logic |
| `src/actions/action_loader.cr` | ~150 | YAML parsing |
| `src/actions/action_dsl.cr` | ~100 | Builder DSL |
| `src/cutscenes/cutscene_compat.cr` | ~150 | Legacy compatibility |
| **Total New** | **~1180** | |

### 10.2 Modified Files

| File | Changes |
|------|---------|
| `src/scenes/scene.cr` | Add script_runner, run_script methods |
| `src/core/engine.cr` | Use compat layer, add run_script |
| `src/scripting/utility_script_api.cr` | Add run_actions, execute_action |

### 10.3 Deprecated Files (Phase 6)

| File | Lines | Status |
|------|-------|--------|
| `src/cutscenes/cutscene.cr` | 167 | Deprecated |
| `src/cutscenes/cutscene_action.cr` | 1461 | Deprecated |
| `src/cutscenes/cutscene_loader.cr` | 454 | Deprecated |
| `src/cutscenes/cutscene_manager.cr` | 265 | Deprecated |
| `src/cutscenes/cutscene_camera.cr` | ~200 | Merged into Camera |
| `src/cutscenes/cutscene_director.cr` | 386 | Deprecated (features ported) |
| **Total Deprecated** | **~2933** | |

### 10.4 Net Change

```
New code:     ~1180 lines
Deprecated:   ~2933 lines
─────────────────────────
Net reduction: ~1753 lines (60% reduction)
```

---

## Appendix A: Action Type Reference

Complete mapping from old CutsceneAction classes to new action types:

| Old Class | New Type | Status |
|-----------|----------|--------|
| WaitAction | `wait` | Core |
| FadeAction | `fade_in`, `fade_out` | Core |
| MoveCharacterAction | `character_move` | Core |
| DialogAction | `dialog` | Core |
| CharacterEnterAction | `character_enter` | Core |
| CharacterExitAction | `character_exit` | Core |
| CharacterMoveAction | `character_move` | Core |
| CharacterFaceAction | `character_face` | Core |
| CharacterAnimationAction | `character_animation` | Core |
| FloatingDialogAction | `floating_dialog` | Core |
| CameraShakeAction | `camera_shake` | Core |
| CameraPanAction | `camera_pan` | Core |
| CameraZoomAction | `camera_zoom` | Core |
| CameraFollowAction | `camera_follow` | Core |
| CameraFocusAction | `camera_focus` | Core |
| ScreenFlashAction | `screen_flash` | Core |
| ScreenEffectAction | `screen_effect` | Core |
| ParticleEffectAction | `particle_effect` | Core |
| StopParticleEffectAction | `stop_particle_effect` | Core |
| WeatherEffectAction | `weather_effect` | Core |
| ShowSpriteAction | `show_sprite` | Extended |
| HideSpriteAction | `hide_sprite` | Extended |
| MoveSpriteAction | `move_sprite` | Extended |
| ShowBackgroundAction | `show_background` | Extended |
| PlayMusicAction | `play_music` | Core |
| StopMusicAction | `stop_music` | Core |
| PlayAmbientAction | `play_ambient` | Core |
| StopAmbientAction | `stop_ambient` | Core |
| SoundEffectAction | `sound_effect` | Core |
| ShowTextAction | `show_text` | Core |
| UIVisibilityAction | `hide_ui`, `show_ui` | Core |
| LetterboxAction | `letterbox` | Core |
| EnablePlayerControlAction | `enable_player_control`, `disable_player_control` | Core |
| SetGameStateAction | `set_game_state` | Core |
| ChangeSceneAction | `change_scene` | Core |
| CallbackAction | `callback` | Core |
| ParallelAction | `parallel` (special) | Core |
| ShowCreditsAction | `show_credits` | Extended |
| ReturnToMenuAction | `return_to_menu` | Extended |

---

## Appendix B: Decision Log

| Date | Decision | Rationale |
|------|----------|-----------|
| 2024-XX-XX | Actions as data, not classes | Reduces boilerplate, easier to extend |
| 2024-XX-XX | Keep YAML format unchanged | Backwards compatibility |
| 2024-XX-XX | Scene owns script runner | Single rendering pipeline |
| 2024-XX-XX | Compat layer for legacy code | Gradual migration |

---

## Appendix C: References

- Current cutscene files: `src/cutscenes/`
- Effect system (inspiration): `src/graphics/effects/`
- Event system: `src/core/events/`
- Example cutscenes: `crystal_mystery/cutscenes/`
