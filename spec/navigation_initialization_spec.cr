require "./spec_helper"

describe "Navigation Initialization" do
  it "initializes navigation when loading scene with pathfinding enabled" do
    # Create a temporary scene YAML file
    scene_yaml = <<-YAML
    name: test_navigation_scene
    background_path: assets/test_bg.png
    logical_width: 800
    logical_height: 600
    enable_pathfinding: true
    navigation_cell_size: 16
    walkable_areas:
      regions:
        - name: main_area
          walkable: true
          vertices:
            - {x: 100, y: 100}
            - {x: 700, y: 100}
            - {x: 700, y: 500}
            - {x: 100, y: 500}
    YAML
    
    # Write to temporary file
    temp_file = File.tempfile("test_scene", ".yaml") do |file|
      file.print(scene_yaml)
    end
    
    begin
      # Load scene using SceneLoader
      scene = PointClickEngine::Scenes::SceneLoader.load_from_yaml(temp_file.path)
      
      # Verify navigation was initialized
      scene.navigation_manager.should_not be_nil
      scene.navigation_grid.should_not be_nil
      scene.pathfinder.should_not be_nil
      
      # Verify navigation grid has walkable cells
      if grid = scene.navigation_grid
        walkable_count = 0
        grid.walkable.each do |row|
          row.each do |cell|
            walkable_count += 1 if cell
          end
        end
        walkable_count.should be > 0
      end
    ensure
      # Clean up temp file
      File.delete(temp_file.path) if File.exists?(temp_file.path)
    end
  end
  
  it "does not initialize navigation when pathfinding is disabled" do
    # Create a scene with pathfinding disabled
    scene_yaml = <<-YAML
    name: test_no_navigation_scene
    background_path: assets/test_bg.png
    enable_pathfinding: false
    walkable_areas:
      regions:
        - name: main_area
          walkable: true
          vertices:
            - {x: 100, y: 100}
            - {x: 700, y: 100}
            - {x: 700, y: 500}
            - {x: 100, y: 500}
    YAML
    
    temp_file = File.tempfile("test_scene", ".yaml") do |file|
      file.print(scene_yaml)
    end
    
    begin
      scene = PointClickEngine::Scenes::SceneLoader.load_from_yaml(temp_file.path)
      
      # Navigation should not be initialized
      scene.navigation_manager.should be_nil
      scene.navigation_grid.should be_nil
      scene.pathfinder.should be_nil
    ensure
      File.delete(temp_file.path) if File.exists?(temp_file.path)
    end
  end
  
  it "provides pathfinding functionality after initialization" do
    RaylibContext.with_window do
      # Create scene with walkable area
      scene = PointClickEngine::Scenes::Scene.new("pathfinding_test")
      scene.logical_width = 800
      scene.logical_height = 600
      scene.enable_pathfinding = true
      
      # Create a simple walkable area
      walkable_area = PointClickEngine::Scenes::WalkableArea.new
      region = PointClickEngine::Scenes::PolygonRegion.new(
        name: "main",
        walkable: true
      )
      region.vertices = [
        vec2(100, 100),
        vec2(700, 100), 
        vec2(700, 500),
        vec2(100, 500)
      ]
      walkable_area.regions << region
      walkable_area.update_bounds
      scene.walkable_area = walkable_area
      
      # Setup navigation
      scene.setup_navigation
      
      # Verify navigation was set up
      scene.navigation_manager.should_not be_nil
      scene.navigation_grid.should_not be_nil
      
      # Debug output
      if nm = scene.navigation_manager
        puts "NavigationManager exists"
        puts "NavigationGrid: #{nm.navigation_grid ? "exists" : "nil"}"
        puts "Pathfinder: #{nm.pathfinder ? "exists" : "nil"}"
      end
      
      # Test pathfinding
      puts "Testing pathfinding from (150,150) to (650,450)"
      path = scene.find_path(150, 150, 650, 450)
      
      if path.nil?
        puts "Path is nil!"
        # Check if the points are walkable
        puts "Is start walkable? #{scene.is_walkable?(vec2(150, 150))}"
        puts "Is end walkable? #{scene.is_walkable?(vec2(650, 450))}"
        
        # Check grid bounds
        if grid = scene.navigation_grid
          puts "Grid size: #{grid.width}x#{grid.height} cells"
          puts "Grid cell size: #{grid.cell_size}"
          start_x, start_y = grid.world_to_grid(150, 150)
          end_x, end_y = grid.world_to_grid(650, 450)
          puts "Start grid coords: (#{start_x}, #{start_y})"
          puts "End grid coords: (#{end_x}, #{end_y})"
          puts "Start walkable in grid? #{grid.is_walkable?(start_x, start_y)}"
          puts "End walkable in grid? #{grid.is_walkable?(end_x, end_y)}"
        end
      else
        puts "Path found with #{path.size} waypoints"
      end
      
      path.should_not be_nil
      path.not_nil!.size.should be > 0
    end
  end
end