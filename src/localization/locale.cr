module PointClickEngine
  module Localization
    # Supported locales
    enum Locale
      En_US # English (United States)
      Fr_FR # French (France)
      Es_ES # Spanish (Spain)
      De_DE # German (Germany)
      It_IT # Italian (Italy)
      Pt_BR # Portuguese (Brazil)
      Ja_JP # Japanese (Japan)
      Zh_CN # Chinese (Simplified)

      def to_s : String
        super.downcase.gsub('_', '-')
      end

      def self.from_string(str : String) : Locale?
        normalized = str.upcase.gsub('-', '_')
        parse?(normalized)
      end

      def language_code : String
        to_s.split('-').first
      end

      def country_code : String
        to_s.split('-').last
      end

      def display_name : String
        case self
        when .en_us? then "English"
        when .fr_fr? then "Français"
        when .es_es? then "Español"
        when .de_de? then "Deutsch"
        when .it_it? then "Italiano"
        when .pt_br? then "Português"
        when .ja_jp? then "日本語"
        when .zh_cn? then "中文"
        else              to_s
        end
      end
    end
  end
end
