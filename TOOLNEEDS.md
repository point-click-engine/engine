# Tool Requirements for Point & Click Engine

This document lists external tools that would enhance the development workflow but are not part of the core engine.

## 1. Hotspot Editor Tool
**Purpose**: Visual editor for creating and editing polygon hotspots
**Features Needed**:
- Load scene background image
- Draw polygon hotspots with mouse
- Edit vertex positions
- Set hotspot properties (name, description, cursor type)
- Export to YAML format compatible with engine
- Import existing scene YAML files
- Show grid and snapping options
- Preview hotspot highlighting

**Suggested Implementation**:
- Standalone desktop app (could use Raylib for consistency)
- Web-based editor as alternative
- Save/Load project files
- Batch export for multiple scenes

## 2. Animation Editor
**Purpose**: Create and preview sprite animations
**Features Needed**:
- Import sprite sheets
- Define frame sequences
- Set frame durations
- Preview animations at different speeds
- Export animation definitions to YAML
- Support for 8-directional character animations

## 3. Dialog Tree Editor
**Purpose**: Visual editor for creating branching dialogs
**Features Needed**:
- Node-based interface
- Support for conditions and game state checks
- Preview dialog flow
- Export to engine-compatible format
- Character portrait assignment
- Voice line markers

## 4. Scene Packager
**Purpose**: Package game assets into archive format
**Features Needed**:
- Scan for all referenced assets in scenes
- Optimize images (compression, format conversion)
- Create PAK archives
- Generate asset manifest
- Handle asset dependencies

## 5. Walkable Area Mask Editor
**Purpose**: Define walkable areas and walk-behind regions
**Features Needed**:
- Paint walkable areas on scene backgrounds
- Define walk-behind mask layers
- Set character scaling zones
- Export as bitmap masks or polygon definitions
- Preview with test character

## 6. Localization Tool
**Purpose**: Manage game text translations
**Features Needed**:
- Extract all game text strings
- Translation matrix interface
- Export to locale files
- Preview text in game context
- Support for font switching per language