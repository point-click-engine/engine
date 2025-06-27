require "./src/core/preflight_check"

result = PointClickEngine::Core::PreflightCheck.run("audio_test/game.yaml")
puts "Errors:"
result.errors.each { |e| puts "  #{e}" }
puts "\nWarnings:"
result.warnings.each { |w| puts "  #{w}" }
