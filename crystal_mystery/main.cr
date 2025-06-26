require "../src/point_click_engine"

# The Crystal Mystery - Simplified with YAML configuration
class CrystalMysteryGame
  property engine : PointClickEngine::Core::Engine

  def initialize
    config_path = "crystal_mystery/game_config.yaml"

    # Load entire game configuration from YAML (includes preflight checks)
    config = PointClickEngine::Core::GameConfig.from_file(config_path)

    # Create engine with all settings from config
    @engine = config.create_engine

    # Register any game-specific Lua functions
    register_game_functions

    # Show main menu
    @engine.show_main_menu
  end

  def run
    @engine.run
  end

  private def register_game_functions
    return unless script_engine = @engine.script_engine

    # Game-specific functions would be registered here if ScriptEngine supported it
    # For now, game logic should be in Lua scripts
  end
end

# That's it! Just 3 lines to run the entire game
game = CrystalMysteryGame.new
game.run
