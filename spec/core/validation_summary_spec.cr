require "../spec_helper"

# Summary specs to ensure the validation system compiles and works
describe "Validation System" do
  it "loads all validation modules" do
    # These should all be defined
    PointClickEngine::Core::LoadingError.should_not be_nil
    PointClickEngine::Core::ConfigError.should_not be_nil
    PointClickEngine::Core::AssetError.should_not be_nil
    PointClickEngine::Core::SceneError.should_not be_nil
    PointClickEngine::Core::ValidationError.should_not be_nil
    PointClickEngine::Core::SaveGameError.should_not be_nil
    
    PointClickEngine::Core::Validators::ConfigValidator.should_not be_nil
    PointClickEngine::Core::Validators::AssetValidator.should_not be_nil
    PointClickEngine::Core::Validators::SceneValidator.should_not be_nil
    
    PointClickEngine::Core::PreflightCheck.should_not be_nil
    PointClickEngine::Core::ErrorReporter.should_not be_nil
  end

  it "can create all exception types" do
    errors = [
      PointClickEngine::Core::LoadingError.new("test"),
      PointClickEngine::Core::ConfigError.new("test", "file.yaml"),
      PointClickEngine::Core::AssetError.new("test", "asset.png"),
      PointClickEngine::Core::SceneError.new("test", "scene"),
      PointClickEngine::Core::ValidationError.new(["error1"], "file.yaml"),
      PointClickEngine::Core::SaveGameError.new("test")
    ]
    
    errors.each { |e| e.should_not be_nil }
  end

  it "can validate a simple config" do
    config_yaml = <<-YAML
    game:
      title: "Test Game"
    YAML
    
    config = PointClickEngine::Core::GameConfig.from_yaml(config_yaml)
    errors = PointClickEngine::Core::Validators::ConfigValidator.validate(config, "test.yaml")
    
    # Basic config should be valid
    errors.should be_empty
  end

  it "can validate scene files" do
    temp_dir = File.tempname("scene_test")
    Dir.mkdir_p(temp_dir)
    temp_file = "#{temp_dir}/test_scene.yaml"
    
    scene_yaml = <<-YAML
    name: test_scene
    background_path: bg.png
    YAML
    
    File.write(temp_file, scene_yaml)
    
    begin
      errors = PointClickEngine::Core::Validators::SceneValidator.validate_scene_file(temp_file)
      errors.should be_empty
    ensure
      FileUtils.rm_rf(temp_dir) if Dir.exists?(temp_dir)
    end
  end

  it "error reporter can report errors without crashing" do
    error = PointClickEngine::Core::ConfigError.new("Test error", "test.yaml")
    
    # Simply test that these methods don't raise exceptions
    # We won't try to capture output in the spec
    PointClickEngine::Core::ErrorReporter.report_loading_error(error)
    PointClickEngine::Core::ErrorReporter.report_warning("Test warning")
    PointClickEngine::Core::ErrorReporter.report_info("Test info")
    PointClickEngine::Core::ErrorReporter.report_success("Test success")
  end

  it "pre-flight check can run" do
    temp_dir = File.tempname("preflight_test")
    Dir.mkdir_p(temp_dir)
    
    begin
      config_yaml = <<-YAML
      game:
        title: "Test Game"
      YAML
      
      config_path = "#{temp_dir}/config.yaml"
      File.write(config_path, config_yaml)
      
      # Just run the check without capturing output
      result = PointClickEngine::Core::PreflightCheck.run(config_path)
      result.should_not be_nil
      result.passed.should be_true
    ensure
      FileUtils.rm_rf(temp_dir) if Dir.exists?(temp_dir)
    end
  end
end