require "./src/core/preflight_check"

Dir.mkdir_p("format_test")

config_yaml = <<-YAML
game:
  title: "Test Game"
assets:
  scenes: ["*.yaml"]
  audio:
    music:
      theme: "theme.midi"
    sounds:
      click: "click.aiff"
YAML

File.write("format_test/game.yaml", config_yaml)
File.write("format_test/theme.midi", "fake midi")
File.write("format_test/click.aiff", "fake aiff")

result = PointClickEngine::Core::PreflightCheck.run("format_test/game.yaml")
puts "Total errors: #{result.errors.size}"
result.errors.each_with_index { |e, i| puts "#{i + 1}. #{e}" }

# Cleanup
File.delete("format_test/game.yaml")
File.delete("format_test/theme.midi")
File.delete("format_test/click.aiff")
Dir.delete("format_test")
