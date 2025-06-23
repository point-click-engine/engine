require "point_click_engine"

# Load configuration
config = PointClickEngine::Core::GameConfig.from_file("mini_game.yaml")

# Create and run game
engine = config.create_engine
engine.show_main_menu
engine.run
