## Implementation Checklist - REMAINING WORK ONLY

### Files to CREATE (OPTIONAL/LOW PRIORITY)
| File | Purpose | Status |
|------|---------|--------|
| `src/graphics/effects/effect_factory_base.cr` | Unified effect factory | **NOT CREATED** |
| `schemas/*.schema.json` | YAML autocomplete (4 files) | **NOT CREATED** |

### Files NOT NEEDED (Verified)
| File | Reason |
|------|--------|
| `src/ui/ui_helpers.cr` | Already in `Graphics::Core::Camera` and `Viewport` |
| `src/ui/menu_items.cr` | String-based menus more flexible for localization |
| `src/characters/animation_names.cr` | `CharacterState` enum already provides this |


---

## Completed Work

### EventBus Migration - DONE
- ✅ `src/core/quest_system.cr` - Added EventBus, publishes QuestStartedEvent/QuestCompletedEvent
- ✅ `src/scenes/scene.cr` - No changes needed (handled by SceneManager)
- ✅ `src/audio/volume_controller.cr` - Replaced callbacks with VolumeChangedEvent
- ✅ `src/localization/localization_manager.cr` - Added LocaleChangedEvent
- ✅ `src/graphics/sprites/animated_sprite.cr` - No changes needed (local callbacks appropriate)

### Singleton Removal - DONE
- ✅ `src/localization/localization_manager.cr` - Removed @@instance singleton

### Code Quality - DONE
- ✅ `src/assets/asset_manager.cr` - Added selective cache clearing (clear_cache_prefix, clear_cache_entry)
- ✅ `src/assets/asset_loader.cr` - Extracted duplicate temp file pattern into `with_temp_file` helper
- ✅ `src/audio/ambient_sound_manager.cr` - Uses SpatialAudio.calculate_volume_factor
- ✅ `src/audio/footstep_system.cr` - N/A (calculates movement distance, not listener distance)

### Legacy Event System Removal - DONE
- ✅ Deleted `src/scripting/event_system.cr`
- ✅ Renamed `src/scripting/game_state_manager.cr` to `src/scripting/lua_state_manager.cr`
- ✅ Updated all references to use EventBus instead of legacy EventSystem

---

## Remaining Work

### Phase 5: Code Quality (LOW PRIORITY)
1. Verify asset_loader.cr temp file pattern

### Phase 6: Testing & Polish
1. Run specs to verify all changes compile and pass

### Optional (LOW PRIORITY)
1. Create helper files (ui_helpers, menu_items, animation_names)
2. Create effect_factory_base
3. Create JSON schemas for YAML autocomplete
