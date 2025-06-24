# Point & Click Engine Schema Reference

## JSON Schema Definitions

This document provides JSON Schema definitions for all game format files. These schemas can be used for validation, autocompletion, and documentation in game editors.

### Game Configuration Schema

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "$id": "https://pointclickengine.com/schemas/game-config.json",
  "title": "Game Configuration",
  "description": "Main game configuration file",
  "type": "object",
  "required": ["game"],
  "properties": {
    "game": {
      "type": "object",
      "required": ["title"],
      "properties": {
        "title": {
          "type": "string",
          "description": "Game title displayed in window"
        },
        "version": {
          "type": "string",
          "pattern": "^\\d+\\.\\d+\\.\\d+$",
          "description": "Semantic version (e.g., 1.0.0)"
        },
        "author": {
          "type": "string",
          "description": "Game author/developer name"
        }
      }
    },
    "window": {
      "type": "object",
      "properties": {
        "width": {
          "type": "integer",
          "minimum": 320,
          "maximum": 7680,
          "default": 1024
        },
        "height": {
          "type": "integer",
          "minimum": 240,
          "maximum": 4320,
          "default": 768
        },
        "fullscreen": {
          "type": "boolean",
          "default": false
        },
        "target_fps": {
          "type": "integer",
          "minimum": 30,
          "maximum": 240,
          "default": 60
        }
      }
    },
    "display": {
      "type": "object",
      "properties": {
        "scaling_mode": {
          "type": "string",
          "enum": ["FitWithBars", "Stretch", "PixelPerfect"],
          "default": "FitWithBars"
        },
        "target_width": {
          "type": "integer",
          "minimum": 320,
          "default": 1024
        },
        "target_height": {
          "type": "integer",
          "minimum": 240,
          "default": 768
        }
      }
    },
    "player": {
      "type": "object",
      "required": ["sprite_path", "sprite"],
      "properties": {
        "name": {
          "type": "string",
          "default": "Player"
        },
        "sprite_path": {
          "type": "string",
          "pattern": ".*\\.(png|jpg)$"
        },
        "sprite": {
          "type": "object",
          "required": ["frame_width", "frame_height", "columns", "rows"],
          "properties": {
            "frame_width": {
              "type": "integer",
              "minimum": 8,
              "maximum": 512
            },
            "frame_height": {
              "type": "integer",
              "minimum": 8,
              "maximum": 512
            },
            "columns": {
              "type": "integer",
              "minimum": 1,
              "maximum": 32
            },
            "rows": {
              "type": "integer",
              "minimum": 1,
              "maximum": 32
            }
          }
        },
        "start_position": {
          "type": "object",
          "properties": {
            "x": {"type": "number"},
            "y": {"type": "number"}
          }
        }
      }
    },
    "features": {
      "type": "array",
      "items": {
        "type": "string",
        "enum": ["verbs", "floating_dialogs", "portraits", "shaders", "auto_save", "debug"]
      },
      "uniqueItems": true
    },
    "assets": {
      "type": "object",
      "properties": {
        "scenes": {
          "type": "array",
          "items": {"type": "string"}
        },
        "dialogs": {
          "type": "array",
          "items": {"type": "string"}
        },
        "quests": {
          "type": "array",
          "items": {"type": "string"}
        },
        "audio": {
          "type": "object",
          "properties": {
            "music": {
              "type": "object",
              "patternProperties": {
                "^[a-zA-Z0-9_]+$": {
                  "type": "string",
                  "pattern": ".*\\.(ogg|wav|mp3)$"
                }
              }
            },
            "sounds": {
              "type": "object",
              "patternProperties": {
                "^[a-zA-Z0-9_]+$": {
                  "type": "string",
                  "pattern": ".*\\.(ogg|wav|mp3)$"
                }
              }
            }
          }
        }
      }
    },
    "settings": {
      "type": "object",
      "properties": {
        "debug_mode": {"type": "boolean", "default": false},
        "show_fps": {"type": "boolean", "default": false},
        "master_volume": {"type": "number", "minimum": 0, "maximum": 1, "default": 0.8},
        "music_volume": {"type": "number", "minimum": 0, "maximum": 1, "default": 0.7},
        "sfx_volume": {"type": "number", "minimum": 0, "maximum": 1, "default": 0.9}
      }
    },
    "initial_state": {
      "type": "object",
      "properties": {
        "flags": {
          "type": "object",
          "patternProperties": {
            "^[a-zA-Z0-9_]+$": {"type": "boolean"}
          }
        },
        "variables": {
          "type": "object",
          "patternProperties": {
            "^[a-zA-Z0-9_]+$": {
              "oneOf": [
                {"type": "number"},
                {"type": "integer"},
                {"type": "string"}
              ]
            }
          }
        }
      }
    },
    "start_scene": {"type": "string"},
    "start_music": {"type": "string"},
    "ui": {
      "type": "object",
      "properties": {
        "hints": {
          "type": "array",
          "items": {
            "type": "object",
            "required": ["text"],
            "properties": {
              "text": {"type": "string"},
              "duration": {"type": "number", "minimum": 0.1, "default": 5.0}
            }
          }
        },
        "opening_message": {"type": "string"}
      }
    }
  }
}
```

### Scene Schema

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "$id": "https://pointclickengine.com/schemas/scene.json",
  "title": "Scene Definition",
  "type": "object",
  "required": ["name", "background_path"],
  "properties": {
    "name": {
      "type": "string",
      "pattern": "^[a-zA-Z0-9_]+$",
      "description": "Unique scene identifier"
    },
    "background_path": {
      "type": "string",
      "pattern": ".*\\.(png|jpg)$"
    },
    "script_path": {
      "type": "string",
      "pattern": ".*\\.lua$"
    },
    "enable_pathfinding": {
      "type": "boolean",
      "default": true
    },
    "navigation_cell_size": {
      "type": "integer",
      "minimum": 8,
      "maximum": 64,
      "default": 16
    },
    "enable_camera_scrolling": {
      "type": "boolean",
      "default": true,
      "description": "Enable camera scrolling for scenes larger than the viewport"
    },
    "walkable_areas": {
      "type": "object",
      "properties": {
        "regions": {
          "type": "array",
          "items": {
            "type": "object",
            "required": ["name", "walkable", "vertices"],
            "properties": {
              "name": {"type": "string"},
              "walkable": {"type": "boolean"},
              "vertices": {
                "type": "array",
                "minItems": 3,
                "items": {
                  "type": "object",
                  "required": ["x", "y"],
                  "properties": {
                    "x": {"type": "number"},
                    "y": {"type": "number"}
                  }
                }
              }
            }
          }
        },
        "walk_behind": {
          "type": "array",
          "items": {
            "type": "object",
            "required": ["name", "y_threshold", "vertices"],
            "properties": {
              "name": {"type": "string"},
              "y_threshold": {"type": "number"},
              "vertices": {
                "type": "array",
                "minItems": 3,
                "items": {
                  "type": "object",
                  "required": ["x", "y"],
                  "properties": {
                    "x": {"type": "number"},
                    "y": {"type": "number"}
                  }
                }
              }
            }
          }
        },
        "scale_zones": {
          "type": "array",
          "items": {
            "type": "object",
            "required": ["min_y", "max_y", "min_scale", "max_scale"],
            "properties": {
              "min_y": {"type": "number"},
              "max_y": {"type": "number"},
              "min_scale": {"type": "number", "minimum": 0.1, "maximum": 2.0},
              "max_scale": {"type": "number", "minimum": 0.1, "maximum": 2.0}
            }
          }
        }
      }
    },
    "hotspots": {
      "type": "array",
      "items": {
        "oneOf": [
          {"$ref": "#/definitions/rectangleHotspot"},
          {"$ref": "#/definitions/polygonHotspot"},
          {"$ref": "#/definitions/exitHotspot"}
        ]
      }
    },
    "characters": {
      "type": "array",
      "items": {
        "type": "object",
        "required": ["name", "position", "sprite_path"],
        "properties": {
          "name": {
            "type": "string",
            "pattern": "^[a-zA-Z0-9_]+$"
          },
          "position": {
            "type": "object",
            "required": ["x", "y"],
            "properties": {
              "x": {"type": "number"},
              "y": {"type": "number"}
            }
          },
          "sprite_path": {"type": "string"},
          "sprite_info": {
            "type": "object",
            "properties": {
              "frame_width": {"type": "integer"},
              "frame_height": {"type": "integer"}
            }
          },
          "dialog_tree": {"type": "string"}
        }
      }
    }
  },
  "definitions": {
    "rectangleHotspot": {
      "type": "object",
      "required": ["name", "x", "y", "width", "height", "description"],
      "properties": {
        "name": {"type": "string"},
        "type": {"type": "string", "enum": ["rectangle"], "default": "rectangle"},
        "x": {"type": "number"},
        "y": {"type": "number"},
        "width": {"type": "number", "minimum": 1},
        "height": {"type": "number", "minimum": 1},
        "description": {"type": "string"},
        "active": {"type": "boolean", "default": true},
        "visible": {"type": "boolean", "default": true},
        "cursor": {"type": "string"},
        "states": {"$ref": "#/definitions/hotspotStates"},
        "conditions": {"$ref": "#/definitions/condition"}
      }
    },
    "polygonHotspot": {
      "type": "object",
      "required": ["name", "type", "vertices", "description"],
      "properties": {
        "name": {"type": "string"},
        "type": {"type": "string", "enum": ["polygon"]},
        "vertices": {
          "type": "array",
          "minItems": 3,
          "items": {
            "type": "object",
            "required": ["x", "y"],
            "properties": {
              "x": {"type": "number"},
              "y": {"type": "number"}
            }
          }
        },
        "description": {"type": "string"},
        "active": {"type": "boolean", "default": true},
        "visible": {"type": "boolean", "default": true},
        "cursor": {"type": "string"},
        "states": {"$ref": "#/definitions/hotspotStates"},
        "conditions": {"$ref": "#/definitions/condition"}
      }
    },
    "exitHotspot": {
      "type": "object",
      "required": ["name", "type", "target_scene", "description"],
      "properties": {
        "name": {"type": "string"},
        "type": {"type": "string", "enum": ["exit"]},
        "x": {"type": "number"},
        "y": {"type": "number"},
        "width": {"type": "number"},
        "height": {"type": "number"},
        "target_scene": {"type": "string"},
        "target_position": {
          "type": "object",
          "required": ["x", "y"],
          "properties": {
            "x": {"type": "number"},
            "y": {"type": "number"}
          }
        },
        "transition_type": {
          "type": "string",
          "enum": ["fade", "iris", "slide_left", "slide_right", "slide_up", "slide_down"]
        },
        "auto_walk": {"type": "boolean", "default": true},
        "edge": {
          "type": "string",
          "enum": ["left", "right", "top", "bottom"]
        },
        "requirements": {"$ref": "#/definitions/condition"},
        "description": {"type": "string"}
      }
    },
    "hotspotStates": {
      "type": "array",
      "items": {
        "type": "object",
        "required": ["name", "description"],
        "properties": {
          "name": {"type": "string"},
          "description": {"type": "string"},
          "sprite_path": {"type": "string"},
          "active": {"type": "boolean"},
          "visible": {"type": "boolean"}
        }
      }
    },
    "condition": {
      "oneOf": [
        {
          "type": "object",
          "properties": {
            "flag": {"type": "string"},
            "has_item": {"type": "string"},
            "variable": {"type": "string"},
            "value": {},
            "operator": {
              "type": "string",
              "enum": ["==", "!=", ">", "<", ">=", "<="]
            }
          }
        },
        {
          "type": "object",
          "properties": {
            "all_of": {
              "type": "array",
              "items": {"$ref": "#/definitions/condition"}
            }
          }
        },
        {
          "type": "object",
          "properties": {
            "any_of": {
              "type": "array",
              "items": {"$ref": "#/definitions/condition"}
            }
          }
        },
        {
          "type": "object",
          "properties": {
            "none_of": {
              "type": "array",
              "items": {"$ref": "#/definitions/condition"}
            }
          }
        }
      ]
    }
  }
}
```

### Quest Schema

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "$id": "https://pointclickengine.com/schemas/quest.json",
  "title": "Quest Definition",
  "type": "object",
  "required": ["quests"],
  "properties": {
    "quests": {
      "type": "array",
      "items": {
        "type": "object",
        "required": ["id", "name", "description", "category", "objectives"],
        "properties": {
          "id": {
            "type": "string",
            "pattern": "^[a-zA-Z0-9_]+$"
          },
          "name": {"type": "string"},
          "description": {"type": "string"},
          "category": {
            "type": "string",
            "enum": ["main", "side", "hidden"]
          },
          "icon": {"type": "string"},
          "auto_start": {"type": "boolean", "default": false},
          "start_conditions": {"$ref": "#/definitions/condition"},
          "prerequisites": {
            "type": "array",
            "items": {"type": "string"}
          },
          "requirements": {"$ref": "#/definitions/condition"},
          "objectives": {
            "type": "array",
            "minItems": 1,
            "items": {
              "type": "object",
              "required": ["id", "description"],
              "properties": {
                "id": {"type": "string"},
                "description": {"type": "string"},
                "optional": {"type": "boolean", "default": false},
                "hidden": {"type": "boolean", "default": false},
                "completion_conditions": {"$ref": "#/definitions/condition"},
                "rewards": {"$ref": "#/definitions/rewards"}
              }
            }
          },
          "rewards": {"$ref": "#/definitions/rewards"},
          "can_fail": {"type": "boolean", "default": false},
          "fail_conditions": {"$ref": "#/definitions/condition"},
          "journal_entries": {
            "type": "array",
            "items": {
              "type": "object",
              "required": ["id", "text"],
              "properties": {
                "id": {"type": "string"},
                "text": {"type": "string"},
                "conditions": {"$ref": "#/definitions/condition"}
              }
            }
          }
        }
      }
    }
  },
  "definitions": {
    "condition": {
      "$ref": "scene.json#/definitions/condition"
    },
    "rewards": {
      "type": "array",
      "items": {
        "type": "object",
        "required": ["type", "name"],
        "properties": {
          "type": {
            "type": "string",
            "enum": ["item", "flag", "variable", "achievement"]
          },
          "name": {"type": "string"},
          "value": {},
          "quantity": {"type": "integer", "minimum": 1}
        }
      }
    }
  }
}
```

### Dialog Schema

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "$id": "https://pointclickengine.com/schemas/dialog.json",
  "title": "Dialog Tree Definition",
  "type": "object",
  "required": ["id", "nodes", "start_node"],
  "properties": {
    "id": {
      "type": "string",
      "pattern": "^[a-zA-Z0-9_]+$"
    },
    "nodes": {
      "type": "array",
      "items": {
        "type": "object",
        "required": ["id", "speaker", "text"],
        "properties": {
          "id": {"type": "string"},
          "speaker": {"type": "string"},
          "text": {"type": "string"},
          "portrait": {"type": "string"},
          "choices": {
            "type": "array",
            "items": {
              "type": "object",
              "required": ["text"],
              "properties": {
                "text": {"type": "string"},
                "next": {"type": "string"},
                "conditions": {"$ref": "#/definitions/condition"},
                "effects": {"$ref": "#/definitions/effects"}
              }
            }
          },
          "next": {"type": "string"},
          "conditions": {"$ref": "#/definitions/condition"},
          "effects": {"$ref": "#/definitions/effects"}
        }
      }
    },
    "start_node": {"type": "string"},
    "on_end": {"$ref": "#/definitions/effects"}
  },
  "definitions": {
    "condition": {
      "$ref": "scene.json#/definitions/condition"
    },
    "effects": {
      "type": "array",
      "items": {
        "type": "object",
        "required": ["type", "name"],
        "properties": {
          "type": {
            "type": "string",
            "enum": ["set_flag", "set_variable", "add_item", "remove_item", "start_quest", "complete_objective"]
          },
          "name": {"type": "string"},
          "value": {}
        }
      }
    }
  }
}
```

### Item Schema

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "$id": "https://pointclickengine.com/schemas/items.json",
  "title": "Item Definitions",
  "type": "object",
  "required": ["items"],
  "properties": {
    "items": {
      "type": "object",
      "patternProperties": {
        "^[a-zA-Z0-9_]+$": {
          "type": "object",
          "required": ["name", "display_name", "description", "icon_path"],
          "properties": {
            "name": {"type": "string"},
            "display_name": {"type": "string"},
            "description": {"type": "string"},
            "icon_path": {"type": "string"},
            "usable_on": {
              "type": "array",
              "items": {"type": "string"}
            },
            "combinable_with": {
              "type": "array",
              "items": {"type": "string"}
            },
            "consumable": {"type": "boolean", "default": false},
            "stackable": {"type": "boolean", "default": false},
            "max_stack": {"type": "integer", "minimum": 1},
            "quest_item": {"type": "boolean", "default": false},
            "readable": {"type": "boolean", "default": false},
            "equippable": {"type": "boolean", "default": false},
            "states": {
              "type": "array",
              "items": {
                "type": "object",
                "required": ["name", "description"],
                "properties": {
                  "name": {"type": "string"},
                  "description": {"type": "string"},
                  "icon_path": {"type": "string"}
                }
              }
            },
            "use_effects": {"$ref": "#/definitions/effects"},
            "combine_effects": {
              "type": "object",
              "patternProperties": {
                "^[a-zA-Z0-9_]+$": {"$ref": "#/definitions/effects"}
              }
            }
          }
        }
      }
    }
  },
  "definitions": {
    "effects": {
      "$ref": "dialog.json#/definitions/effects"
    }
  }
}
```

## Type Definitions for Editors

### TypeScript Definitions

```typescript
// Core Types
type Point = { x: number; y: number };
type Color = string; // Hex color or named color
type FilePath = string;
type Identifier = string; // [a-zA-Z0-9_]+

// Condition Types
type SimpleCondition = {
  flag?: string;
  has_item?: string;
  variable?: string;
  value?: any;
  operator?: "==" | "!=" | ">" | "<" | ">=" | "<=";
};

type ComplexCondition = {
  all_of?: Condition[];
  any_of?: Condition[];
  none_of?: Condition[];
};

type Condition = SimpleCondition | ComplexCondition;

// Effect Types
type Effect = {
  type: "set_flag" | "set_variable" | "add_item" | "remove_item" | 
        "start_quest" | "complete_objective" | "unlock_achievement";
  name: string;
  value?: any;
};

// Hotspot Types
type BaseHotspot = {
  name: Identifier;
  description: string;
  active?: boolean;
  visible?: boolean;
  cursor?: string;
  states?: HotspotState[];
  conditions?: Condition;
};

type RectangleHotspot = BaseHotspot & {
  type?: "rectangle";
  x: number;
  y: number;
  width: number;
  height: number;
};

type PolygonHotspot = BaseHotspot & {
  type: "polygon";
  vertices: Point[];
};

type ExitHotspot = BaseHotspot & {
  type: "exit";
  x?: number;
  y?: number;
  width?: number;
  height?: number;
  target_scene: Identifier;
  target_position?: Point;
  transition_type?: TransitionType;
  auto_walk?: boolean;
  edge?: "left" | "right" | "top" | "bottom";
  requirements?: Condition;
};

type Hotspot = RectangleHotspot | PolygonHotspot | ExitHotspot;

// Scene Types
type WalkableRegion = {
  name: string;
  walkable: boolean;
  vertices: Point[];
};

type WalkBehindRegion = {
  name: string;
  y_threshold: number;
  vertices: Point[];
};

type ScaleZone = {
  min_y: number;
  max_y: number;
  min_scale: number;
  max_scale: number;
};

type SceneCharacter = {
  name: Identifier;
  position: Point;
  sprite_path: FilePath;
  sprite_info?: {
    frame_width: number;
    frame_height: number;
  };
  dialog_tree?: string;
};

type Scene = {
  name: Identifier;
  background_path: FilePath;
  script_path?: FilePath;
  enable_pathfinding?: boolean;
  navigation_cell_size?: number;
  walkable_areas?: {
    regions?: WalkableRegion[];
    walk_behind?: WalkBehindRegion[];
    scale_zones?: ScaleZone[];
  };
  hotspots?: Hotspot[];
  characters?: SceneCharacter[];
};

// Quest Types
type QuestObjective = {
  id: Identifier;
  description: string;
  optional?: boolean;
  hidden?: boolean;
  completion_conditions: Condition;
  rewards?: Reward[];
};

type Quest = {
  id: Identifier;
  name: string;
  description: string;
  category: "main" | "side" | "hidden";
  icon?: FilePath;
  auto_start?: boolean;
  start_conditions?: Condition;
  prerequisites?: Identifier[];
  requirements?: Condition;
  objectives: QuestObjective[];
  rewards?: Reward[];
  can_fail?: boolean;
  fail_conditions?: Condition;
  journal_entries?: JournalEntry[];
};

// Dialog Types
type DialogChoice = {
  text: string;
  next?: Identifier;
  conditions?: Condition;
  effects?: Effect[];
};

type DialogNode = {
  id: Identifier;
  speaker: string;
  text: string;
  portrait?: string;
  choices?: DialogChoice[];
  next?: Identifier;
  conditions?: Condition;
  effects?: Effect[];
};

type DialogTree = {
  id: Identifier;
  nodes: DialogNode[];
  start_node: Identifier;
  on_end?: Effect[];
};

// Item Types
type ItemState = {
  name: string;
  description: string;
  icon_path?: FilePath;
};

type Item = {
  name: Identifier;
  display_name: string;
  description: string;
  icon_path: FilePath;
  usable_on?: Identifier[];
  combinable_with?: Identifier[];
  consumable?: boolean;
  stackable?: boolean;
  max_stack?: number;
  quest_item?: boolean;
  readable?: boolean;
  equippable?: boolean;
  states?: ItemState[];
  use_effects?: Effect[];
  combine_effects?: Record<Identifier, Effect[]>;
};
```

## Validation Rules for Editors

### Scene Validation
1. **Background image must exist** at specified path
2. **Scene name must be unique** across all scenes
3. **Walkable regions must not overlap** with non-walkable regions
4. **Scale zones must have min_scale < max_scale**
5. **Exit hotspots must reference valid scenes**
6. **Character sprite paths must exist**
7. **Hotspot names must be unique within scene**
8. **Polygon hotspots must have at least 3 vertices**
9. **Walk-behind regions must be within scene bounds**

### Quest Validation
1. **Quest IDs must be unique**
2. **Prerequisites must reference existing quests**
3. **At least one objective required**
4. **Objective IDs must be unique within quest**
5. **Reward items must exist in item definitions**
6. **Start conditions must use valid flags/variables**

### Dialog Validation
1. **Node IDs must be unique within dialog**
2. **Start node must exist**
3. **Choice next references must be valid node IDs**
4. **Portrait files must exist if specified**
5. **No circular references in dialog flow**

### Item Validation
1. **Item names must be unique**
2. **Icon paths must exist**
3. **Usable_on targets must be valid hotspot names**
4. **Combinable_with must reference valid items**
5. **Max_stack must be > 1 if stackable**

### Cross-File Validation
1. **Scene scripts must exist at specified paths**
2. **Dialog files referenced in characters must exist**
3. **Items referenced in quests must be defined**
4. **Flags/variables must be consistently typed**
5. **Audio files must exist at specified paths**
6. **All asset paths must be relative to game root**

## Editor Features Checklist

### Essential Features
- [ ] YAML syntax highlighting and validation
- [ ] Visual scene editor with hotspot placement
- [ ] Dialog tree visual editor
- [ ] Quest dependency graph viewer
- [ ] Asset browser with preview
- [ ] Lua script editor with API autocomplete
- [ ] Real-time validation with error reporting
- [ ] Project structure creation wizard

### Advanced Features
- [ ] Live game preview
- [ ] Integrated debugger
- [ ] Asset optimization tools
- [ ] Localization support
- [ ] Version control integration
- [ ] Multi-user collaboration
- [ ] Plugin system for extensions
- [ ] Export to multiple platforms

### Quality of Life
- [ ] Undo/redo system
- [ ] Search across all files
- [ ] Batch operations
- [ ] Template library
- [ ] Keyboard shortcuts
- [ ] Dark/light themes
- [ ] Customizable workspace
- [ ] Context-sensitive help

This comprehensive documentation provides everything needed to implement a professional game editor for the Point & Click Engine.