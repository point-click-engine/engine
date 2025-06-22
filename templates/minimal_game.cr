require "../src/point_click_engine"

# Minimal game using YAML configuration
# Just load the config and run!

# Load game configuration
config = PointClickEngine::Core::GameConfig.from_file("game_config.yaml")

# Create and configure engine from YAML
engine = config.create_engine

# Show main menu and run
engine.show_main_menu
engine.run