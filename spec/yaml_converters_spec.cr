require "./spec_helper"

describe PointClickEngine::Utils::YAMLConverters do
  describe ".vector2_to_yaml and .vector2_from_yaml" do
    it "converts Vector2 to YAML and back" do
      original = RL::Vector2.new(x: 10.5_f32, y: 20.7_f32)
      
      yaml_string = PointClickEngine::Utils::YAMLConverters.vector2_to_yaml(original)
      restored = PointClickEngine::Utils::YAMLConverters.vector2_from_yaml(yaml_string)
      
      restored.x.should eq(10.5_f32)
      restored.y.should eq(20.7_f32)
    end

    it "handles zero values" do
      original = RL::Vector2.new(x: 0_f32, y: 0_f32)
      
      yaml_string = PointClickEngine::Utils::YAMLConverters.vector2_to_yaml(original)
      restored = PointClickEngine::Utils::YAMLConverters.vector2_from_yaml(yaml_string)
      
      restored.x.should eq(0_f32)
      restored.y.should eq(0_f32)
    end

    it "handles negative values" do
      original = RL::Vector2.new(x: -15.3_f32, y: -25.8_f32)
      
      yaml_string = PointClickEngine::Utils::YAMLConverters.vector2_to_yaml(original)
      restored = PointClickEngine::Utils::YAMLConverters.vector2_from_yaml(yaml_string)
      
      restored.x.should eq(-15.3_f32)
      restored.y.should eq(-25.8_f32)
    end
  end

  describe ".color_to_yaml and .color_from_yaml" do
    it "converts Color to YAML and back" do
      original = RL::Color.new(r: 255_u8, g: 128_u8, b: 64_u8, a: 200_u8)
      
      yaml_string = PointClickEngine::Utils::YAMLConverters.color_to_yaml(original)
      restored = PointClickEngine::Utils::YAMLConverters.color_from_yaml(yaml_string)
      
      restored.r.should eq(255_u8)
      restored.g.should eq(128_u8)
      restored.b.should eq(64_u8)
      restored.a.should eq(200_u8)
    end

    it "handles black color" do
      original = RL::Color.new(r: 0_u8, g: 0_u8, b: 0_u8, a: 255_u8)
      
      yaml_string = PointClickEngine::Utils::YAMLConverters.color_to_yaml(original)
      restored = PointClickEngine::Utils::YAMLConverters.color_from_yaml(yaml_string)
      
      restored.r.should eq(0_u8)
      restored.g.should eq(0_u8)
      restored.b.should eq(0_u8)
      restored.a.should eq(255_u8)
    end

    it "handles transparent color" do
      original = RL::Color.new(r: 255_u8, g: 255_u8, b: 255_u8, a: 0_u8)
      
      yaml_string = PointClickEngine::Utils::YAMLConverters.color_to_yaml(original)
      restored = PointClickEngine::Utils::YAMLConverters.color_from_yaml(yaml_string)
      
      restored.r.should eq(255_u8)
      restored.g.should eq(255_u8)
      restored.b.should eq(255_u8)
      restored.a.should eq(0_u8)
    end
  end

  describe ".rectangle_to_yaml and .rectangle_from_yaml" do
    it "converts Rectangle to YAML and back" do
      original = RL::Rectangle.new(x: 10.5_f32, y: 20.7_f32, width: 100.2_f32, height: 50.8_f32)
      
      yaml_string = PointClickEngine::Utils::YAMLConverters.rectangle_to_yaml(original)
      restored = PointClickEngine::Utils::YAMLConverters.rectangle_from_yaml(yaml_string)
      
      restored.x.should eq(10.5_f32)
      restored.y.should eq(20.7_f32)
      restored.width.should eq(100.2_f32)
      restored.height.should eq(50.8_f32)
    end

    it "handles zero-sized rectangle" do
      original = RL::Rectangle.new(x: 0_f32, y: 0_f32, width: 0_f32, height: 0_f32)
      
      yaml_string = PointClickEngine::Utils::YAMLConverters.rectangle_to_yaml(original)
      restored = PointClickEngine::Utils::YAMLConverters.rectangle_from_yaml(yaml_string)
      
      restored.x.should eq(0_f32)
      restored.y.should eq(0_f32)
      restored.width.should eq(0_f32)
      restored.height.should eq(0_f32)
    end

    it "handles negative position" do
      original = RL::Rectangle.new(x: -10_f32, y: -20_f32, width: 50_f32, height: 75_f32)
      
      yaml_string = PointClickEngine::Utils::YAMLConverters.rectangle_to_yaml(original)
      restored = PointClickEngine::Utils::YAMLConverters.rectangle_from_yaml(yaml_string)
      
      restored.x.should eq(-10_f32)
      restored.y.should eq(-20_f32)
      restored.width.should eq(50_f32)
      restored.height.should eq(75_f32)
    end
  end

  describe ".vector2_array_to_yaml and .vector2_array_from_yaml" do
    it "converts array of Vector2 to YAML and back" do
      original = [
        RL::Vector2.new(x: 10_f32, y: 20_f32),
        RL::Vector2.new(x: 30_f32, y: 40_f32),
        RL::Vector2.new(x: 50_f32, y: 60_f32)
      ]
      
      yaml_string = PointClickEngine::Utils::YAMLConverters.vector2_array_to_yaml(original)
      restored = PointClickEngine::Utils::YAMLConverters.vector2_array_from_yaml(yaml_string)
      
      restored.size.should eq(3)
      
      restored[0].x.should eq(10_f32)
      restored[0].y.should eq(20_f32)
      
      restored[1].x.should eq(30_f32)
      restored[1].y.should eq(40_f32)
      
      restored[2].x.should eq(50_f32)
      restored[2].y.should eq(60_f32)
    end

    it "handles empty array" do
      original = [] of RL::Vector2
      
      yaml_string = PointClickEngine::Utils::YAMLConverters.vector2_array_to_yaml(original)
      restored = PointClickEngine::Utils::YAMLConverters.vector2_array_from_yaml(yaml_string)
      
      restored.should be_empty
    end

    it "handles single element array" do
      original = [RL::Vector2.new(x: 42_f32, y: 84_f32)]
      
      yaml_string = PointClickEngine::Utils::YAMLConverters.vector2_array_to_yaml(original)
      restored = PointClickEngine::Utils::YAMLConverters.vector2_array_from_yaml(yaml_string)
      
      restored.size.should eq(1)
      restored[0].x.should eq(42_f32)
      restored[0].y.should eq(84_f32)
    end
  end
end