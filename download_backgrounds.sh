#!/bin/bash

echo "🎨 Creating simple test background images for Crystal Mystery..."

# Create the backgrounds directory
mkdir -p assets/backgrounds

# Create simple colored PNG files using a simple method
# These are basic 1024x768 solid color images

# Library - Blue background
echo "📝 Creating library.png (blue)..."
convert -size 1024x768 xc:darkblue \
  -font Arial -pointsize 48 -fill white -gravity center \
  -annotate +0-100 "Ancient Library" \
  -pointsize 20 -annotate +0+300 "Click on objects to interact" \
  assets/backgrounds/library.png 2>/dev/null || {
  echo "⚠️  ImageMagick not available, creating placeholder..."
  echo "# Library Background Placeholder" > assets/backgrounds/library.png
}

# Laboratory - Green background  
echo "📝 Creating laboratory.png (green)..."
convert -size 1024x768 xc:darkgreen \
  -font Arial -pointsize 48 -fill white -gravity center \
  -annotate +0-100 "Mad Scientist's Lab" \
  -pointsize 20 -annotate +0+300 "Click on objects to interact" \
  assets/backgrounds/laboratory.png 2>/dev/null || {
  echo "⚠️  ImageMagick not available, creating placeholder..."
  echo "# Laboratory Background Placeholder" > assets/backgrounds/laboratory.png
}

# Garden - Brown background
echo "📝 Creating garden.png (brown)..."
convert -size 1024x768 xc:saddlebrown \
  -font Arial -pointsize 48 -fill white -gravity center \
  -annotate +0-100 "Mysterious Garden" \
  -pointsize 20 -annotate +0+300 "Click on objects to interact" \
  assets/backgrounds/garden.png 2>/dev/null || {
  echo "⚠️  ImageMagick not available, creating placeholder..."
  echo "# Garden Background Placeholder" > assets/backgrounds/garden.png
}

echo ""
echo "✅ Background files created!"
echo "📁 Files in assets/backgrounds/:"
ls -la assets/backgrounds/

echo ""
echo "🎮 Now try running the game:"
echo "   ./crystal_mystery_game"
echo ""
echo "💡 If you still see black backgrounds, it means:"
echo "   1. The placeholder files aren't proper PNG images (need ImageMagick)"
echo "   2. The SceneLoader might not be loading backgrounds correctly"
echo "   3. The Scene draw method might not be rendering backgrounds"