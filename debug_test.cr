require "./src/core/preflight_check"

Dir.mkdir("test_game_dir")

config_yaml = <<-YAML
game:
  title: "Test Game"
window:
  width: 1024
  height: 768
assets:
  scenes: ["*.yaml"]
  audio:
    music:
      theme: "audio/theme.mid"
    sounds:
      click: "sounds/click.aiff"
YAML

File.write("test_game_dir/game.yaml", config_yaml)

result = PointClickEngine::Core::PreflightCheck.run("test_game_dir/game.yaml")

puts "All errors (#{result.errors.size}):"
result.errors.each_with_index { |e, i| puts "#{i + 1}. #{e}" }

puts "\nErrors containing 'Unsupported audio format':"
format_errors = result.errors.select { |e| e.includes?("Unsupported audio format") }
format_errors.each_with_index { |e, i| puts "#{i + 1}. #{e}" }
puts "Count: #{format_errors.size}"

puts "\nErrors containing 'Unsupported':"
unsupported_errors = result.errors.select { |e| e.includes?("Unsupported") }
unsupported_errors.each_with_index { |e, i| puts "#{i + 1}. #{e}" }

# Cleanup
File.delete("test_game_dir/game.yaml")
Dir.delete("test_game_dir")
