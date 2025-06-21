# Point & Click Game Engine
#
# A Crystal shard for creating pixel art point-and-click adventure games using raylib-cr.
# This library provides a comprehensive framework for building traditional adventure games
# with features like scene management, inventory systems, dialog trees, character AI,
# pathfinding, cutscenes, and more.
#
# ## Quick Start
#
# ```
# require "point_click_engine"
#
# # Create a new game
# game = PointClickEngine::Core::Engine.new(800, 600, "My Adventure Game")
# game.init
#
# # Create and add a scene
# scene = PointClickEngine::Scenes::Scene.new("main_room")
# scene.load_background("assets/room.png")
# game.add_scene(scene)
# game.change_scene("main_room")
#
# # Run the game
# game.run
# ```
#
# ## Main Modules
#
# - `Core` - Core engine functionality, game loop, and state management
# - `Scenes` - Scene management, hotspots, and interactive areas
# - `Characters` - Character system with AI, animation, and dialogue
# - `UI` - User interface components and dialog systems
# - `Graphics` - Rendering, animations, transitions, and visual effects
# - `Audio` - Sound effects, music, and ambient audio management
# - `Inventory` - Item management and inventory systems
# - `Scripting` - Lua scripting integration for game logic
# - `Navigation` - Pathfinding and movement systems
# - `Cutscenes` - Cinematic sequences and scripted events

require "../lib/raylib-cr/src/raylib-cr"
require "yaml"
require "json" # Required for luajit.cr compatibility (fixes JSON::Any issue)

# Alias for convenience - shorthand for Raylib module
alias RL = Raylib

# Core modules
require "./utils/yaml_converters"
require "./core/game_object"
require "./core/config_manager"
require "./core/achievement_manager"
require "./core/game_state_manager"
require "./core/quest_system"
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
require "./characters/animation"
require "./characters/ai/behavior"
require "./characters/dialogue/character_dialogue"
require "./characters/dialogue/dialog_tree"

# UI modules
require "./ui"
require "./ui/dialog_manager"
require "./ui/gui_manager"
require "./ui/floating_dialog"
require "./ui/verb_coin"
require "./ui/status_bar"
require "./ui/ui_manager"

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
require "./audio/ambient_sound_manager"
require "./audio/footstep_system"

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
  alias VerbCoin = UI::VerbCoin
  alias StatusBar = UI::StatusBar
  alias UIManager = UI::UIManager
  alias FloatingDialog = UI::FloatingDialog
  alias FloatingDialogManager = UI::FloatingDialogManager
  alias DialogStyle = UI::DialogStyle
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
  alias Direction8 = Characters::Direction8
  alias AnimationState = Characters::AnimationState
  alias AnimationController = Characters::AnimationController
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

  # Game state and quest system aliases
  alias GameStateManager = Core::GameStateManager
  alias QuestManager = Core::QuestManager
  alias Quest = Core::Quest
  alias QuestObjective = Core::QuestObjective
  alias QuestReward = Core::QuestReward
  alias GameValue = Core::GameValue
  alias ConditionResult = Core::ConditionResult

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
