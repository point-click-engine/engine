# Point & Click Game Engine
# A Crystal shard for creating pixel art point-and-click adventure games using raylib-cr

require "../lib/raylib-cr/src/raylib-cr"
require "yaml"
require "json" # Required for luajit.cr compatibility (fixes JSON::Any issue)

# Alias for convenience
alias RL = Raylib

# Core modules
require "./utils/yaml_converters"
require "./core/game_object"
require "./core/config_manager"
require "./core/achievement_manager"
require "./core/engine"

# Graphics modules
require "./graphics/display_manager"
require "./graphics/animated_sprite"
require "./graphics/particles"
require "./graphics/transitions"
require "./graphics/shaders/shader_system"
require "./graphics/shaders/shader_helpers"

# Character system modules
require "./characters/character"
require "./characters/player"
require "./characters/npc"
require "./characters/ai/behavior"
require "./characters/dialogue/character_dialogue"
require "./characters/dialogue/dialog_tree"

# UI modules
require "./ui"
require "./ui/dialog_manager"
require "./ui/gui_manager"

# Inventory modules
require "./inventory/inventory_item"
require "./inventory/inventory_system"

# Scene modules
require "./scenes/hotspot"
require "./scenes/polygon_hotspot"
require "./scenes/exit_zone"
require "./scenes/walkable_area"
require "./scenes/scene"
require "./scenes/scene_loader"

# Scripting modules
require "./scripting/event_system"
require "./scripting/script_engine"
require "./characters/scriptable_character"

# Core system modules
require "./core/save_system"

# Audio modules (optional - only if audio is enabled)
require "./audio/sound_system"

# Asset management modules
require "./assets/asset_manager"
require "./assets/asset_loader"

# Navigation modules
require "./navigation/pathfinding"

# Cutscene modules
require "./cutscenes/cutscene_action"
require "./cutscenes/cutscene"
require "./cutscenes/cutscene_manager"

# Localization modules
require "./localization/locale"
require "./localization/translation"
require "./localization/localization_manager"

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
  alias PolygonHotspot = Scenes::PolygonHotspot
  alias ExitZone = Scenes::ExitZone
  alias TransitionType = Scenes::TransitionType
  alias EdgeExit = Scenes::EdgeExit
  alias WalkableArea = Scenes::WalkableArea
  alias PolygonRegion = Scenes::PolygonRegion
  alias WalkBehindRegion = Scenes::WalkBehindRegion
  alias ScaleZone = Scenes::ScaleZone
  alias Dialog = UI::Dialog
  alias InventoryItem = Inventory::InventoryItem
  alias InventoryUI = Inventory::InventorySystem
  alias AnimatedSprite = Graphics::AnimatedSprite
  alias DisplayManager = Graphics::DisplayManager
  alias ParticleSystem = Graphics::ParticleSystem
  alias Particle = Graphics::Particle
  alias TransitionManager = Graphics::TransitionManager
  alias TransitionEffect = Graphics::TransitionEffect
  alias ShaderSystem = Graphics::Shaders::ShaderSystem
  alias ShaderHelpers = Graphics::Shaders::ShaderHelpers

  # Character system aliases
  alias CharacterState = Characters::CharacterState
  alias Direction = Characters::Direction
  alias NPCMood = Characters::NPCMood
  alias AnimationData = Characters::AnimationData
  alias CharacterDialogue = Characters::Dialogue::CharacterDialogue
  alias DialogTree = Characters::Dialogue::DialogTree
  alias DialogNode = Characters::Dialogue::DialogNode
  alias DialogChoice = Characters::Dialogue::DialogChoice

  # AI behavior aliases
  alias NPCBehavior = Characters::AI::NPCBehavior
  alias PatrolBehavior = Characters::AI::PatrolBehavior
  alias RandomWalkBehavior = Characters::AI::RandomWalkBehavior
  alias IdleBehavior = Characters::AI::IdleBehavior
  alias FollowBehavior = Characters::AI::FollowBehavior

  # Utility aliases
  alias YAMLConverters = Utils::YAMLConverters

  # Audio system aliases
  alias AudioManager = Audio::AudioManager
  alias SoundEffect = Audio::SoundEffect
  alias Music = Audio::Music

  # Save system aliases
  alias SaveSystem = Core::SaveSystem
  alias SaveData = Core::SaveData

  # Scripting system aliases
  alias ScriptEngine = Scripting::ScriptEngine
  alias EventSystem = Scripting::EventSystem
  alias Event = Scripting::Event
  alias EventHandler = Scripting::EventHandler
  alias ScriptEventHandler = Scripting::ScriptEventHandler
  alias FunctionEventHandler = Scripting::FunctionEventHandler
  alias ScriptableCharacter = Characters::ScriptableCharacter
  alias SimpleNPC = Characters::SimpleNPC

  # Navigation aliases
  alias Pathfinding = Navigation::Pathfinding
  alias NavigationGrid = Navigation::Pathfinding::NavigationGrid

  # Cutscene aliases
  alias Cutscene = Cutscenes::Cutscene
  alias CutsceneManager = Cutscenes::CutsceneManager
  alias CutsceneAction = Cutscenes::CutsceneAction
  alias MoveCharacterAction = Cutscenes::MoveCharacterAction
  alias DialogAction = Cutscenes::DialogAction
  alias WaitAction = Cutscenes::WaitAction
  alias FadeAction = Cutscenes::FadeAction
  alias ChangeSceneAction = Cutscenes::ChangeSceneAction
  alias PlayAnimationAction = Cutscenes::PlayAnimationAction
  alias CameraAction = Cutscenes::CameraAction
  alias CallbackAction = Cutscenes::CallbackAction
  alias UIVisibilityAction = Cutscenes::UIVisibilityAction
  alias ParallelAction = Cutscenes::ParallelAction

  # Localization aliases
  alias Locale = Localization::Locale
  alias Translation = Localization::Translation
  alias LocalizationManager = Localization::LocalizationManager
end
