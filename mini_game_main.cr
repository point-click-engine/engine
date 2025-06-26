require "point_click_engine"
config = PointClickEngine::Core::GameConfig.from_file("mini_game.yaml")
engine = config.create_engine
engine.run