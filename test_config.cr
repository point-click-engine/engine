require "./src/core/game_config"

yaml = File.read("crystal_mystery/game_config.yaml")
puts "YAML content around line 19:"
lines = yaml.split('\n')
(17..21).each do |i|
  puts "#{i}: #{lines[i-1]? || "(no line)"}"
end

begin
  config = PointClickEngine::Core::GameConfig.from_yaml(yaml)
  puts "Config loaded successfully!"
rescue ex
  puts "Error: #{ex.message}"
  puts ex.backtrace.join("\n")
end