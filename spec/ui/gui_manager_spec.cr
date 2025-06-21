require "../spec_helper"
require "../../src/ui/gui_manager"

describe PointClickEngine::UI::GUIManager do
  describe "#initialize" do
    it "creates an empty GUI manager" do
      gui = PointClickEngine::UI::GUIManager.new
      gui.labels.should be_empty
      gui.buttons.should be_empty
      gui.visible.should be_true
    end
  end

  describe "#add_label" do
    it "adds a label with specified properties" do
      gui = PointClickEngine::UI::GUIManager.new
      pos = Raylib::Vector2.new(x: 100f32, y: 50f32)

      gui.add_label("test_label", "Hello", pos, 24, Raylib::RED)

      gui.labels.size.should eq(1)
      label = gui.labels["test_label"]
      label.text.should eq("Hello")
      label.position.x.should eq(100f32)
      label.position.y.should eq(50f32)
      label.font_size.should eq(24)
      label.color.should eq(Raylib::RED)
    end

    it "adds label with default values" do
      gui = PointClickEngine::UI::GUIManager.new
      pos = Raylib::Vector2.new(x: 0f32, y: 0f32)

      gui.add_label("default", "Text", pos)

      label = gui.labels["default"]
      label.font_size.should eq(20)
      label.color.should eq(Raylib::WHITE)
    end
  end

  describe "#add_button" do
    it "adds a button with callback" do
      gui = PointClickEngine::UI::GUIManager.new
      pos = Raylib::Vector2.new(x: 10f32, y: 20f32)
      size = Raylib::Vector2.new(x: 100f32, y: 40f32)

      clicked = false
      gui.add_button("test_btn", "Click Me", pos, size) do
        clicked = true
      end

      gui.buttons.size.should eq(1)
      button = gui.buttons["test_btn"]
      button.text.should eq("Click Me")
      button.position.x.should eq(10f32)
      button.size.x.should eq(100f32)

      # Test callback
      button.callback.call
      clicked.should be_true
    end
  end

  describe "#remove_label" do
    it "removes a label by id" do
      gui = PointClickEngine::UI::GUIManager.new
      pos = Raylib::Vector2.new(x: 0f32, y: 0f32)

      gui.add_label("temp", "Temporary", pos)
      gui.labels.size.should eq(1)

      gui.remove_label("temp")
      gui.labels.size.should eq(0)
    end
  end

  describe "#remove_button" do
    it "removes a button by id" do
      gui = PointClickEngine::UI::GUIManager.new
      pos = Raylib::Vector2.new(x: 0f32, y: 0f32)
      size = Raylib::Vector2.new(x: 0f32, y: 0f32)

      gui.add_button("temp", "Remove Me", pos, size) { }
      gui.buttons.size.should eq(1)

      gui.remove_button("temp")
      gui.buttons.size.should eq(0)
    end
  end

  describe "#clear" do
    it "removes all labels and buttons" do
      gui = PointClickEngine::UI::GUIManager.new
      pos = Raylib::Vector2.new(x: 0f32, y: 0f32)
      size = Raylib::Vector2.new(x: 0f32, y: 0f32)

      gui.add_label("label1", "Text1", pos)
      gui.add_label("label2", "Text2", pos)
      gui.add_button("btn1", "Button1", pos, size) { }
      gui.add_button("btn2", "Button2", pos, size) { }

      gui.labels.size.should eq(2)
      gui.buttons.size.should eq(2)

      gui.clear

      gui.labels.size.should eq(0)
      gui.buttons.size.should eq(0)
    end
  end

  describe "#show and #hide" do
    it "toggles visibility" do
      gui = PointClickEngine::UI::GUIManager.new

      gui.visible.should be_true

      gui.hide
      gui.visible.should be_false

      gui.show
      gui.visible.should be_true
    end
  end

  describe "Label" do
    it "is visible by default" do
      pos = Raylib::Vector2.new(x: 0f32, y: 0f32)
      label = PointClickEngine::UI::GUIManager::Label.new("Test", pos, 20, Raylib::WHITE)
      label.visible.should be_true
    end
  end

  describe "Button" do
    it "tracks hover and pressed states" do
      pos = Raylib::Vector2.new(x: 0f32, y: 0f32)
      size = Raylib::Vector2.new(x: 100f32, y: 50f32)

      button = PointClickEngine::UI::GUIManager::Button.new("Test", pos, size) { }

      button.hovered.should be_false
      button.pressed.should be_false
    end

    it "calculates bounds correctly" do
      pos = Raylib::Vector2.new(x: 10f32, y: 20f32)
      size = Raylib::Vector2.new(x: 100f32, y: 50f32)

      button = PointClickEngine::UI::GUIManager::Button.new("Test", pos, size) { }
      bounds = button.bounds

      bounds.x.should eq(10f32)
      bounds.y.should eq(20f32)
      bounds.width.should eq(100f32)
      bounds.height.should eq(50f32)
    end
  end
end
