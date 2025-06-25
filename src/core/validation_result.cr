module PointClickEngine
  module Core
    # Result of a validation operation
    class ValidationResult
      getter errors : Array(String)
      getter warnings : Array(String)
      getter infos : Array(String)

      def initialize
        @errors = [] of String
        @warnings = [] of String
        @infos = [] of String
      end

      def add_error(message : String)
        @errors << message
      end

      def add_warning(message : String)
        @warnings << message
      end

      def add_info(message : String)
        @infos << message
      end

      def valid?
        @errors.empty?
      end

      def has_warnings?
        !@warnings.empty?
      end

      def has_info?
        !@infos.empty?
      end

      def summary
        parts = [] of String
        parts << "#{@errors.size} error(s)" if !@errors.empty?
        parts << "#{@warnings.size} warning(s)" if !@warnings.empty?
        parts << "#{@infos.size} info(s)" if !@infos.empty?

        parts.empty? ? "No issues found" : parts.join(", ")
      end

      def to_s(io)
        if !@errors.empty?
          io << "Errors:\n"
          @errors.each { |e| io << "  ❌ " << e << "\n" }
        end

        if !@warnings.empty?
          io << "Warnings:\n"
          @warnings.each { |w| io << "  ⚠️  " << w << "\n" }
        end

        if !@infos.empty?
          io << "Information:\n"
          @infos.each { |i| io << "  ℹ️  " << i << "\n" }
        end
      end
    end
  end
end
