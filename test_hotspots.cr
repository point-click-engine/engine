require "./src/point_click_engine"

# Test loading a scene with hotspots
scene_yaml = <<-YAML
name: test_scene
background_path: crystal_mystery/assets/backgrounds/library.png
hotspots:
  - name: test_hotspot
    x: 100
    y: 200
    width: 150
    height: 300
    description: "Test hotspot"
  - name: desk
    x: 400
    y: 400
    width: 200
    height: 150
    description: "A desk"
YAML

File.write("test_scene.yaml", scene_yaml)
scene = PointClickEngine::Scenes::SceneLoader.load_from_yaml("test_scene.yaml")
File.delete("test_scene.yaml")

puts "Scene loaded: #{scene.name}"
puts "Background: #{scene.background_path}"
puts "Hotspots count: #{scene.hotspots.size}"
scene.hotspots.each do |hotspot|
  puts "  - #{hotspot.name} at (#{hotspot.position.x}, #{hotspot.position.y}) size: (#{hotspot.size.x}, #{hotspot.size.y})"
end