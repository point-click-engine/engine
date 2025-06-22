# Point & Click Engine Editor Implementation Guide

## Architecture Overview

### Recommended Technology Stack

#### Desktop Application (Recommended)
- **Framework**: Electron + React/Vue/Angular
- **Language**: TypeScript
- **UI Library**: Material-UI, Ant Design, or custom
- **State Management**: Redux/MobX/Vuex
- **File Handling**: Node.js fs module
- **Canvas/Graphics**: Konva.js or Fabric.js
- **Code Editor**: Monaco Editor (VS Code's editor)
- **YAML Parsing**: js-yaml
- **Validation**: Ajv (JSON Schema validator)

#### Alternative: Web-Based Editor
- **Backend**: Node.js/Express or Python/FastAPI
- **Frontend**: Same as desktop minus Electron
- **Storage**: Cloud storage (S3, GCS) or Git integration
- **Real-time**: WebSockets for collaboration

#### Alternative: Native Application
- **Language**: C++ with Qt or C# with WPF
- **Pros**: Better performance, native feel
- **Cons**: Platform-specific builds needed

## Core Components

### 1. Project Manager

```typescript
interface Project {
  name: string;
  path: string;
  version: string;
  lastModified: Date;
  engineVersion: string;
}

class ProjectManager {
  // Create new project with folder structure
  createProject(name: string, path: string): Project {
    // Create directories
    const dirs = [
      'scenes', 'scripts', 'dialogs', 'quests', 
      'items', 'cutscenes', 'assets/backgrounds',
      'assets/sprites', 'assets/items', 'assets/portraits',
      'assets/music', 'assets/sounds/effects',
      'assets/sounds/ambience', 'saves'
    ];
    
    dirs.forEach(dir => fs.mkdirSync(path.join(projectPath, dir), { recursive: true }));
    
    // Create default game_config.yaml
    const defaultConfig = this.generateDefaultConfig(name);
    fs.writeFileSync(path.join(projectPath, 'game_config.yaml'), yaml.dump(defaultConfig));
    
    // Create minimal main.cr
    const mainCr = this.generateMainCr();
    fs.writeFileSync(path.join(projectPath, 'main.cr'), mainCr);
    
    return { name, path, version: '1.0.0', lastModified: new Date(), engineVersion: '1.0' };
  }
  
  // Open existing project
  openProject(path: string): Project {
    const configPath = path.join(path, 'game_config.yaml');
    const config = yaml.load(fs.readFileSync(configPath, 'utf8'));
    return {
      name: config.game.title,
      path,
      version: config.game.version || '1.0.0',
      lastModified: fs.statSync(configPath).mtime,
      engineVersion: this.detectEngineVersion(path)
    };
  }
}
```

### 2. Scene Editor

```typescript
interface SceneEditor {
  // Visual components
  canvas: Canvas;
  propertyPanel: PropertyPanel;
  hotspotList: HotspotList;
  toolbar: SceneToolbar;
  
  // Current state
  currentScene: Scene;
  selectedHotspot: Hotspot | null;
  mode: 'select' | 'rectangle' | 'polygon' | 'walkable' | 'character';
  
  // Core functionality
  loadScene(scenePath: string): void;
  saveScene(): void;
  
  // Hotspot operations
  addHotspot(type: HotspotType): void;
  deleteHotspot(id: string): void;
  updateHotspot(id: string, changes: Partial<Hotspot>): void;
  
  // Visual editing
  setBackgroundImage(imagePath: string): void;
  drawWalkableAreas(): void;
  drawScaleZones(): void;
  
  // Preview
  previewScene(): void;
}

class SceneEditorCanvas {
  private stage: Konva.Stage;
  private backgroundLayer: Konva.Layer;
  private hotspotLayer: Konva.Layer;
  private walkableLayer: Konva.Layer;
  private gridLayer: Konva.Layer;
  
  constructor(container: HTMLElement) {
    this.stage = new Konva.Stage({
      container: container,
      width: 1024,
      height: 768
    });
    
    this.setupLayers();
    this.setupInteractions();
  }
  
  // Hotspot creation with visual feedback
  createRectangleHotspot(): void {
    let rect: Konva.Rect;
    let startPos: { x: number, y: number };
    
    this.stage.on('mousedown', (e) => {
      startPos = this.stage.getPointerPosition();
      rect = new Konva.Rect({
        x: startPos.x,
        y: startPos.y,
        width: 0,
        height: 0,
        fill: 'rgba(0, 255, 0, 0.3)',
        stroke: 'green',
        strokeWidth: 2
      });
      this.hotspotLayer.add(rect);
    });
    
    this.stage.on('mousemove', () => {
      if (!rect) return;
      const pos = this.stage.getPointerPosition();
      rect.width(pos.x - startPos.x);
      rect.height(pos.y - startPos.y);
      this.hotspotLayer.batchDraw();
    });
    
    this.stage.on('mouseup', () => {
      if (!rect) return;
      this.createHotspotFromRect(rect);
      this.stage.off('mousedown mousemove mouseup');
    });
  }
  
  // Walkable area polygon drawing
  createWalkablePolygon(): void {
    const points: number[] = [];
    let polygon: Konva.Line;
    let tempLine: Konva.Line;
    
    this.stage.on('click', (e) => {
      const pos = this.stage.getPointerPosition();
      points.push(pos.x, pos.y);
      
      if (points.length === 2) {
        // First point - create polygon
        polygon = new Konva.Line({
          points: points,
          fill: 'rgba(0, 0, 255, 0.2)',
          stroke: 'blue',
          strokeWidth: 2,
          closed: false
        });
        this.walkableLayer.add(polygon);
      } else {
        // Update polygon
        polygon.points(points);
      }
      
      // Visual feedback for next line
      if (tempLine) tempLine.destroy();
      tempLine = new Konva.Line({
        points: [pos.x, pos.y, pos.x, pos.y],
        stroke: 'blue',
        strokeWidth: 1,
        dash: [5, 5]
      });
      this.walkableLayer.add(tempLine);
    });
    
    this.stage.on('mousemove', () => {
      if (!tempLine) return;
      const pos = this.stage.getPointerPosition();
      const p = tempLine.points();
      p[2] = pos.x;
      p[3] = pos.y;
      tempLine.points(p);
      this.walkableLayer.batchDraw();
    });
    
    // Double-click to finish
    this.stage.on('dblclick', () => {
      polygon.closed(true);
      tempLine.destroy();
      this.createWalkableArea(polygon);
      this.stage.off('click mousemove dblclick');
    });
  }
}
```

### 3. Dialog Editor

```typescript
class DialogTreeEditor {
  private cy: cytoscape.Core; // Cytoscape for graph visualization
  private selectedNode: DialogNode | null;
  
  constructor(container: HTMLElement) {
    this.cy = cytoscape({
      container: container,
      style: [
        {
          selector: 'node',
          style: {
            'background-color': '#666',
            'label': 'data(label)',
            'text-valign': 'center',
            'text-halign': 'center',
            'width': 150,
            'height': 50,
            'shape': 'roundrectangle'
          }
        },
        {
          selector: 'edge',
          style: {
            'width': 3,
            'line-color': '#ccc',
            'target-arrow-color': '#ccc',
            'target-arrow-shape': 'triangle',
            'curve-style': 'bezier',
            'label': 'data(label)',
            'text-rotation': 'autorotate'
          }
        }
      ],
      layout: {
        name: 'dagre',
        rankDir: 'TB',
        nodeSep: 100,
        rankSep: 100
      }
    });
  }
  
  loadDialogTree(dialogTree: DialogTree): void {
    const elements = [];
    
    // Add nodes
    dialogTree.nodes.forEach(node => {
      elements.push({
        data: {
          id: node.id,
          label: `${node.speaker}: ${this.truncate(node.text, 30)}`
        }
      });
    });
    
    // Add edges for choices
    dialogTree.nodes.forEach(node => {
      if (node.choices) {
        node.choices.forEach((choice, index) => {
          if (choice.next) {
            elements.push({
              data: {
                source: node.id,
                target: choice.next,
                label: this.truncate(choice.text, 20)
              }
            });
          }
        });
      } else if (node.next) {
        elements.push({
          data: {
            source: node.id,
            target: node.next,
            label: 'Continue'
          }
        });
      }
    });
    
    this.cy.elements().remove();
    this.cy.add(elements);
    this.cy.layout({ name: 'dagre' }).run();
  }
  
  addNode(): DialogNode {
    const node: DialogNode = {
      id: `node_${Date.now()}`,
      speaker: 'Character',
      text: 'Dialog text here...'
    };
    
    this.cy.add({
      data: {
        id: node.id,
        label: `${node.speaker}: New Node`
      }
    });
    
    return node;
  }
  
  connectNodes(sourceId: string, targetId: string, choiceText?: string): void {
    this.cy.add({
      data: {
        source: sourceId,
        target: targetId,
        label: choiceText || 'Continue'
      }
    });
  }
}
```

### 4. Quest Editor

```typescript
class QuestEditor {
  private questList: Quest[] = [];
  private selectedQuest: Quest | null = null;
  private objectivesPanel: ObjectivesPanel;
  private dependencyGraph: DependencyGraph;
  
  // Visual dependency graph
  renderDependencyGraph(): void {
    const nodes = this.questList.map(quest => ({
      id: quest.id,
      label: quest.name,
      category: quest.category
    }));
    
    const edges = [];
    this.questList.forEach(quest => {
      if (quest.prerequisites) {
        quest.prerequisites.forEach(prereq => {
          edges.push({
            source: prereq,
            target: quest.id
          });
        });
      }
    });
    
    this.dependencyGraph.render(nodes, edges);
  }
  
  // Objective editor with drag-and-drop reordering
  class ObjectivesPanel {
    private container: HTMLElement;
    private sortable: Sortable;
    
    renderObjectives(objectives: QuestObjective[]): void {
      this.container.innerHTML = '';
      
      objectives.forEach((obj, index) => {
        const objElement = this.createObjectiveElement(obj, index);
        this.container.appendChild(objElement);
      });
      
      // Enable drag-and-drop reordering
      this.sortable = Sortable.create(this.container, {
        animation: 150,
        handle: '.drag-handle',
        onEnd: (evt) => {
          this.reorderObjectives(evt.oldIndex, evt.newIndex);
        }
      });
    }
    
    private createObjectiveElement(obj: QuestObjective, index: number): HTMLElement {
      const div = document.createElement('div');
      div.className = 'objective-item';
      div.innerHTML = `
        <span class="drag-handle">≡</span>
        <span class="objective-id">${obj.id}</span>
        <span class="objective-desc">${obj.description}</span>
        ${obj.optional ? '<span class="optional-badge">Optional</span>' : ''}
        ${obj.hidden ? '<span class="hidden-badge">Hidden</span>' : ''}
        <button class="edit-btn" data-index="${index}">Edit</button>
        <button class="delete-btn" data-index="${index}">×</button>
      `;
      return div;
    }
  }
}
```

### 5. Asset Manager

```typescript
class AssetManager {
  private assetTree: AssetTree;
  private previewPanel: PreviewPanel;
  private importDialog: ImportDialog;
  
  // Asset validation
  validateAsset(file: File, type: AssetType): ValidationResult {
    const errors: string[] = [];
    const warnings: string[] = [];
    
    // File type validation
    const validExtensions = {
      image: ['.png', '.jpg', '.jpeg'],
      audio: ['.ogg', '.wav', '.mp3'],
      script: ['.lua'],
      data: ['.yaml', '.yml']
    };
    
    const ext = path.extname(file.name).toLowerCase();
    if (!validExtensions[type].includes(ext)) {
      errors.push(`Invalid file type. Expected: ${validExtensions[type].join(', ')}`);
    }
    
    // Size validation
    if (type === 'image' && file.size > 10 * 1024 * 1024) {
      warnings.push('Image larger than 10MB may impact performance');
    }
    
    // Name validation
    if (!/^[a-zA-Z0-9_\-\.]+$/.test(file.name)) {
      errors.push('Filename contains invalid characters');
    }
    
    return { valid: errors.length === 0, errors, warnings };
  }
  
  // Sprite sheet slicer
  class SpriteSheetSlicer {
    private canvas: HTMLCanvasElement;
    private ctx: CanvasRenderingContext2D;
    private image: HTMLImageElement;
    private grid: { cols: number; rows: number; cellWidth: number; cellHeight: number };
    
    loadImage(imagePath: string): Promise<void> {
      return new Promise((resolve, reject) => {
        this.image = new Image();
        this.image.onload = () => {
          this.canvas.width = this.image.width;
          this.canvas.height = this.image.height;
          this.ctx.drawImage(this.image, 0, 0);
          this.detectGrid();
          resolve();
        };
        this.image.onerror = reject;
        this.image.src = imagePath;
      });
    }
    
    // Auto-detect sprite grid
    detectGrid(): void {
      // Simple detection based on transparency gaps
      // More sophisticated detection could analyze pixel patterns
      const imageData = this.ctx.getImageData(0, 0, this.canvas.width, this.canvas.height);
      // ... grid detection algorithm
    }
    
    // Extract individual frames
    extractFrames(): HTMLCanvasElement[] {
      const frames: HTMLCanvasElement[] = [];
      
      for (let row = 0; row < this.grid.rows; row++) {
        for (let col = 0; col < this.grid.cols; col++) {
          const frameCanvas = document.createElement('canvas');
          frameCanvas.width = this.grid.cellWidth;
          frameCanvas.height = this.grid.cellHeight;
          const frameCtx = frameCanvas.getContext('2d');
          
          frameCtx.drawImage(
            this.image,
            col * this.grid.cellWidth,
            row * this.grid.cellHeight,
            this.grid.cellWidth,
            this.grid.cellHeight,
            0, 0,
            this.grid.cellWidth,
            this.grid.cellHeight
          );
          
          frames.push(frameCanvas);
        }
      }
      
      return frames;
    }
  }
}
```

### 6. Script Editor Integration

```typescript
class ScriptEditor {
  private monaco: monaco.editor.IStandaloneCodeEditor;
  private currentFile: string;
  private breakpoints: Set<number> = new Set();
  
  constructor(container: HTMLElement) {
    // Configure Monaco Editor
    this.monaco = monaco.editor.create(container, {
      value: '',
      language: 'lua',
      theme: 'vs-dark',
      automaticLayout: true,
      minimap: { enabled: true },
      folding: true,
      lineNumbers: 'on',
      renderWhitespace: 'selection',
      scrollBeyondLastLine: false
    });
    
    this.setupAutoComplete();
    this.setupLinting();
    this.setupDebugging();
  }
  
  // API auto-completion
  private setupAutoComplete(): void {
    monaco.languages.registerCompletionItemProvider('lua', {
      provideCompletionItems: (model, position) => {
        const suggestions = [];
        
        // Engine API functions
        const engineAPI = {
          'change_scene': { 
            snippet: 'change_scene("${1:scene_name}")',
            docs: 'Change to another scene'
          },
          'show_message': {
            snippet: 'show_message("${1:text}")',
            docs: 'Show a message dialog'
          },
          'add_to_inventory': {
            snippet: 'add_to_inventory("${1:item_name}")',
            docs: 'Add item to player inventory'
          },
          // ... more API functions
        };
        
        Object.entries(engineAPI).forEach(([func, info]) => {
          suggestions.push({
            label: func,
            kind: monaco.languages.CompletionItemKind.Function,
            insertText: info.snippet,
            insertTextRules: monaco.languages.CompletionInsertTextRule.InsertAsSnippet,
            documentation: info.docs
          });
        });
        
        return { suggestions };
      }
    });
  }
  
  // Real-time linting
  private setupLinting(): void {
    let lintTimeout: NodeJS.Timeout;
    
    this.monaco.onDidChangeModelContent(() => {
      clearTimeout(lintTimeout);
      lintTimeout = setTimeout(() => {
        this.lintCode();
      }, 500);
    });
  }
  
  private async lintCode(): Promise<void> {
    const code = this.monaco.getValue();
    const errors = await this.validateLuaCode(code);
    
    const markers = errors.map(error => ({
      severity: error.severity === 'error' 
        ? monaco.MarkerSeverity.Error 
        : monaco.MarkerSeverity.Warning,
      startLineNumber: error.line,
      startColumn: error.column,
      endLineNumber: error.line,
      endColumn: error.column + error.length,
      message: error.message
    }));
    
    monaco.editor.setModelMarkers(
      this.monaco.getModel(),
      'lua-lint',
      markers
    );
  }
}
```

### 7. Testing & Preview System

```typescript
class GamePreview {
  private previewWindow: BrowserWindow | null = null;
  private debugger: GameDebugger;
  
  async launchPreview(projectPath: string, scene?: string): Promise<void> {
    // Build temporary game package
    const tempPath = await this.buildTempGame(projectPath);
    
    // Launch preview window
    this.previewWindow = new BrowserWindow({
      width: 1024,
      height: 768,
      webPreferences: {
        nodeIntegration: false,
        contextIsolation: true
      }
    });
    
    // Load game with debug hooks
    this.previewWindow.loadURL(`file://${tempPath}/index.html?debug=true&scene=${scene || 'start'}`);
    
    // Attach debugger
    this.debugger = new GameDebugger(this.previewWindow);
    this.debugger.on('breakpoint', this.handleBreakpoint.bind(this));
    this.debugger.on('variable-change', this.handleVariableChange.bind(this));
  }
  
  // Live reload on file changes
  watchForChanges(projectPath: string): void {
    const watcher = chokidar.watch(projectPath, {
      ignored: /node_modules|\.git|saves/,
      persistent: true
    });
    
    watcher.on('change', (filePath) => {
      if (this.previewWindow) {
        // Hot reload specific file types
        if (filePath.endsWith('.lua')) {
          this.debugger.reloadScript(filePath);
        } else if (filePath.endsWith('.yaml')) {
          this.debugger.reloadData(filePath);
        } else {
          // Full reload for other changes
          this.previewWindow.reload();
        }
      }
    });
  }
}

class GameDebugger {
  private gameState: Map<string, any> = new Map();
  private eventLog: GameEvent[] = [];
  
  // State inspection
  inspectState(): GameState {
    return {
      currentScene: this.gameState.get('current_scene'),
      playerPosition: this.gameState.get('player_position'),
      inventory: this.gameState.get('inventory'),
      flags: this.gameState.get('flags'),
      variables: this.gameState.get('variables'),
      activeQuests: this.gameState.get('quests')
    };
  }
  
  // Command injection
  executeCommand(command: string): any {
    // Send command to game engine
    return this.sendToGame('execute', { command });
  }
  
  // Event monitoring
  monitorEvents(filter?: string[]): void {
    this.on('game-event', (event: GameEvent) => {
      if (!filter || filter.includes(event.type)) {
        this.eventLog.push(event);
        this.emit('event-logged', event);
      }
    });
  }
}
```

### 8. Localization Support

```typescript
class LocalizationManager {
  private languages: Map<string, LanguagePack> = new Map();
  private currentLanguage: string = 'en';
  
  // Extract translatable strings
  async extractStrings(projectPath: string): Promise<TranslatableString[]> {
    const strings: TranslatableString[] = [];
    
    // Extract from YAML files
    const yamlFiles = await this.findFiles(projectPath, '**/*.yaml');
    for (const file of yamlFiles) {
      const content = yaml.load(await fs.readFile(file, 'utf8'));
      this.extractFromObject(content, file, strings);
    }
    
    // Extract from Lua scripts
    const luaFiles = await this.findFiles(projectPath, '**/*.lua');
    for (const file of luaFiles) {
      const content = await fs.readFile(file, 'utf8');
      this.extractFromLua(content, file, strings);
    }
    
    return strings;
  }
  
  // Generate translation file
  generateTranslationFile(strings: TranslatableString[], language: string): string {
    const translations = {};
    
    strings.forEach(str => {
      translations[str.key] = {
        original: str.text,
        translation: '',
        context: str.context,
        location: str.location
      };
    });
    
    return yaml.dump({
      language: language,
      translations: translations
    });
  }
  
  // Apply translations to project
  async applyTranslations(projectPath: string, language: string): Promise<void> {
    const langPack = this.languages.get(language);
    if (!langPack) throw new Error(`Language pack ${language} not found`);
    
    // Create localized versions of files
    // ... implementation
  }
}
```

### 9. Build & Export System

```typescript
class BuildSystem {
  private platforms: Platform[] = ['windows', 'mac', 'linux'];
  
  async buildGame(project: Project, options: BuildOptions): Promise<BuildResult> {
    const steps = [
      'Validating project',
      'Optimizing assets',
      'Compiling scripts',
      'Packaging files',
      'Creating executable'
    ];
    
    const progress = new BuildProgress(steps);
    
    try {
      // Validate all files
      progress.update('Validating project');
      await this.validateProject(project);
      
      // Optimize assets
      progress.update('Optimizing assets');
      await this.optimizeAssets(project, options);
      
      // Compile/minify scripts
      progress.update('Compiling scripts');
      await this.compileScripts(project, options);
      
      // Package everything
      progress.update('Packaging files');
      const package = await this.createPackage(project, options);
      
      // Create platform-specific builds
      progress.update('Creating executable');
      const builds = await this.createBuilds(package, options.platforms);
      
      return { success: true, builds };
      
    } catch (error) {
      return { success: false, error: error.message };
    }
  }
  
  // Asset optimization
  private async optimizeAssets(project: Project, options: BuildOptions): Promise<void> {
    // Image optimization
    if (options.optimizeImages) {
      const images = await this.findAssets(project, 'image');
      for (const image of images) {
        await this.optimizeImage(image, options.imageQuality);
      }
    }
    
    // Audio compression
    if (options.compressAudio) {
      const audio = await this.findAssets(project, 'audio');
      for (const file of audio) {
        await this.compressAudio(file, options.audioBitrate);
      }
    }
    
    // Create texture atlases
    if (options.createAtlases) {
      await this.createTextureAtlases(project);
    }
  }
}
```

## Data Models

### Project File Structure
```typescript
interface ProjectStructure {
  root: string;
  directories: {
    scenes: string;
    scripts: string;
    dialogs: string;
    quests: string;
    items: string;
    cutscenes: string;
    assets: {
      backgrounds: string;
      sprites: string;
      items: string;
      portraits: string;
      music: string;
      sounds: {
        effects: string;
        ambience: string;
      };
    };
    saves: string;
  };
  files: {
    config: string;      // game_config.yaml
    main: string;        // main.cr
    readme?: string;     // README.md
    changelog?: string;  // CHANGELOG.md
  };
}
```

### Editor State Management
```typescript
interface EditorState {
  project: Project | null;
  openFiles: OpenFile[];
  activeFile: string | null;
  unsavedChanges: Set<string>;
  selection: Selection | null;
  clipboard: ClipboardData | null;
  history: HistoryStack;
  preferences: EditorPreferences;
}

interface HistoryStack {
  undoStack: Action[];
  redoStack: Action[];
  maxSize: number;
}

interface Action {
  type: string;
  timestamp: number;
  data: any;
  undo: () => void;
  redo: () => void;
}
```

## UI/UX Guidelines

### Layout Principles
1. **Dockable Panels** - Allow users to customize workspace
2. **Dark/Light Themes** - Support both for user preference
3. **Consistent Icons** - Use standard icons (save, open, etc.)
4. **Keyboard Shortcuts** - Standard shortcuts plus custom ones
5. **Context Menus** - Right-click menus everywhere
6. **Drag & Drop** - Support for files, assets, nodes
7. **Multi-Select** - Ctrl/Cmd+click, Shift+click
8. **Search Everything** - Global search across project

### Responsive Design
```css
/* Example grid layout */
.editor-layout {
  display: grid;
  grid-template-columns: 200px 1fr 300px;
  grid-template-rows: 40px 1fr 30px;
  grid-template-areas:
    "toolbar toolbar toolbar"
    "sidebar content properties"
    "status status status";
  height: 100vh;
}

/* Collapsible panels */
.panel {
  min-width: 150px;
  max-width: 500px;
  resize: horizontal;
  overflow: auto;
}

/* Mobile/tablet support */
@media (max-width: 768px) {
  .editor-layout {
    grid-template-columns: 1fr;
    grid-template-areas:
      "toolbar"
      "content"
      "status";
  }
  
  .sidebar, .properties {
    position: absolute;
    transform: translateX(-100%);
    transition: transform 0.3s;
  }
  
  .sidebar.open, .properties.open {
    transform: translateX(0);
  }
}
```

## Performance Optimization

### Large Project Handling
```typescript
class VirtualFileTree {
  // Load only visible nodes
  private visibleNodes: Set<string> = new Set();
  private nodeCache: Map<string, TreeNode> = new Map();
  
  async loadNode(path: string): Promise<TreeNode> {
    if (this.nodeCache.has(path)) {
      return this.nodeCache.get(path)!;
    }
    
    const stats = await fs.stat(path);
    const node: TreeNode = {
      path,
      name: path.basename(path),
      type: stats.isDirectory() ? 'directory' : 'file',
      children: stats.isDirectory() ? [] : undefined,
      loaded: false
    };
    
    this.nodeCache.set(path, node);
    return node;
  }
  
  async expandNode(path: string): Promise<void> {
    const node = await this.loadNode(path);
    if (node.type === 'directory' && !node.loaded) {
      const entries = await fs.readdir(path);
      node.children = entries.map(name => path.join(path, name));
      node.loaded = true;
    }
  }
}

// Efficient scene rendering
class SceneRenderer {
  private renderQueue: RenderTask[] = [];
  private frameRequest: number | null = null;
  
  queueRender(task: RenderTask): void {
    this.renderQueue.push(task);
    
    if (!this.frameRequest) {
      this.frameRequest = requestAnimationFrame(() => {
        this.processRenderQueue();
        this.frameRequest = null;
      });
    }
  }
  
  private processRenderQueue(): void {
    // Batch similar operations
    const batches = this.batchTasks(this.renderQueue);
    
    batches.forEach(batch => {
      this.renderBatch(batch);
    });
    
    this.renderQueue = [];
  }
}
```

## Testing the Editor

### Unit Tests
```typescript
describe('SceneEditor', () => {
  it('should create valid hotspot', () => {
    const editor = new SceneEditor();
    const hotspot = editor.createHotspot('rectangle', {
      x: 100, y: 100, width: 50, height: 50
    });
    
    expect(hotspot).toMatchObject({
      type: 'rectangle',
      x: 100,
      y: 100,
      width: 50,
      height: 50
    });
    expect(hotspot.name).toMatch(/^hotspot_\d+$/);
  });
  
  it('should validate scene on save', async () => {
    const editor = new SceneEditor();
    editor.loadScene(mockScene);
    editor.setBackgroundImage(''); // Invalid
    
    await expect(editor.save()).rejects.toThrow('Background image required');
  });
});
```

### Integration Tests
```typescript
describe('Editor Integration', () => {
  it('should build playable game', async () => {
    const project = await ProjectManager.create('TestGame', tempDir);
    
    // Add minimal content
    await SceneEditor.createScene('intro', {
      background: 'test.png',
      hotspots: [{
        name: 'start',
        type: 'exit',
        target_scene: 'main'
      }]
    });
    
    // Build
    const result = await BuildSystem.build(project, {
      platform: 'test',
      validate: true
    });
    
    expect(result.success).toBe(true);
    expect(result.errors).toHaveLength(0);
  });
});
```

## Distribution

### Packaging Options
1. **Electron App**
   - Windows: NSIS installer
   - macOS: DMG with code signing
   - Linux: AppImage, deb, rpm

2. **Web Version**
   - Progressive Web App
   - Cloud storage integration
   - Collaborative editing

3. **Plugin for Existing IDEs**
   - VS Code extension
   - IntelliJ plugin
   - Sublime Text package

This comprehensive guide provides a solid foundation for implementing a professional game editor for the Point & Click Engine. The modular architecture allows for incremental development and easy extension of features.