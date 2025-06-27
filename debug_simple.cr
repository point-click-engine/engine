require "./src/core/game_config"

config_yaml = <<-YAML
game:
  title: "Test Game"
assets:
  audio:
    music:
      theme: "theme.midi"
    sounds:
      click: "click.aiff"
YAML

File.write("simple_test.yaml", config_yaml)
config = PointClickEngine::Core::GameConfig.from_file("simple_test.yaml", skip_preflight: true)

puts "Audio config loaded:"
if audio = config.assets.try(&.audio)
  puts "Music files:"
  audio.music.each { |k, v| puts "  #{k}: #{v}" }
  puts "Sound files:"
  audio.sounds.each { |k, v| puts "  #{k}: #{v}" }

  puts "\nChecking extensions:"
  (audio.music.values + audio.sounds.values).each do |path|
    ext = File.extname(path).downcase
    puts "  #{path} -> #{ext}"
    unless [".wav", ".ogg", ".mp3", ".flac"].includes?(ext)
      puts "    UNSUPPORTED!"
    end
  end
end

File.delete("simple_test.yaml")
