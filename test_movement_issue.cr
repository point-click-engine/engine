require "./spec/spec_helper"
require "./src/characters/movement_controller"
require "./src/characters/character"
require "./src/core/game_constants"

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

# Enable debug logging
PointClickEngine::Core::DebugConfig.enable_verbose_logging

# Test the waypoint advancement
puts "Testing waypoint advancement issue..."
character = MockCharacter.new(Raylib::Vector2.new(x: 0.0_f32, y: 0.0_f32))
controller = PointClickEngine::Characters::MovementController.new(character)

# Access private internals for debugging
class PointClickEngine::Characters::MovementController
  def debug_state
    {
      target_position:    @target_position,
      path:               @path,
      current_path_index: @current_path_index,
      character_state:    @character.state,
      character_position: @character.position,
    }
  end
end

waypoints = [
  Raylib::Vector2.new(x: 10.0_f32, y: 0.0_f32), # Close waypoint
  Raylib::Vector2.new(x: 20.0_f32, y: 0.0_f32),
]

puts "\nCalling move_along_path..."
controller.move_along_path(waypoints)
puts "State after move_along_path: #{controller.debug_state}"

# Move enough to reach first waypoint
puts "\nStarting movement updates..."
updates_done = 0
20.times do |i|
  old_position = Raylib::Vector2.new(x: character.position.x, y: character.position.y)
  old_index = controller.current_path_index

  controller.update(0.1_f32)
  updates_done += 1

  if old_position.x != character.position.x || old_position.y != character.position.y || old_index != controller.current_path_index
    puts "Update #{i}: Position changed from #{old_position} to #{character.position}, index: #{old_index} -> #{controller.current_path_index}"
  end

  # Break if we've advanced or stopped
  break if controller.current_path_index >= 1 || character.state != PointClickEngine::Characters::CharacterState::Walking
end

puts "\nFinal state after #{updates_done} updates: #{controller.debug_state}"
puts "Test result: #{controller.current_path_index >= 1 ? "PASSED" : "FAILED"}"
