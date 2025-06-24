# Validation and Error Detection System

The Point & Click Engine includes a comprehensive validation system that detects configuration and asset errors before the game runs, preventing runtime crashes and providing clear error messages.

## Overview

The validation system consists of:

1. **Custom Exception Types** - Specific error types for different loading failures
2. **Validators** - Modules that check configuration, assets, and scene files
3. **Pre-flight Check** - Comprehensive validation that runs before game starts
4. **Enhanced Pre-flight Check** - Extended 20-category validation system
5. **Error Reporter** - Formatted, colorized console output for errors and warnings

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

## Enhanced Pre-flight Check - 20 Validation Categories

The enhanced preflight check performs comprehensive validation across 20 different categories to ensure game configuration integrity, asset availability, and optimal performance.

### 1. Configuration Validation
- **Game Info**: Validates title and version fields
- **Window Settings**: Checks resolution (min 640x480, warns if >1920x1080)
- **Aspect Ratio**: Warns about unusual aspect ratios (validates against 4:3, 16:9, 16:10, 21:9)
- **Feature Conflicts**: Detects conflicting features (e.g., shaders + low_end_mode)

### 2. Asset Validation
- **File Existence**: Verifies all referenced assets exist
- **Format Validation**: 
  - Audio: Supports .ogg, .wav, .mp3, .flac
  - Images: Validates .png, .jpg, .jpeg, .bmp
- **File Size Warnings**:
  - Music files > 10MB
  - Sound effects > 2MB
  - Backgrounds > 10MB
  - Total assets > 100MB

### 3. Scene Validation
- **Scene Files**: Validates all scene YAML files
- **Background Images**: Checks if backgrounds exist and warns about missing ones
- **Scene References**: Validates exit zones point to existing scenes
- **Orphaned Scenes**: Detects unreachable scenes
- **Scale Values**: Warns about unusual scene scale values (<=0 or >10)

### 4. Player Configuration
- **Sprite Validation**:
  - Checks sprite file exists
  - Validates dimensions (warns if >256x256)
  - Warns about excessive frames (>100)
- **Starting Position**: Ensures non-negative coordinates
- **Missing Player**: Errors if no player configuration found

### 5. Audio System
- **Format Support**: Validates audio file formats
- **Duplicate Names**: Detects duplicate audio entries
- **Start Music**: Validates start music exists in configuration
- **Volume Settings**: Checks master volume range (0.0-1.0)

### 6. Input Controls
- **Feature Flags**: Checks for custom_controls feature
- **Default System**: Confirms default input system availability

### 7. Save System
- **Directory Permissions**: Checks save directory is writable
- **Auto-Save**: Validates auto-save configuration
- **Feature Flags**: Checks save_system feature

### 8. Localization
- **Locale Files**: Validates locale files exist when enabled
- **Directory Structure**: Checks locales directory
- **File Formats**: Supports .json, .yaml, .yml

### 9. Cross-Scene References
- **Exit Zones**: Validates all target scenes exist
- **Scene Graph**: Builds reference graph
- **Unreachable Detection**: Finds orphaned scenes
- **Start Scene**: Validates start scene exists

### 10. Resource Usage
- **Texture Count**: Warns if >100 textures
- **Sound Count**: Warns if >50 sounds
- **Memory Estimation**: Estimates memory usage
- **Performance Impact**: Provides performance hints

### 11. Platform Compatibility
- **Platform Detection**: Identifies current platform
- **Feature Compatibility**: Warns about platform-specific features
- **DirectX Check**: Warns if DirectX enabled on non-Windows

### 12. Security Scanning
- **Sensitive Data**: Detects potential secrets in config:
  - API keys
  - Passwords
  - Tokens
  - Private keys
- **Script Safety**: Checks for unsafe operations in scripts:
  - system() calls
  - exec() calls
  - eval() usage
- **File Permissions**: Validates sensitive directory access

### 13. Animation Validation
- **Frame Rates**: Validates animation frame rates (>0, warns if >60)
- **Sprite Info**: Checks sprite animation configurations
- **8-Direction Support**: Validates directional animations

### 14. Dialog System
- **Dialog Files**: Validates dialog file syntax
- **Format Support**: Checks YAML/JSON validity
- **Feature Flag**: Ensures dialog_system feature when using dialogs

### 15. Quest System
- **Quest File**: Validates quests.yaml when enabled
- **Syntax Check**: Ensures valid YAML format
- **Feature Flag**: Checks quest_system feature

### 16. Inventory System
- **Items File**: Validates items.yaml configuration
- **Item Count**: Warns if >100 items (UI impact)
- **Feature Flag**: Checks inventory feature

### 17. Archive Integrity
- **Archive Files**: Detects .zip, .pak, .dat files
- **Size Warnings**: Warns about archives >100MB
- **Mount Points**: Validates archive mount configurations

### 18. Development Environment
- **Crystal Version**: Reports Crystal compiler version
- **Required Tools**: Checks for git, make
- **System Resources**: Validates available resources

### 19. Performance Analysis
- **Scene Count**: Warns if >50 scenes
- **Asset Sizes**: Tracks large assets
- **Memory Usage**: Estimates total memory footprint
- **Loading Time**: Predicts impact on load times

### 20. Comprehensive Summary
- **Error Count**: Critical issues that must be fixed
- **Warning Count**: Potential issues to review
- **Info Messages**: Helpful confirmations
- **Performance Hints**: Optimization suggestions
- **Security Issues**: Security-related concerns

## Enhanced Check Usage

### Basic Usage
```crystal
result = PointClickEngine::Core::EnhancedPreflightCheck.run("game.yaml")

if result.passed
  puts "All checks passed!"
else
  puts "Found #{result.errors.size} errors"
  result.errors.each { |e| puts "ERROR: #{e}" }
end
```

### With Exception on Failure
```crystal
# Raises ValidationError if checks fail
PointClickEngine::Core::EnhancedPreflightCheck.run!("game.yaml")
```

### Check Result Structure
```crystal
struct CheckResult
  property passed : Bool                    # Overall pass/fail
  property errors : Array(String)           # Critical errors
  property warnings : Array(String)         # Non-critical warnings
  property info : Array(String)             # Informational messages
  property performance_hints : Array(String) # Performance suggestions
  property security_issues : Array(String)   # Security concerns
end
```

## Integration Example

Here's how the validation system is integrated into a game:

```crystal
require "point_click_engine"

class MyGame
  def initialize
    config_path = "game_config.yaml"
    
    # Run enhanced pre-flight checks first
    begin
      PointClickEngine::Core::EnhancedPreflightCheck.run!(config_path)
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

## Example Output

```
Running comprehensive pre-flight checks...
============================================================

1. Checking game configuration...
✓ Configuration loaded successfully

2. Checking game assets...
✓ All assets validated

...

⚡ Performance Hints:
   High texture count (125) - consider texture atlases
   Total asset size is 156.3 MB - may affect initial loading time

⚠️  Warnings:
   Window size (2560x1440) is larger than 1920x1080 - may cause performance issues
   Scene 'secret_room' is potentially unreachable

❌ Errors:
   Player sprite not found: sprites/player.png
   Scene 'level2' references non-existent scene: 'level3'

============================================================
❌ Pre-flight checks failed with 2 error(s).
   Please fix the errors before running the game.
============================================================
```

## Error Categories

### Critical Errors (Must Fix)
- Missing required configuration fields
- Invalid window dimensions (<640x480)
- Missing player configuration
- Invalid sprite dimensions (<=0)
- File not found errors
- Syntax errors in YAML/JSON files
- Broken scene references
- Empty game title
- Negative or zero FPS
- Volume out of range (must be 0-1)
- Reserved variable names ("true", "false", "nil", "null")

### Warnings (Should Review)
- Large window resolutions
- Non-standard aspect ratios
- Missing optional features
- Large asset files
- Orphaned scenes
- Unusual configuration values
- Platform compatibility issues
- Unusual scene scale values (<=0 or >10)
- Sprite dimensions >256x256
- More than 100 animation frames

### Performance Hints
- High texture counts
- Large total asset size
- Many scenes or sounds
- Memory usage estimates
- Optimization suggestions

### Security Issues
- Exposed sensitive data
- Unsafe script operations
- Insecure file permissions
- Potential vulnerabilities

## Best Practices

1. **Run pre-flight checks early** - Add to your main.cr before creating the engine
2. **Use specific error types** - When adding new validators, use the appropriate error class
3. **Provide context** - Include filename and field information in errors
4. **Batch validations** - Collect all errors before reporting, don't fail on first error
5. **Clear error messages** - Explain what's wrong and how to fix it
6. **Performance warnings** - Warn about large files or many scenes
7. **Check common locations** - Look for assets in multiple standard directories
8. **Use enhanced checks for production** - Leverage the 20-category system for comprehensive validation

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

## Benefits

1. **Early Error Detection**: Catches configuration and asset issues before runtime
2. **Performance Optimization**: Identifies potential performance bottlenecks
3. **Security Hardening**: Detects common security vulnerabilities
4. **Cross-Platform Support**: Ensures compatibility across platforms
5. **Developer Guidance**: Provides actionable feedback for issues
6. **Comprehensive Coverage**: 20 validation categories cover all major systems
7. **Production Ready**: Enhanced validation ensures games are properly configured

## Integration with CI/CD

The validation system works seamlessly with CI/CD pipelines:

1. Runs automatically when loading game configuration
2. Can be disabled for faster development iterations
3. Provides detailed logging for debugging
4. Supports custom validation extensions
5. Returns appropriate exit codes for automation

This comprehensive validation system ensures games are properly configured and optimized before deployment, reducing runtime errors and improving player experience.