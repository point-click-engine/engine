# Validation and Error Detection System

The Point & Click Engine includes a comprehensive validation system that detects configuration and asset errors before the game runs, preventing runtime crashes and providing clear error messages.

## Overview

The validation system consists of:

1. **Custom Exception Types** - Specific error types for different loading failures
2. **Validators** - Modules that check configuration, assets, and scene files
3. **Pre-flight Check** - Comprehensive validation that runs before game starts
4. **Error Reporter** - Formatted, colorized console output for errors and warnings

## Exception Types

### LoadingError
Base class for all loading-related errors.

```crystal
raise PointClickEngine::Core::LoadingError.new("Failed to load", "file.yaml", "field_name")
```

### ConfigError
Configuration file errors (YAML syntax, invalid values, etc.)

```crystal
raise PointClickEngine::Core::ConfigError.new("Invalid window size", "game_config.yaml", "window.width")
```

### AssetError
Missing or invalid asset files.

```crystal
raise PointClickEngine::Core::AssetError.new("File not found", "sprites/player.png", "intro_scene.yaml")
```

### SceneError
Scene file validation errors.

```crystal
raise PointClickEngine::Core::SceneError.new("Invalid hotspot", "intro_scene", "hotspots[0]")
```

### ValidationError
Multiple validation errors collected together.

```crystal
errors = ["Missing field", "Invalid value", "Asset not found"]
raise PointClickEngine::Core::ValidationError.new(errors, "config.yaml")
```

### SaveGameError
Save file corruption or compatibility issues.

```crystal
raise PointClickEngine::Core::SaveGameError.new("Corrupted save data", "save1.dat")
```

## Validators

### ConfigValidator

Validates `game_config.yaml` files:

- Required fields (game title, etc.)
- Numeric ranges (window dimensions, FPS, volumes)
- Valid enum values (scaling modes, etc.)
- Asset references (start scene, music)
- Reserved names for flags/variables

```crystal
config = GameConfig.from_file("game_config.yaml")
errors = Validators::ConfigValidator.validate(config, "game_config.yaml")
```

### AssetValidator

Checks that all referenced assets exist:

- Player sprites
- Scene backgrounds
- Character sprites and portraits
- Audio files (music and sound effects)
- Validates file formats
- Checks multiple locations (filesystem, archives)

```crystal
errors = Validators::AssetValidator.validate_all_assets(config, config_path)
```

### SceneValidator

Validates scene YAML files:

- Required fields (name, background)
- Scene name matches filename
- Hotspot definitions (positions, types, actions)
- Walkable area polygons
- Exit zones and targets
- Scale zones
- Character definitions

```crystal
errors = Validators::SceneValidator.validate_scene_file("scenes/intro.yaml")
```

## Pre-flight Check System

The pre-flight check runs all validations before the game starts:

```crystal
# In your main.cr
begin
  PointClickEngine::Core::PreflightCheck.run!(config_path)
rescue ex : PointClickEngine::Core::ValidationError
  puts "Game failed pre-flight checks. Please fix these issues:"
  exit(1)
end
```

The pre-flight check:

1. Validates configuration file
2. Checks all asset files exist
3. Validates all scene files
4. Warns about common issues
5. Checks performance considerations

Output example:
```
Running pre-flight checks...
==================================================

1. Checking game configuration...
✓ Configuration loaded successfully

2. Checking game assets...
✓ All assets validated

3. Checking scene files...
✓ 5 scene(s) validated

4. Checking for common issues...
⚠️ Start scene 'missing_scene' not found in scene files

5. Checking performance considerations...
⚠️ Large assets detected (consider compression):
   - Music 'theme': 15.2 MB

==================================================
✅ All checks passed! Game is ready to run.
==================================================
```

## Error Reporter

The ErrorReporter provides formatted console output with color coding:

```crystal
# Report a loading error
ErrorReporter.report_loading_error(error, "Loading scenes")

# Report warnings
ErrorReporter.report_warning("Large asset file", "Loading assets")

# Report info
ErrorReporter.report_info("Loading game configuration...")

# Report success
ErrorReporter.report_success("All assets loaded")

# Progress indicators
ErrorReporter.report_progress("Loading scene 'intro'")
# ... do work ...
ErrorReporter.report_progress_done(true)  # or false for failure
```

## Integration Example

Here's how the validation system is integrated into a game:

```crystal
require "point_click_engine"

class MyGame
  def initialize
    config_path = "game_config.yaml"
    
    # Run pre-flight checks first
    begin
      PointClickEngine::Core::PreflightCheck.run!(config_path)
    rescue ex : PointClickEngine::Core::ValidationError
      puts "\n❌ Game failed pre-flight checks. Please fix these issues before running."
      exit(1)
    end

    # Load configuration (with validation)
    begin
      config = PointClickEngine::Core::GameConfig.from_file(config_path)
    rescue ex : PointClickEngine::Core::ConfigError
      PointClickEngine::Core::ErrorReporter.report_loading_error(ex)
      exit(1)
    rescue ex : PointClickEngine::Core::ValidationError
      PointClickEngine::Core::ErrorReporter.report_loading_error(ex)
      exit(1)
    end

    # Create engine
    @engine = config.create_engine
  end
end
```

## Common Validation Errors

### Configuration Errors
- Empty game title
- Invalid window dimensions (negative or zero)
- Invalid FPS (must be 1-300)
- Volume out of range (must be 0-1)
- Invalid scaling mode
- Reserved variable names ("true", "false", "nil", "null")

### Asset Errors
- Missing player sprite
- Missing scene backgrounds
- Missing audio files
- Unsupported file formats
- Empty asset files
- Files referenced in ZIP archives that don't exist

### Scene Errors
- Scene name doesn't match filename
- Missing required fields
- Invalid hotspot types
- Negative dimensions or positions
- Polygon with less than 3 points
- Invalid exit targets
- Scale zones with min > max

## Best Practices

1. **Run pre-flight checks early** - Add to your main.cr before creating the engine
2. **Use specific error types** - When adding new validators, use the appropriate error class
3. **Provide context** - Include filename and field information in errors
4. **Batch validations** - Collect all errors before reporting, don't fail on first error
5. **Clear error messages** - Explain what's wrong and how to fix it
6. **Performance warnings** - Warn about large files or many scenes
7. **Check common locations** - Look for assets in multiple standard directories

## Extending the System

To add new validations:

1. Create a new validator in `src/core/validators/`
2. Add validation method that returns `Array(String)` of errors
3. Include validator in pre-flight check if needed
4. Add specs in `spec/core/validators/`

Example:
```crystal
module PointClickEngine::Core::Validators
  class MyValidator
    def self.validate(data : MyData, context : String) : Array(String)
      errors = [] of String
      
      # Add validation logic
      if data.some_field.nil?
        errors << "Missing required field 'some_field'"
      end
      
      errors
    end
  end
end
```