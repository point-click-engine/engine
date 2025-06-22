# Game builder for simplified engine initialization
require "../engine"
require "../../game_state_manager"
require "../../quest_manager"
require "../../characters/player"
require "../../scenes/scene_loader"

module PointClickEngine
  module Core
    module EngineComponents
      # Builder pattern for simplified game initialization
      # Reduces boilerplate and provides sensible defaults
      class GameBuilder
        property engine : Engine
        property game_state_manager : GameStateManager
        property quest_manager : QuestManager
        
        @player_config : NamedTuple(name: String, sprite_path: String, frame_width: Int32, frame_height: Int32, columns: Int32, rows: Int32)?
        @scene_paths : Array(String) = [] of String
        @dialog_paths : Array(String) = [] of String
        @quest_paths : Array(String) = [] of String
        @audio_config : Hash(String, String) = {} of String => String
        @enable_features : Set(Symbol) = Set(Symbol).new
        
        def initialize(width : Int32 = 1024, height : Int32 = 768, title : String = "Adventure Game")
          @engine = Engine.new(width, height, title)
          @game_state_manager = GameStateManager.new
          @quest_manager = QuestManager.new
        end
        
        # Configure player with sensible defaults
        def with_player(name : String = "Player", 
                       sprite_path : String = "assets/sprites/player.png",
                       frame_width : Int32 = 56, 
                       frame_height : Int32 = 56,
                       columns : Int32 = 8,
                       rows : Int32 = 4) : self
          @player_config = {
            name: name,
            sprite_path: sprite_path,
            frame_width: frame_width,
            frame_height: frame_height,
            columns: columns,
            rows: rows
          }
          self
        end
        
        # Add scenes from a directory or specific files
        def with_scenes(pattern : String) : self
          @scene_paths << pattern
          self
        end
        
        # Add dialog files
        def with_dialogs(pattern : String) : self
          @dialog_paths << pattern
          self
        end
        
        # Add quest files
        def with_quests(pattern : String) : self
          @quest_paths << pattern
          self
        end
        
        # Configure audio with a hash of name => path
        def with_audio(music : Hash(String, String)? = nil, sounds : Hash(String, String)? = nil) : self
          music.try { |m| m.each { |k, v| @audio_config["music:#{k}"] = v } }
          sounds.try { |s| s.each { |k, v| @audio_config["sound:#{k}"] = v } }
          self
        end
        
        # Enable specific features
        def with_features(*features : Symbol) : self
          features.each { |f| @enable_features.add(f) }
          self
        end
        
        # Build the configured game
        def build : Engine
          # Initialize engine
          @engine.init
          
          # Enable requested features
          enable_features
          
          # Initialize all systems (they're already created by SystemManager)
          setup_systems
          
          # Configure player if specified
          setup_player
          
          # Load all assets
          load_scenes
          load_dialogs
          load_quests
          load_audio
          
          # Connect state manager and quest manager
          connect_managers
          
          # Set up default callbacks
          setup_callbacks
          
          @engine
        end
        
        private def enable_features
          @enable_features.each do |feature|
            case feature
            when :verbs
              @engine.enable_verb_input
            when :floating_dialogs
              @engine.dialog_manager.try { |dm| dm.enable_floating = true }
            when :portraits
              @engine.dialog_manager.try { |dm| dm.enable_portraits = true }
            when :shaders
              setup_default_shaders
            when :debug
              Engine.debug_mode = true
            end
          end
        end
        
        private def setup_systems
          # Configure display manager
          if dm = @engine.display_manager
            dm.scaling_mode = Graphics::DisplayManager::ScalingMode::FitWithBars
            dm.target_width = @engine.window_width
            dm.target_height = @engine.window_height
          end
          
          # Systems are already created by SystemManager, just need to configure them
          @engine.game_state_manager = @game_state_manager
          @engine.quest_manager = @quest_manager
        end
        
        private def setup_player
          return unless config = @player_config
          
          # Default position at bottom center of screen
          default_x = @engine.window_width / 2
          default_y = @engine.window_height - 150
          
          player = Characters::Player.new(
            config[:name],
            Raylib::Vector2.new(x: default_x.to_f32, y: default_y.to_f32),
            Raylib::Vector2.new(x: config[:frame_width].to_f32, y: config[:frame_height].to_f32)
          )
          
          player.load_enhanced_spritesheet(
            config[:sprite_path], 
            config[:frame_width], 
            config[:frame_height], 
            config[:columns], 
            config[:rows]
          )
          
          @engine.player = player
        end
        
        private def load_scenes
          @scene_paths.each do |pattern|
            if pattern.includes?("*") || pattern.includes?("?")
              # It's a glob pattern
              Dir.glob(pattern).each do |path|
                load_scene_file(path)
              end
            elsif File.directory?(pattern)
              # It's a directory
              Dir.glob("#{pattern}/*.yaml").each do |path|
                load_scene_file(path)
              end
            else
              # It's a specific file
              load_scene_file(pattern)
            end
          end
        end
        
        private def load_scene_file(path : String)
          return unless File.exists?(path)
          
          scene = Scenes::SceneLoader.load_from_yaml(path)
          @engine.add_scene(scene)
          puts "Loaded scene: #{scene.name} from #{path}"
        rescue ex
          puts "Error loading scene from #{path}: #{ex.message}"
        end
        
        private def load_dialogs
          # Similar pattern for dialogs when dialog loading is implemented
          @dialog_paths.each do |pattern|
            puts "Dialog loading from #{pattern} (not yet implemented)"
          end
        end
        
        private def load_quests
          @quest_paths.each do |path|
            if File.exists?(path)
              @quest_manager.load_quests_from_yaml(path)
              puts "Loaded quests from #{path}"
            end
          end
        end
        
        private def load_audio
          return unless audio = @engine.audio_manager
          
          @audio_config.each do |key, path|
            if File.exists?(path)
              if key.starts_with?("music:")
                name = key.lchop("music:")
                audio.load_music(name, path)
              elsif key.starts_with?("sound:")
                name = key.lchop("sound:")
                audio.load_sound_effect(name, path)
              end
            end
          end
        end
        
        private def connect_managers
          # Connect game state manager
          @engine.on_update = ->(dt : Float32) {
            @game_state_manager.update_timers(dt)
            @game_state_manager.update_game_time(dt)
            @quest_manager.update_all_quests(@game_state_manager, dt)
          }
          
          # Connect quest completion to events
          @game_state_manager.add_change_handler(->(name : String, value : GameValue) {
            @quest_manager.update_all_quests(@game_state_manager, 0.0f32)
          })
        end
        
        private def setup_callbacks
          # Set up new game event
          @engine.event_system.on("game:new") do
            # Clear state
            @game_state_manager.clear
            @engine.inventory.clear
            
            # Reset player position
            if player = @engine.player
              player.position = Raylib::Vector2.new(x: 200f32, y: 500f32)
            end
            
            # Start game
            @engine.start_game
          end
        end
        
        private def setup_default_shaders
          return unless shader_system = @engine.shader_system
          
          # Create common shaders
          Graphics::Shaders::ShaderHelpers.create_vignette_shader(shader_system)
          Graphics::Shaders::ShaderHelpers.create_bloom_shader(shader_system)
        end
      end
    end
  end
end