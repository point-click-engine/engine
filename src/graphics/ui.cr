# UI rendering components module

require "./ui/nine_patch"
require "./ui/text_renderer"
require "./ui/dialog_renderer"
require "./ui/inventory_renderer"

module PointClickEngine
  module Graphics
    # UI rendering components for adventure games
    module UI
      # Convenience method to create a button nine-patch
      def self.button(texture_path : String) : NinePatch
        NinePatchPresets.button(texture_path)
      end

      # Convenience method to create a panel nine-patch
      def self.panel(texture_path : String) : NinePatch
        NinePatchPresets.panel(texture_path)
      end

      # Convenience method to create a dialog nine-patch
      def self.dialog(texture_path : String) : NinePatch
        NinePatchPresets.dialog(texture_path)
      end

      # Create a default text renderer
      def self.text_renderer(font_path : String? = nil, size : Int32 = TextRenderer::DEFAULT_FONT_SIZE) : TextRenderer
        renderer = TextRenderer.new
        renderer.load_font(font_path, size) if font_path
        renderer
      end

      # Create a dialog renderer with nine-patch
      def self.dialog_renderer(nine_patch_path : String? = nil) : DialogRenderer
        if path = nine_patch_path
          nine_patch = NinePatch.new(path)
          DialogRenderer.new(nine_patch)
        else
          DialogRenderer.new
        end
      end

      # Create an inventory renderer
      def self.inventory(columns : Int32 = 6, rows : Int32 = 4) : InventoryRenderer
        InventoryRenderer.new(columns, rows)
      end

      # Create a quick inventory (hotbar)
      def self.quick_inventory(slots : Int32 = 8) : QuickInventoryRenderer
        QuickInventoryRenderer.new(slots)
      end
    end
  end
end
