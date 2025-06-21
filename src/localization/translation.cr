module PointClickEngine
  module Localization
    # Translation entry with support for pluralization and interpolation
    class Translation
      property key : String
      property translations : Hash(Locale, String | Hash(String, String))

      def initialize(@key : String)
        @translations = {} of Locale => String | Hash(String, String)
      end

      def add_translation(locale : Locale, value : String)
        @translations[locale] = value
      end

      def add_plural_forms(locale : Locale, forms : Hash(String, String))
        @translations[locale] = forms
      end

      def get(locale : Locale, count : Int32? = nil, params : Hash(String, String)? = nil) : String
        translation = @translations[locale]? || @translations[Locale::En_US]? || @key

        result = case translation
                 when String
                   translation
                 when Hash(String, String)
                   # Handle pluralization
                   if count
                     form = get_plural_form(locale, count)
                     translation[form]? || translation["other"]? || @key
                   else
                     translation["other"]? || @key
                   end
                 else
                   @key
                 end

        # Handle interpolation
        if params
          params.each do |key, value|
            result = result.gsub("{{#{key}}}", value)
          end
        end

        result
      end

      private def get_plural_form(locale : Locale, count : Int32) : String
        case locale
        when .en_us?, .de_de?, .es_es?, .it_it?, .pt_br?
          # Most European languages: singular for 1, plural otherwise
          count == 1 ? "one" : "other"
        when .fr_fr?
          # French: singular for 0 and 1, plural otherwise
          count <= 1 ? "one" : "other"
        when .ja_jp?, .zh_cn?
          # Japanese and Chinese: no plural forms
          "other"
        else
          count == 1 ? "one" : "other"
        end
      end
    end
  end
end
