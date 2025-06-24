# Asset Guide for Point & Click Engine

This guide covers all asset requirements, formats, and best practices for creating games with the Point & Click Engine.

## Table of Contents
- [Image Assets](#image-assets)
  - [Background Images](#background-images)
  - [Sprite Sheets](#sprite-sheets)
  - [Item Icons](#item-icons)
  - [Character Portraits](#character-portraits)
- [Audio Assets](#audio-assets)
  - [Music Tracks](#music-tracks)
  - [Sound Effects](#sound-effects)
  - [Ambient Sounds](#ambient-sounds)
- [Asset Organization](#asset-organization)
- [File Format Specifications](#file-format-specifications)
- [Best Practices](#best-practices)
- [Resource Optimization](#resource-optimization)

## Image Assets

### General Image Requirements
- **Formats**: PNG (recommended for transparency), JPG
- **Color Depth**: 32-bit RGBA
- **Size Limits**: No hard limit, but consider memory usage and performance
- **Compression**: Use appropriate compression levels to balance quality and file size

### Background Images
Background images set the scene for each location in your game.

**Specifications:**
- **Recommended Size**: Match game resolution (e.g., 1024x768, 1280x720, 1920x1080)
- **Format**: PNG or JPG
- **Naming Convention**: `scene_name.png` (e.g., `mansion_entrance.png`, `garden.png`)

**Best Practices:**
- Use JPG for photographic backgrounds without transparency
- Use PNG when you need precise colors or partial transparency
- Consider multiple resolutions for different display sizes
- Optimize file size without sacrificing visual quality

### Sprite Sheets
Sprite sheets contain animation frames for characters and animated objects.

**Specifications:**
- **Format**: PNG with transparency
- **Layout**: Grid of equal-sized frames
- **Frame Order**: Left-to-right, top-to-bottom
- **Naming Convention**: `character_name.png` (e.g., `player_walk.png`, `npc_idle.png`)

**Best Practices:**
- Keep all frames the same size for consistent animation
- Include transparent padding around sprites for smooth movement
- Group related animations (idle, walk, talk) in separate sheets
- Document frame counts and animation speeds

**Example Layout:**
```
Frame 1 | Frame 2 | Frame 3 | Frame 4
Frame 5 | Frame 6 | Frame 7 | Frame 8
```

### Item Icons
Icons represent inventory items and interactive objects.

**Specifications:**
- **Recommended Sizes**: 
  - Small: 64x64 pixels (inventory thumbnails)
  - Medium: 128x128 pixels (standard icons)
  - Large: 256x256 pixels (detailed view)
- **Format**: PNG with transparency
- **Naming Convention**: `item_name.png` (e.g., `key_gold.png`, `book_ancient.png`)

**Best Practices:**
- Create icons with clear silhouettes for easy recognition
- Use consistent lighting and style across all icons
- Include transparent backgrounds
- Consider creating multiple sizes for different UI contexts

### Character Portraits
Portraits show character emotions during dialogue sequences.

**Specifications:**
- **Recommended Sizes**: 
  - Small: 256x256 pixels (dialogue boxes)
  - Large: 512x512 pixels (character screens)
- **Format**: PNG with transparency
- **Naming Convention**: `character_emotion.png` (e.g., `player_happy.png`, `detective_thinking.png`)

**Best Practices:**
- Maintain consistent positioning across emotions
- Use transparent backgrounds for flexible UI integration
- Create a base set of emotions: neutral, happy, sad, angry, surprised, thinking
- Keep lighting and style consistent across all portraits

## Audio Assets

### General Audio Requirements
- **Formats**: OGG Vorbis (recommended), WAV
- **Sample Rate**: 44.1 kHz or 48 kHz
- **Bit Depth**: 16-bit or 24-bit
- **Channels**: Mono or Stereo

### Music Tracks
Background music sets the mood and atmosphere for your game.

**Specifications:**
- **Format**: OGG Vorbis
- **Bitrate**: 128-192 kbps (balances quality and file size)
- **Looping**: Create seamless loop points for continuous playback
- **Duration**: 2-5 minutes for looping tracks

**Common Track Types:**
1. **Main Theme** (`main_theme.ogg`)
   - Used for main menu and title screen
   - Should be memorable and set the game's tone

2. **Area Themes** (`area_name.ogg`)
   - Unique music for different locations
   - Examples: `castle_ambient.ogg`, `forest_ambient.ogg`, `village_ambient.ogg`

3. **Situation Music** (`situation.ogg`)
   - For specific game states
   - Examples: `tension.ogg`, `victory.ogg`, `puzzle_solving.ogg`

**Best Practices:**
- Ensure smooth looping with no clicks or pops
- Keep volume levels consistent across tracks
- Use appropriate compression to reduce file size
- Consider dynamic music that changes with game state

### Sound Effects
Sound effects provide audio feedback for player actions and game events.

**Specifications:**
- **Format**: OGG or WAV
- **Duration**: Keep short (typically < 5 seconds)
- **Volume**: Normalized to prevent clipping

**Essential Sound Effects:**

1. **UI Sounds**
   - `click.ogg` - Button clicks
   - `hover.ogg` - Mouse hover
   - `dialog_open.ogg` - Dialog appears
   - `dialog_close.ogg` - Dialog closes
   - `menu_navigate.ogg` - Menu navigation

2. **Interaction Sounds**
   - `door_open.ogg` - Opening doors
   - `door_close.ogg` - Closing doors
   - `pickup.ogg` - Collecting items
   - `use_item.ogg` - Using inventory items
   - `combine_items.ogg` - Combining items

3. **Movement Sounds**
   - `footstep_1.ogg` - Walking on hard surfaces
   - `footstep_2.ogg` - Walking on soft surfaces
   - `footstep_grass.ogg` - Walking on grass
   - `footstep_gravel.ogg` - Walking on gravel

4. **Feedback Sounds**
   - `success.ogg` - Positive feedback
   - `error.ogg` - Negative feedback
   - `notification.ogg` - General alerts
   - `achievement.ogg` - Goal completion

**Best Practices:**
- Keep effects short and punchy
- Avoid effects that become annoying with repetition
- Create variations for frequently used sounds
- Normalize volume levels across all effects

### Ambient Sounds
Ambient sounds create atmosphere and bring scenes to life.

**Specifications:**
- **Format**: OGG Vorbis
- **Duration**: 1-5 minutes (loopable)
- **Volume**: Lower than music and effects

**Common Ambient Sounds:**
- `birds.ogg` - Outdoor bird sounds
- `wind.ogg` - Wind atmosphere
- `fire_crackling.ogg` - Fireplace ambiance
- `water_flow.ogg` - Fountains or streams
- `crowd_chatter.ogg` - Distant conversations
- `rain.ogg` - Rain atmosphere
- `thunder.ogg` - Storm sounds
- `clock_ticking.ogg` - Interior atmosphere

**Best Practices:**
- Create seamless loops
- Layer multiple ambients for rich soundscapes
- Keep volume subtle to avoid overwhelming
- Match ambients to visual environment

## Asset Organization

Recommended directory structure:

```
assets/
├── images/
│   ├── backgrounds/
│   │   ├── mansion_entrance.png
│   │   ├── garden.png
│   │   └── library.png
│   ├── sprites/
│   │   ├── player_walk.png
│   │   ├── player_idle.png
│   │   └── npc_detective.png
│   ├── items/
│   │   ├── key_gold.png
│   │   ├── book_ancient.png
│   │   └── potion_health.png
│   ├── portraits/
│   │   ├── player_happy.png
│   │   ├── player_sad.png
│   │   └── detective_thinking.png
│   └── ui/
│       ├── button_normal.png
│       ├── button_hover.png
│       └── inventory_slot.png
├── audio/
│   ├── music/
│   │   ├── main_theme.ogg
│   │   ├── castle_ambient.ogg
│   │   └── tension.ogg
│   ├── effects/
│   │   ├── click.ogg
│   │   ├── door_open.ogg
│   │   └── pickup.ogg
│   └── ambient/
│       ├── birds.ogg
│       ├── wind.ogg
│       └── fire_crackling.ogg
└── fonts/
    ├── main_font.ttf
    └── dialog_font.ttf
```

## File Format Specifications

### Converting Audio Files

**To OGG Vorbis (recommended):**
```bash
# Using FFmpeg
ffmpeg -i input.wav -c:a libvorbis -q:a 5 output.ogg

# Quality settings:
# -q:a 0 = ~64 kbps (lowest quality)
# -q:a 5 = ~160 kbps (recommended)
# -q:a 10 = ~500 kbps (highest quality)
```

### Image Optimization

**PNG Optimization:**
```bash
# Using optipng
optipng -o5 image.png

# Using pngquant for lossy compression
pngquant --quality=65-80 image.png
```

**Batch Processing:**
```bash
# Convert all WAV files to OGG
for f in *.wav; do ffmpeg -i "$f" -c:a libvorbis -q:a 5 "${f%.wav}.ogg"; done

# Optimize all PNG files
for f in *.png; do optipng -o5 "$f"; done
```

## Best Practices

### Performance Optimization

1. **Image Optimization:**
   - Use appropriate formats (PNG for UI/sprites, JPG for backgrounds)
   - Compress images without visible quality loss
   - Consider texture atlases for multiple small images
   - Implement lazy loading for large assets

2. **Audio Optimization:**
   - Use OGG Vorbis for music (smaller than WAV)
   - Keep sound effects short and compressed
   - Stream large music files instead of loading entirely
   - Use mono for centered sounds, stereo for music

3. **Memory Management:**
   - Load assets on demand
   - Unload unused assets
   - Reuse common assets across scenes
   - Implement asset pooling for frequently used items

### Quality Guidelines

1. **Visual Consistency:**
   - Maintain consistent art style across all assets
   - Use a unified color palette
   - Keep lighting direction consistent
   - Match pixel density across sprites

2. **Audio Consistency:**
   - Normalize audio levels across all files
   - Use consistent acoustic space (reverb/ambience)
   - Match musical key/tempo for smooth transitions
   - Keep sound effect style cohesive

3. **Technical Standards:**
   - Always include source files (PSD, AI, project files)
   - Document asset specifications
   - Version control binary assets appropriately
   - Create asset manifests for easy tracking

### Accessibility Considerations

1. **Visual Accessibility:**
   - Provide high contrast versions when possible
   - Avoid relying solely on color for information
   - Include clear, readable fonts
   - Support multiple resolution options

2. **Audio Accessibility:**
   - Provide subtitles for dialogue
   - Include visual cues for important sounds
   - Allow separate volume controls
   - Avoid frequencies that cause discomfort

## Resource Optimization

### File Size Guidelines

**Target Sizes (compressed):**
- Backgrounds: 200-500 KB per image
- Sprite sheets: 100-300 KB per sheet
- Item icons: 10-50 KB per icon
- Character portraits: 50-150 KB per portrait
- Music tracks: 2-5 MB per track
- Sound effects: 10-100 KB per effect
- Ambient sounds: 500 KB - 2 MB per loop

### Loading Strategies

1. **Preloading:**
   - Main menu assets
   - Common UI elements
   - Frequently used sound effects

2. **Lazy Loading:**
   - Scene-specific backgrounds
   - Character sprites for NPCs
   - Area-specific music

3. **Streaming:**
   - Long music tracks
   - Cutscene videos
   - Large ambient loops

### Platform Considerations

1. **Desktop (Windows/Mac/Linux):**
   - Can handle larger file sizes
   - Support for high resolutions
   - Full audio quality

2. **Web (Browser-based):**
   - Optimize for download size
   - Consider WebP for images
   - Use Web Audio API compatible formats

3. **Mobile (if applicable):**
   - Reduce texture sizes
   - Lower audio bitrates
   - Consider device memory limits

## Asset Creation Resources

### Recommended Tools

**Image Creation:**
- Aseprite (pixel art)
- Krita (digital painting)
- GIMP (general image editing)
- Inkscape (vector graphics)

**Audio Creation:**
- Audacity (audio editing)
- LMMS (music creation)
- Reaper (professional DAW)
- sfxr/Bfxr (retro sound effects)

### Free Asset Sources

**Images:**
- OpenGameArt.org
- Itch.io (free assets section)
- Kenney.nl
- CraftPix.net (free section)

**Audio:**
- Freesound.org
- OpenGameArt.org (audio section)
- Zapsplat.com (free with account)
- Incompetech.com (royalty-free music)

**Important:** Always check licensing terms and provide proper attribution when required.

## Conclusion

Following these guidelines ensures your game assets are optimized, consistent, and professional. Remember to:

1. Plan your asset requirements early
2. Maintain consistency across all assets
3. Optimize for performance without sacrificing quality
4. Test assets in-game regularly
5. Keep source files and documentation

Well-crafted assets are crucial for creating an immersive and polished gaming experience. Take time to get them right, and your game will benefit greatly from the attention to detail.