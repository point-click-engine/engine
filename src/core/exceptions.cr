module PointClickEngine
  module Core
    class LoadingError < Exception
      getter filename : String?
      getter field : String?

      def initialize(@message : String? = nil, @filename : String? = nil, @field : String? = nil)
        super(@message)
      end
    end

    class ConfigError < LoadingError
      def initialize(message : String, filename : String? = nil, field : String? = nil)
        super("Configuration Error: #{message}", filename, field)
      end
    end

    class AssetError < LoadingError
      getter asset_path : String

      def initialize(message : String, @asset_path : String, filename : String? = nil)
        super("Asset Error: #{message} (asset: #{@asset_path})", filename)
      end
    end

    class SceneError < LoadingError
      getter scene_name : String

      def initialize(message : String, @scene_name : String, field : String? = nil)
        super("Scene Error in '#{@scene_name}': #{message}", "#{@scene_name}.yaml", field)
      end
    end

    class ValidationError < LoadingError
      getter errors : Array(String)

      def initialize(@errors : Array(String), filename : String? = nil)
        message = "Validation failed with #{@errors.size} error(s):\n" + @errors.join("\n")
        super(message, filename)
      end
    end

    class SaveGameError < LoadingError
      def initialize(message : String, filename : String? = nil)
        super("Save Game Error: #{message}", filename)
      end
    end
  end
end
