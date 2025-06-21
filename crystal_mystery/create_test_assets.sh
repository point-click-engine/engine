#!/bin/bash

# Create test assets using ImageMagick (convert) or simple touch commands

echo "Creating test assets..."

# Create directories
mkdir -p assets/{backgrounds,sprites,items,ui,sounds,music,fonts}

# Create test images (1x1 pixel placeholders)
# If ImageMagick is available, create colored rectangles, otherwise just touch files

if command -v convert &> /dev/null; then
    echo "Using ImageMagick to create test images..."
    
    # Backgrounds
    convert -size 1024x768 xc:brown assets/backgrounds/library.png
    convert -size 1024x768 xc:navy assets/backgrounds/laboratory.png  
    convert -size 1024x768 xc:darkgreen assets/backgrounds/garden.png
    
    # Character sprites (simple colored squares)
    convert -size 256x512 xc:transparent -fill gray -draw "rectangle 0,0 256,512" assets/sprites/player.png
    convert -size 256x512 xc:transparent -fill black -draw "rectangle 0,0 256,512" assets/sprites/butler.png
    convert -size 256x512 xc:transparent -fill white -draw "rectangle 0,0 256,512" assets/sprites/scientist.png
    
    # Items
    convert -size 64x64 xc:transparent -fill gold -draw "circle 32,32 32,16" assets/items/brass_key.png
    convert -size 64x64 xc:transparent -fill cyan -draw "polygon 32,8 48,32 32,56 16,32" assets/items/crystal.png
    convert -size 64x64 xc:transparent -fill beige -draw "rectangle 16,16 48,48" assets/items/mysterious_note.png
    convert -size 64x64 xc:transparent -fill lightblue -draw "circle 32,32 32,16" assets/items/crystal_lens.png
    convert -size 64x64 xc:transparent -fill tan -draw "rectangle 16,16 48,48" assets/items/research_notes.png
    
    # UI elements
    convert -size 200x50 xc:darkblue assets/ui/button.png
    convert -size 32x32 xc:white assets/ui/cursor.png
else
    echo "ImageMagick not found, creating empty placeholder files..."
    
    # Create empty files as placeholders
    touch assets/backgrounds/{library,laboratory,garden}.png
    touch assets/sprites/{player,butler,scientist}.png
    touch assets/items/{brass_key,crystal,mysterious_note,crystal_lens,research_notes}.png
    touch assets/ui/{button,cursor}.png
fi

# Create placeholder sound files (empty files)
touch assets/sounds/{item_pickup,unlock,secret_door,puzzle_start,puzzle_solved,crystal_placed}.wav
touch assets/music/{main_theme,garden_theme}.ogg

# Create a simple font file placeholder
touch assets/fonts/game_font.ttf

echo "Test assets created!"