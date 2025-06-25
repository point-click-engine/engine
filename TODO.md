# TODO

## Completed
- Fix navigation grid marking all cells as non-walkable
- Fix mismatch between walkable area coordinates and actual background size
- Debug why character still collides with desk
- Debug pathfinding trigger when movement is blocked
- Write specs for character size collision detection
- Write specs for pathfinding with obstacles
- Write specs for movement controller fixes
- Add preflight checks for scene coordinate validation
- Write comprehensive specs for navigation grid generation
- Add validation for texture dimensions vs scene coordinates
- Create specs for walkable area coordinate systems
- Search for other engine calculations wrongly based on texture sizes
- Fix camera bounds to use logical dimensions instead of texture dimensions
- Update inventory icon scaling to handle aspect ratio
- Add logical dimensions to scene YAML loading
- Re-enable character radius checking in navigation grid generation
- Fix the one failing navigation grid spec (negative coordinates)
- Update all example scenes to use logical dimensions in YAML
- Create documentation about coordinate systems and texture independence
- Add more validation for logical dimensions vs actual coordinates
- Test the game with the new navigation grid using logical dimensions
- **MAJOR REFACTORING COMPLETED**: Extracted components from all large monolithic files:
  - Engine.cr (1,559 lines) → 3 modular spec extractions
  - Character.cr (757 lines) → AnimationController, SpriteController, CharacterStateManager + specs
  - Scene.cr (722 lines) → NavigationManager, BackgroundRenderer, HotspotManager + specs
  - Menu System (718 lines) → MenuInputHandler, MenuRenderer, MenuNavigator, ConfigurationManager + specs
  - Pathfinding (701 lines) → 8 components including AStarAlgorithm, PathOptimizer, NavigationGrid + specs
  - Enhanced Preflight Check (678 lines) → ValidationResult, AssetValidationChecker, RenderingValidationChecker, PerformanceValidationChecker + orchestrator

## In Progress
- Debug character stuck after first movement (may be resolved by movement controller refactoring)

## Pending - Future Enhancements
See [REFACTORING_TODO.md](REFACTORING_TODO.md) for additional improvement opportunities.

### Documentation Updates Needed
- Update ARCHITECTURE.md to reflect new component structure
- Create COMPONENT_ARCHITECTURE.md for developer guide
- Update existing feature documentation to reference new components
- Archive outdated documentation