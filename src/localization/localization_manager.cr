module PointClickEngine
  module Localization
    # Manages translations and localization
    class LocalizationManager
      include YAML::Serializable

      @[YAML::Field(ignore: true)]
      property translations : Hash(String, Translation)
      property current_locale : Locale
      property fallback_locale : Locale

      # Singleton instance
      @@instance : LocalizationManager?

      def self.instance : LocalizationManager
        @@instance ||= new
      end

      def initialize(@current_locale : Locale = Locale::En_US, @fallback_locale : Locale = Locale::En_US)
        @translations = {} of String => Translation
      end

      # Load translations from YAML file
      def load_from_file(path : String)
        content = File.read(path)
        data = YAML.parse(content)

        # Expected format:
        # en-us:
        #   hello: "Hello"
        #   items:
        #     one: "{{count}} item"
        #     other: "{{count}} items"
        # fr-fr:
        #   hello: "Bonjour"
        #   items:
        #     one: "{{count}} objet"
        #     other: "{{count}} objets"

        data.as_h.each do |locale_str, translations|
          if locale = Locale.from_string(locale_str.as_s)
            load_locale_translations(locale, translations)
          end
        end
      end

      # Load translations from a directory (one file per locale)
      def load_from_directory(dir : String)
        Dir.glob("#{dir}/*.yml").each do |file|
          locale_code = File.basename(file, ".yml")
          if locale = Locale.from_string(locale_code)
            load_locale_file(locale, file)
          end
        end
      end

      private def load_locale_file(locale : Locale, path : String)
        content = File.read(path)
        data = YAML.parse(content)
        load_locale_translations(locale, data)
      end

      private def load_locale_translations(locale : Locale, data : YAML::Any)
        data.as_h.each do |key, value|
          key_str = key.as_s
          translation = @translations[key_str]? || Translation.new(key_str)

          case value.raw
          when String
            translation.add_translation(locale, value.as_s)
          when Hash
            # Plural forms
            forms = {} of String => String
            value.as_h.each do |form, text|
              forms[form.as_s] = text.as_s
            end
            translation.add_plural_forms(locale, forms)
          end

          @translations[key_str] = translation
        end
      end

      # Get translated string
      def translate(key : String, count : Int32? = nil, **params) : String
        translation = @translations[key]?
        return key unless translation

        # Convert named arguments to hash
        params_hash = {} of String => String
        params.each do |k, v|
          params_hash[k.to_s] = v.to_s
        end

        # Try current locale first, then fallback
        result = translation.get(@current_locale, count, params_hash)
        if result == key && @current_locale != @fallback_locale
          result = translation.get(@fallback_locale, count, params_hash)
        end

        result
      end

      # Convenience alias
      def t(key : String, count : Int32? = nil, **params) : String
        translate(key, count, **params)
      end

      # Get available locales
      def available_locales : Array(Locale)
        locales = Set(Locale).new
        @translations.each_value do |translation|
          translation.translations.each_key do |locale|
            locales << locale
          end
        end
        locales.to_a.sort_by(&.to_s)
      end

      # Check if a locale is available
      def locale_available?(locale : Locale) : Bool
        available_locales.includes?(locale)
      end

      # Set current locale
      def set_locale(locale : Locale)
        @current_locale = locale if locale_available?(locale)
      end

      # Clear all translations
      def clear
        @translations.clear
      end

      # Add a single translation programmatically
      def add_translation(key : String, locale : Locale, value : String)
        translation = @translations[key]? || Translation.new(key)
        translation.add_translation(locale, value)
        @translations[key] = translation
      end

      # Add plural forms programmatically
      def add_plural_translation(key : String, locale : Locale, forms : Hash(String, String))
        translation = @translations[key]? || Translation.new(key)
        translation.add_plural_forms(locale, forms)
        @translations[key] = translation
      end
    end
  end
end

# Global helper function
def t(key : String, count : Int32? = nil, default : String? = nil, **params) : String
  result = PointClickEngine::Localization::LocalizationManager.instance.translate(key, count, **params)
  # Return default if translation is the same as key (not found)
  result == key && default ? default : result
end
