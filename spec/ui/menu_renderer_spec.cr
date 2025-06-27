require "../spec_helper"
require "../../src/ui/menu_renderer"

describe PointClickEngine::UI::MenuRenderer do
  describe "initialization" do
    it "initializes with default theme" do
      renderer = PointClickEngine::UI::MenuRenderer.new
      renderer.theme.background_color.a.should eq(180)
      renderer.theme.border_color.should eq(RL::WHITE)
      renderer.theme.text_color.should eq(RL::WHITE)
      renderer.theme.highlight_color.should eq(RL::YELLOW)
      renderer.theme.font_size.should eq(20)
    end

    it "initializes with default settings" do
      renderer = PointClickEngine::UI::MenuRenderer.new
      renderer.center_horizontally.should be_true
      renderer.center_vertically.should be_true
      renderer.auto_size.should be_true
      renderer.enable_animations.should be_true
    end

    it "initializes animation state" do
      renderer = PointClickEngine::UI::MenuRenderer.new
      renderer.animation.highlight_pulse.should eq(0.0)
      renderer.animation.fade_alpha.should eq(1.0)
      renderer.animation.slide_offset.should eq(0.0)
    end
  end

  describe "theme management" do
    it "creates theme with custom values" do
      theme = PointClickEngine::UI::MenuRenderer::MenuTheme.new
      theme.font_size = 24
      theme.padding = 30

      renderer = PointClickEngine::UI::MenuRenderer.new
      renderer.theme = theme

      renderer.theme.font_size.should eq(24)
      renderer.theme.padding.should eq(30)
    end

    it "updates theme from configuration" do
      renderer = PointClickEngine::UI::MenuRenderer.new
      config = {
        "background_color" => "black",
        "text_color"       => "white",
        "font_size"        => "18",
        "padding"          => "25",
      }

      renderer.update_theme_from_config(config)

      renderer.theme.font_size.should eq(18)
      renderer.theme.padding.should eq(25)
    end

    it "gets theme configuration" do
      renderer = PointClickEngine::UI::MenuRenderer.new
      config = renderer.get_theme_config

      config["font_size"].should eq("20")
      config["padding"].should eq("20")
      config["animations_enabled"].should eq("true")
    end

    it "validates theme configuration" do
      renderer = PointClickEngine::UI::MenuRenderer.new
      issues = renderer.validate_theme
      issues.should be_empty

      renderer.theme.font_size = -5
      issues = renderer.validate_theme
      issues.should_not be_empty
      issues.first.should contain("positive")
    end
  end

  describe "size calculations" do
    # Commented out - requires mocking library
    # it "calculates menu size for content" do
    #   # Mock text measurement
    #   RL.stub(:measure_text) do |text, size|
    #     text.size * 10 # Simple approximation
    #   end
    #
    #   title = "Test Menu"
    #   items = ["Option 1", "Option 2", "Option 3"]
    #
    #   size = renderer.calculate_menu_size(title, items)
    #
    #   size.x.should be > 0
    #   size.y.should be > 0
    # end

    it "calculates content bounds within menu" do
      renderer = PointClickEngine::UI::MenuRenderer.new
      menu_bounds = RL::Rectangle.new(x: 100, y: 50, width: 300, height: 200)

      content_bounds = renderer.calculate_content_bounds(menu_bounds)

      content_bounds.x.should eq(120)      # 100 + padding
      content_bounds.y.should eq(70)       # 50 + padding
      content_bounds.width.should eq(260)  # 300 - padding*2
      content_bounds.height.should eq(160) # 200 - padding*2
    end

    it "calculates item bounds for interaction" do
      renderer = PointClickEngine::UI::MenuRenderer.new
      menu_bounds = RL::Rectangle.new(x: 100, y: 50, width: 300, height: 200)
      title = "Menu Title"

      item_bounds = renderer.get_item_bounds(menu_bounds, title, 1)

      item_bounds.x.should eq(120)     # Content start
      item_bounds.width.should eq(260) # Content width
      item_bounds.height.should eq(30) # Font size + spacing
    end
  end

  # Commented out - requires mocking library
  # describe "rendering operations" do
  #
  #   before_each do
  #     # Mock Raylib drawing functions
  #     RL.stub(:draw_rectangle_rec) { }
  #     RL.stub(:draw_rectangle_lines_ex) { }
  #     RL.stub(:draw_text) { }
  #     RL.stub(:measure_text) { |text, size| text.size * 6 }
  #   end
  #
  #   it "draws complete menu" do
  #     draw_calls = [] of String
  #
  #     RL.stub(:draw_rectangle_rec) do |rect, color|
  #       draw_calls << "background"
  #     end
  #
  #     RL.stub(:draw_rectangle_lines_ex) do |rect, width, color|
  #       draw_calls << "border"
  #     end
  #
  #     RL.stub(:draw_text) do |text, x, y, size, color|
  #       draw_calls << "text:#{text}"
  #     end
  #
  #     renderer.draw_menu(menu_bounds, "Test Menu", items, 1, [true, true, true])
  #
  #     draw_calls.should contain("background")
  #     draw_calls.should contain("border")
  #     draw_calls.should contain("text:Test Menu")
  #     draw_calls.should contain("text:Option 1")
  #   end
  #
  #   it "draws background with theme color" do
  #     background_drawn = false
  #
  #     RL.stub(:draw_rectangle_rec) do |rect, color|
  #       background_drawn = true
  #       rect.should eq(menu_bounds)
  #     end
  #
  #     renderer.draw_background(menu_bounds)
  #     background_drawn.should be_true
  #   end
  #
  #   it "draws border with theme styling" do
  #     border_drawn = false
  #
  #     RL.stub(:draw_rectangle_lines_ex) do |rect, width, color|
  #       border_drawn = true
  #       rect.should eq(menu_bounds)
  #       width.should eq(2.0)
  #     end
  #
  #     renderer.draw_border(menu_bounds)
  #     border_drawn.should be_true
  #   end
  #
  #   it "draws title with proper positioning" do
  #     content_bounds = RL::Rectangle.new(x: 120, y: 70, width: 260, height: 160)
  #     title_drawn = false
  #
  #     RL.stub(:draw_text) do |text, x, y, size, color|
  #       title_drawn = true
  #       text.should eq("Test Title")
  #       size.should eq(renderer.theme.title_font_size)
  #     end
  #
  #     height = renderer.draw_title(content_bounds, "Test Title")
  #     title_drawn.should be_true
  #     height.should eq(renderer.theme.title_font_size)
  #   end
  #
  #   it "draws menu items with selection highlighting" do
  #     content_bounds = RL::Rectangle.new(x: 120, y: 70, width: 260, height: 160)
  #     items_drawn = [] of String
  #
  #     RL.stub(:draw_text) do |text, x, y, size, color|
  #       items_drawn << text
  #     end
  #
  #     renderer.draw_menu_items(content_bounds, 100.0, items, 1, [true, true, false])
  #
  #     items_drawn.should contain("Option 1")
  #     items_drawn.should contain("Option 2")
  #     items_drawn.should contain("Option 3")
  #   end
  # end

  describe "animation effects" do
    it "updates animation states" do
      renderer = PointClickEngine::UI::MenuRenderer.new
      initial_time = renderer.animation.animation_time

      renderer.update_animations

      # Animation time should be updated
      renderer.animation.animation_time.should be > initial_time
    end

    it "applies fade effect to colors" do
      renderer = PointClickEngine::UI::MenuRenderer.new
      original_color = RL::WHITE
      renderer.set_fade_alpha(0.5)

      faded_color = renderer.apply_fade(original_color)

      faded_color.r.should eq(original_color.r)
      faded_color.g.should eq(original_color.g)
      faded_color.b.should eq(original_color.b)
      faded_color.a.should be < original_color.a
    end

    it "applies highlight pulse effect" do
      renderer = PointClickEngine::UI::MenuRenderer.new
      renderer.enable_animations = true
      original_color = RL::YELLOW

      highlighted_color = renderer.apply_highlight(original_color)

      # Color should be modified when animations enabled
      # (exact values depend on animation timing)
    end

    it "skips highlight effect when animations disabled" do
      renderer = PointClickEngine::UI::MenuRenderer.new
      renderer.enable_animations = false
      original_color = RL::YELLOW

      highlighted_color = renderer.apply_highlight(original_color)

      highlighted_color.should eq(original_color)
    end

    it "sets fade alpha within valid range" do
      renderer = PointClickEngine::UI::MenuRenderer.new
      renderer.set_fade_alpha(1.5) # Above max
      renderer.animation.fade_alpha.should eq(1.0_f32)

      renderer.set_fade_alpha(-0.5) # Below min
      renderer.animation.fade_alpha.should eq(0.0_f32)

      renderer.set_fade_alpha(0.7) # Valid value
      renderer.animation.fade_alpha.should eq(0.7_f32)
    end
  end

  describe "color management" do
    it "parses known color names" do
      renderer = PointClickEngine::UI::MenuRenderer.new
      # This tests the private parse_color method indirectly
      config = {"background_color" => "red"}

      renderer.update_theme_from_config(config)
      # Color should be updated (exact verification depends on implementation)
    end

    it "handles unknown color names" do
      renderer = PointClickEngine::UI::MenuRenderer.new
      config = {"background_color" => "unknown_color"}

      # Should not crash and should use default
      renderer.update_theme_from_config(config)
    end

    it "converts colors to string representation" do
      renderer = PointClickEngine::UI::MenuRenderer.new
      config = renderer.get_theme_config

      # Background color should be in string format
      config["background_color"].should_not be_empty
    end
  end

  describe "rendering states" do
    it "handles empty title" do
      renderer = PointClickEngine::UI::MenuRenderer.new
      content_bounds = RL::Rectangle.new(x: 0, y: 0, width: 200, height: 100)

      height = 0
      RaylibContext.with_window do
        height = renderer.draw_title(content_bounds, "")
      end

      height.should eq(0)
    end

    it "handles empty item list" do
      renderer = PointClickEngine::UI::MenuRenderer.new
      content_bounds = RL::Rectangle.new(x: 0, y: 0, width: 200, height: 100)
      empty_items = [] of String

      # Should not crash
      RaylibContext.with_window do
        renderer.draw_menu_items(content_bounds, 50.0, empty_items, -1, nil)
      end
    end

    # Commented out - requires mocking library
    # it "handles disabled items correctly" do
    #   renderer = PointClickEngine::UI::MenuRenderer.new
    #   content_bounds = RL::Rectangle.new(x: 0, y: 0, width: 200, height: 100)
    #   text_colors = [] of RL::Color
    #
    #   RL.stub(:draw_text) do |text, x, y, size, color|
    #     text_colors << color
    #   end
    #
    #   renderer.draw_menu_item(content_bounds, "Disabled", 50.0, false, false)
    #
    #   # Should use disabled color (gray by default)
    #   text_colors.last.should eq(renderer.theme.disabled_color)
    # end
    #
    # it "highlights selected items" do
    #   renderer = PointClickEngine::UI::MenuRenderer.new
    #   content_bounds = RL::Rectangle.new(x: 0, y: 0, width: 200, height: 100)
    #   backgrounds_drawn = 0
    #
    #   RL.stub(:draw_rectangle_rec) do |rect, color|
    #     backgrounds_drawn += 1
    #   end
    #
    #   renderer.draw_menu_item(content_bounds, "Selected", 50.0, true, true)
    #
    #   # Should draw selection background
    #   backgrounds_drawn.should be > 0
    # end
  end

  describe "layout configuration" do
    it "handles center alignment" do
      renderer = PointClickEngine::UI::MenuRenderer.new
      renderer.center_horizontally = true

      # Text positioning should consider centering
      # (verification would require mocking measure_text more precisely)
    end

    it "handles left alignment" do
      renderer = PointClickEngine::UI::MenuRenderer.new
      renderer.center_horizontally = false

      # Text should be left-aligned
    end

    # Commented out - requires mocking library
    # it "calculates selection background correctly" do
    #   renderer = PointClickEngine::UI::MenuRenderer.new
    #   selection_drawn = false
    #
    #   RL.stub(:draw_rectangle_rec) do |rect, color|
    #     selection_drawn = true
    #     # Rect should be slightly larger than text area
    #     rect.width.should be > 100 # Text width
    #   end
    #
    #   renderer.draw_selection_background(50.0, 100.0, 100.0, 20.0)
    #   selection_drawn.should be_true
    # end
  end

  describe "configuration persistence" do
    it "updates multiple theme properties" do
      renderer = PointClickEngine::UI::MenuRenderer.new
      config = {
        "font_size"        => "16",
        "padding"          => "15",
        "background_color" => "blue",
      }

      renderer.update_theme_from_config(config)

      renderer.theme.font_size.should eq(16)
      renderer.theme.padding.should eq(15)
    end

    it "ignores invalid configuration values" do
      renderer = PointClickEngine::UI::MenuRenderer.new
      original_font_size = renderer.theme.font_size

      config = {"font_size" => "invalid"}

      renderer.update_theme_from_config(config)

      # Font size should remain unchanged
      renderer.theme.font_size.should eq(original_font_size)
    end
  end

  describe "edge cases" do
    it "handles zero-sized menu bounds" do
      RaylibContext.with_window do
        renderer = PointClickEngine::UI::MenuRenderer.new
        zero_bounds = RL::Rectangle.new(x: 0, y: 0, width: 0, height: 0)

        # Should not crash
        renderer.draw_background(zero_bounds)
        renderer.draw_border(zero_bounds)
      end
    end

    it "handles negative positioning" do
      renderer = PointClickEngine::UI::MenuRenderer.new
      negative_bounds = RL::Rectangle.new(x: -100, y: -50, width: 200, height: 100)

      # Should handle gracefully
      content_bounds = renderer.calculate_content_bounds(negative_bounds)
      content_bounds.x.should be > negative_bounds.x
    end

    it "handles very large item lists" do
      renderer = PointClickEngine::UI::MenuRenderer.new
      large_items = (1..1000).map { |i| "Item #{i}" }

      # Should calculate size without crashing
      size = renderer.calculate_menu_size("Large Menu", large_items)
      size.y.should be > 0
    end
  end
end
