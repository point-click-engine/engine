# Enhanced Preflight Validations

The Point & Click Engine now includes comprehensive preflight validations to catch potential issues before the game runs. The enhanced preflight check performs 20 different validation steps to ensure game configuration integrity, asset availability, and optimal performance.

## Validation Categories

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

## Usage

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

## Error Categories

### Critical Errors (Must Fix)
- Missing required configuration fields
- Invalid window dimensions (<640x480)
- Missing player configuration
- Invalid sprite dimensions (<=0)
- File not found errors
- Syntax errors in YAML/JSON files
- Broken scene references

### Warnings (Should Review)
- Large window resolutions
- Non-standard aspect ratios
- Missing optional features
- Large asset files
- Orphaned scenes
- Unusual configuration values
- Platform compatibility issues

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

## Benefits

1. **Early Error Detection**: Catches configuration and asset issues before runtime
2. **Performance Optimization**: Identifies potential performance bottlenecks
3. **Security Hardening**: Detects common security vulnerabilities
4. **Cross-Platform Support**: Ensures compatibility across platforms
5. **Developer Guidance**: Provides actionable feedback for issues
6. **Comprehensive Coverage**: 20 validation categories cover all major systems

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

## Integration

The enhanced preflight check integrates seamlessly with the existing engine startup:

1. Runs automatically when loading game configuration
2. Can be disabled for faster development iterations
3. Provides detailed logging for debugging
4. Supports custom validation extensions
5. Works with CI/CD pipelines for automated testing

This comprehensive validation system ensures games are properly configured and optimized before deployment, reducing runtime errors and improving player experience.