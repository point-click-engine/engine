require "./spec/spec_helper"
require "./src/core/game_constants"

# Enable verbose debugging
PointClickEngine::Core::DebugConfig.enable_verbose_logging

# Run just the failing spec
system("crystal spec spec/characters/movement_controller_spec.cr:209")
