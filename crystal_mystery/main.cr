require "../src/point_click_engine"
require "../src/core/preflight_check"

# The Crystal Mystery - Simplified with YAML configuration
class CrystalMysteryGame
  property engine : PointClickEngine::Core::Engine

  def initialize
    config_path = "crystal_mystery/game_config.yaml"

    # Run pre-flight checks first
    begin
      PointClickEngine::Core::PreflightCheck.run!(config_path)
    rescue ex : PointClickEngine::Core::ValidationError
      puts "\n❌ Game failed pre-flight checks. Please fix these issues before running."
      exit(1)
    end

    # Load entire game configuration from YAML
    config = PointClickEngine::Core::GameConfig.from_file(config_path)

    # Create engine with all settings from config
    @engine = config.create_engine

    # Register any game-specific Lua functions
    register_game_functions

    # Show main menu
    @engine.show_main_menu

    # Debug: Check if menu is visible
    if menu = @engine.system_manager.menu_system
      puts "Menu system exists"
      if menu.current_menu
        puts "Current menu: #{menu.current_menu.class}"
        puts "Menu visible: #{menu.current_menu.try(&.visible)}"
      else
        puts "No current menu set!"
      end
    else
      puts "No menu system!"
    end
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
