require "./spec/spec_helper"
require "./src/characters/movement_controller"
require "./src/characters/character"

# Mock character class for testing
class MockCharacter < PointClickEngine::Characters::Character
  def initialize(position : Raylib::Vector2, @walking_speed : Float32 = 100.0_f32)
    super("TestCharacter", position, Raylib::Vector2.new(x: 32.0_f32, y: 32.0_f32))
    @animation_controller.try(&.add_animation("idle", 0, 1, 0.1_f32, false))
    @animation_controller.try(&.add_animation("walk_left", 1, 4, 0.1_f32, true))
    @animation_controller.try(&.add_animation("walk_right", 5, 4, 0.1_f32, true))
    @animation_controller.try(&.add_animation("walk_up", 9, 4, 0.1_f32, true))
    @animation_controller.try(&.add_animation("walk_down", 13, 4, 0.1_f32, true))
  end

  def on_interact(interactor : PointClickEngine::Characters::Character)
    # Mock implementation
  end

  def on_look
    # Mock implementation
  end

  def on_talk
    # Mock implementation
  end
end

# Test the waypoint advancement
puts "Testing waypoint advancement..."
character = MockCharacter.new(Raylib::Vector2.new(x: 0.0_f32, y: 0.0_f32))
controller = PointClickEngine::Characters::MovementController.new(character)

waypoints = [
  Raylib::Vector2.new(x: 10.0_f32, y: 0.0_f32), # Close waypoint
  Raylib::Vector2.new(x: 20.0_f32, y: 0.0_f32),
]

controller.move_along_path(waypoints)
puts "Initial position: #{character.position}"
puts "Initial path index: #{controller.current_path_index}"
puts "Initial state: #{character.state}"

# Move enough to reach first waypoint
20.times do |i|
  controller.update(0.1_f32)
  distance_to_waypoint = Math.sqrt((character.position.x - waypoints[0].x)**2 + (character.position.y - waypoints[0].y)**2)
  puts "Update #{i}: position=#{character.position}, distance to waypoint=#{distance_to_waypoint}, path_index=#{controller.current_path_index}, state=#{character.state}"

  # Break early if we've advanced
  break if controller.current_path_index >= 1
end

puts "\nFinal position: #{character.position}"
puts "Final path index: #{controller.current_path_index}"
puts "Final state: #{character.state}"
puts "Target was reached: #{controller.current_path_index >= 1}"
