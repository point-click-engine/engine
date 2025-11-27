# Concrete game event types for the EventBus
#
# These are type-safe alternatives to the string-based events in Scripting::Events

require "./game_event"
require "raylib-cr"

module PointClickEngine
  module Core
    module Events
      # ===================
      # Scene Events
      # ===================

      # Fired when a scene transition begins
      class SceneTransitionStartEvent < GameEvent
        define_event_type "scene:transition:start"

        getter from_scene : String?
        getter to_scene : String
        getter transition_type : String?

        def initialize(@to_scene : String, @from_scene : String? = nil, @transition_type : String? = nil)
          super()
        end
      end

      # Fired when entering a new scene
      class SceneEnteredEvent < GameEvent
        define_event_type "scene:entered"

        getter scene_name : String
        getter previous_scene : String?

        def initialize(@scene_name : String, @previous_scene : String? = nil)
          super()
        end
      end

      # Fired when exiting a scene
      class SceneExitedEvent < GameEvent
        define_event_type "scene:exited"

        getter scene_name : String

        def initialize(@scene_name : String)
          super()
        end
      end

      # Fired when a hotspot is clicked
      class HotspotClickedEvent < GameEvent
        define_event_type "scene:hotspot:clicked"

        getter hotspot_name : String
        getter verb : String
        getter position : Raylib::Vector2

        def initialize(@hotspot_name : String, @verb : String, @position : Raylib::Vector2)
          super()
        end
      end

      # Fired when hovering over a hotspot
      class HotspotHoveredEvent < GameEvent
        define_event_type "scene:hotspot:hovered"

        getter hotspot_name : String
        getter position : Raylib::Vector2

        def initialize(@hotspot_name : String, @position : Raylib::Vector2)
          super()
        end
      end

      # ===================
      # Character Events
      # ===================

      # Fired when a character starts moving
      class CharacterMoveStartEvent < GameEvent
        define_event_type "character:move:start"

        getter character_name : String
        getter from_position : Raylib::Vector2
        getter to_position : Raylib::Vector2

        def initialize(@character_name : String, @from_position : Raylib::Vector2, @to_position : Raylib::Vector2)
          super()
        end
      end

      # Fired when a character reaches their destination
      class CharacterReachedTargetEvent < GameEvent
        define_event_type "character:move:complete"

        getter character_name : String
        getter position : Raylib::Vector2

        def initialize(@character_name : String, @position : Raylib::Vector2)
          super()
        end
      end

      # Fired when a character speaks
      class CharacterSpeakEvent < GameEvent
        define_event_type "character:speak"

        getter character_name : String
        getter text : String
        getter duration : Float32?

        def initialize(@character_name : String, @text : String, @duration : Float32? = nil)
          super()
        end
      end

      # Fired when a character finishes speaking
      class CharacterSpeakEndEvent < GameEvent
        define_event_type "character:speak:end"

        getter character_name : String

        def initialize(@character_name : String)
          super()
        end
      end

      # Fired when an animation completes
      class AnimationCompleteEvent < GameEvent
        define_event_type "character:animation:complete"

        getter character_name : String
        getter animation_name : String

        def initialize(@character_name : String, @animation_name : String)
          super()
        end
      end

      # ===================
      # Inventory Events
      # ===================

      # Fired when an item is added to inventory
      class ItemAddedEvent < GameEvent
        define_event_type "inventory:item:added"

        getter item_id : String
        getter item_name : String
        getter quantity : Int32

        def initialize(@item_id : String, @item_name : String = "", @quantity : Int32 = 1)
          super()
        end
      end

      # Fired when an item is removed from inventory
      class ItemRemovedEvent < GameEvent
        define_event_type "inventory:item:removed"

        getter item_id : String
        getter quantity : Int32

        def initialize(@item_id : String, @quantity : Int32 = 1)
          super()
        end
      end

      # Fired when an item is selected
      class ItemSelectedEvent < GameEvent
        define_event_type "inventory:item:selected"

        getter item_id : String

        def initialize(@item_id : String)
          super()
        end
      end

      # Fired when an item is used
      class ItemUsedEvent < GameEvent
        define_event_type "inventory:item:used"

        getter item_id : String
        getter target : String?
        getter success : Bool

        def initialize(@item_id : String, @target : String? = nil, @success : Bool = true)
          super()
        end
      end

      # Fired when combining two items
      class ItemCombinedEvent < GameEvent
        define_event_type "inventory:item:combined"

        getter item1_id : String
        getter item2_id : String
        getter result_id : String?
        getter success : Bool

        def initialize(@item1_id : String, @item2_id : String, @result_id : String? = nil, @success : Bool = true)
          super()
        end
      end

      # ===================
      # Dialog Events
      # ===================

      # Fired when a dialog starts
      class DialogStartedEvent < GameEvent
        define_event_type "dialog:started"

        getter dialog_id : String
        getter character : String?

        def initialize(@dialog_id : String, @character : String? = nil)
          super()
        end
      end

      # Fired when a dialog ends
      class DialogEndedEvent < GameEvent
        define_event_type "dialog:ended"

        getter dialog_id : String

        def initialize(@dialog_id : String)
          super()
        end
      end

      # Fired when a dialog choice is selected
      class DialogChoiceSelectedEvent < GameEvent
        define_event_type "dialog:choice:selected"

        getter dialog_id : String
        getter choice_index : Int32
        getter choice_text : String

        def initialize(@dialog_id : String, @choice_index : Int32, @choice_text : String = "")
          super()
        end
      end

      # Fired when showing dialog text
      class DialogTextEvent < GameEvent
        define_event_type "dialog:text"

        getter text : String
        getter speaker : String?

        def initialize(@text : String, @speaker : String? = nil)
          super()
        end
      end

      # ===================
      # Game State Events
      # ===================

      # Fired when the game starts
      class GameStartedEvent < GameEvent
        define_event_type "game:started"

        getter new_game : Bool

        def initialize(@new_game : Bool = true)
          super()
        end
      end

      # Fired when the game is paused
      class GamePausedEvent < GameEvent
        define_event_type "game:paused"

        def initialize
          super()
        end
      end

      # Fired when the game is resumed
      class GameResumedEvent < GameEvent
        define_event_type "game:resumed"

        def initialize
          super()
        end
      end

      # Fired when the game is saved
      class GameSavedEvent < GameEvent
        define_event_type "game:saved"

        getter slot : Int32
        getter save_name : String?

        def initialize(@slot : Int32, @save_name : String? = nil)
          super()
        end
      end

      # Fired when a game is loaded
      class GameLoadedEvent < GameEvent
        define_event_type "game:loaded"

        getter slot : Int32

        def initialize(@slot : Int32)
          super()
        end
      end

      # Fired when a game state flag changes
      class GameStateChangedEvent < GameEvent
        define_event_type "game:state:changed"

        getter key : String
        getter old_value : Bool?
        getter new_value : Bool

        def initialize(@key : String, @new_value : Bool, @old_value : Bool? = nil)
          super()
        end
      end

      # Fired when a game variable changes
      class GameVariableChangedEvent < GameEvent
        define_event_type "game:variable:changed"

        getter key : String
        getter old_value : Int32?
        getter new_value : Int32

        def initialize(@key : String, @new_value : Int32, @old_value : Int32? = nil)
          super()
        end
      end

      # ===================
      # Audio Events
      # ===================

      # Fired when music starts playing
      class MusicStartedEvent < GameEvent
        define_event_type "audio:music:started"

        getter track_name : String
        getter looping : Bool

        def initialize(@track_name : String, @looping : Bool = true)
          super()
        end
      end

      # Fired when music stops
      class MusicStoppedEvent < GameEvent
        define_event_type "audio:music:stopped"

        getter track_name : String

        def initialize(@track_name : String)
          super()
        end
      end

      # Fired when a sound effect plays
      class SoundPlayedEvent < GameEvent
        define_event_type "audio:sound:played"

        getter sound_name : String
        getter volume : Float32

        def initialize(@sound_name : String, @volume : Float32 = 1.0_f32)
          super()
        end
      end

      # ===================
      # Input Events
      # ===================

      # Fired when the user clicks in the game world
      class WorldClickEvent < GameEvent
        define_event_type "input:world:click"

        getter position : Raylib::Vector2
        getter button : Int32

        def initialize(@position : Raylib::Vector2, @button : Int32 = 0)
          super()
        end
      end

      # Fired when a verb is selected
      class VerbSelectedEvent < GameEvent
        define_event_type "input:verb:selected"

        getter verb : String

        def initialize(@verb : String)
          super()
        end
      end

      # ===================
      # Achievement Events
      # ===================

      # Fired when an achievement is unlocked
      class AchievementUnlockedEvent < GameEvent
        define_event_type "achievement:unlocked"

        getter achievement_id : String
        getter achievement_name : String

        def initialize(@achievement_id : String, @achievement_name : String = "")
          super()
        end
      end

      # ===================
      # Custom Events
      # ===================

      # Generic custom event for scripts and user-defined events
      class CustomEvent < GameEvent
        define_event_type "custom"

        getter custom_type : String
        getter data : Hash(String, String)

        def initialize(@custom_type : String, @data : Hash(String, String) = {} of String => String)
          super()
        end

        def get_string(key : String) : String
          @data[key]? || ""
        end

        def get_float(key : String) : Float32
          @data[key]?.try(&.to_f32) || 0.0_f32
        end

        def get_int(key : String) : Int32
          @data[key]?.try(&.to_i32) || 0
        end

        def get_bool(key : String) : Bool
          @data[key]? == "true"
        end
      end
    end
  end
end
