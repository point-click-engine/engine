# Point & Click Game Engine
# A Crystal shard for creating pixel art point-and-click adventure games using raylib-cr

require "raylib-cr"
require "yaml"
require "json"  # Required for luajit.cr compatibility (fixes JSON::Any issue)

# Alias for convenience
alias RL = Raylib

# Core modules
require "./utils/yaml_converters"
require "./core/game_object"
require "./core/engine"

# Graphics modules
require "./graphics/display_manager"
require "./graphics/animated_sprite"
require "./graphics/particles"

# Character system modules
require "./characters/character"
require "./characters/player"
require "./characters/npc"
require "./characters/ai/behavior"
require "./characters/dialogue/character_dialogue"

# UI modules
require "./ui"

# Inventory modules
require "./inventory/inventory_item"
require "./inventory/inventory_system"

# Scene modules
require "./scenes/hotspot"
require "./scenes/scene"

# Scripting modules
require "./scripting/event_system"
require "./scripting/script_engine"
require "./characters/scriptable_character"

module PointClickEngine
  VERSION = "0.3.0"

  # Convenience aliases for backward compatibility
  alias Game = Core::Engine
  alias GameObject = Core::GameObject
  alias Drawable = Core::Drawable
  alias Character = Characters::Character
  alias Player = Characters::Player
  alias NPC = Characters::NPC
  alias Scene = Scenes::Scene
  alias Hotspot = Scenes::Hotspot
  alias Dialog = UI::Dialog
  alias InventoryItem = Inventory::InventoryItem
  alias InventoryUI = Inventory::InventorySystem
  alias AnimatedSprite = Graphics::AnimatedSprite
  alias DisplayManager = Graphics::DisplayManager
  alias ParticleSystem = Graphics::ParticleSystem
  alias Particle = Graphics::Particle

  # Character system aliases
  alias CharacterState = Characters::CharacterState
  alias Direction = Characters::Direction
  alias NPCMood = Characters::NPCMood
  alias AnimationData = Characters::AnimationData
  alias CharacterDialogue = Characters::Dialogue::CharacterDialogue

  # AI behavior aliases
  alias NPCBehavior = Characters::AI::NPCBehavior
  alias PatrolBehavior = Characters::AI::PatrolBehavior
  alias RandomWalkBehavior = Characters::AI::RandomWalkBehavior
  alias IdleBehavior = Characters::AI::IdleBehavior
  alias FollowBehavior = Characters::AI::FollowBehavior

  # Utility aliases
  alias YAMLConverters = Utils::YAMLConverters

  # Scripting system aliases
  alias ScriptEngine = Scripting::ScriptEngine
  alias EventSystem = Scripting::EventSystem
  alias Event = Scripting::Event
  alias EventHandler = Scripting::EventHandler
  alias ScriptEventHandler = Scripting::ScriptEventHandler
  alias FunctionEventHandler = Scripting::FunctionEventHandler
  alias ScriptableCharacter = Characters::ScriptableCharacter
  alias SimpleNPC = Characters::SimpleNPC
end