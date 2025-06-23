# Performance monitoring system for the Point & Click Engine

require "./error_handling"
require "./interfaces"

module PointClickEngine
  module Core
    class PerformanceMonitor
      include ErrorHelpers
      include IPerformanceMonitor

      @timings : Hash(String, Float32) = {} of String => Float32
      @start_times : Hash(String, Time::Span) = {} of String => Time::Span
      @metrics : Hash(String, Float32) = {} of String => Float32
      @enabled : Bool = true

      def initialize
        ErrorLogger.info("PerformanceMonitor initialized")
      end

      def start_timing(category : String)
        return unless @enabled
        @start_times[category] = Time.monotonic
      end

      def end_timing(category : String)
        return unless @enabled

        start_time = @start_times[category]?
        return unless start_time

        elapsed = (Time.monotonic - start_time).total_milliseconds.to_f32
        @timings[category] = elapsed
        @start_times.delete(category)

        # Update rolling average
        if existing = @metrics[category]?
          @metrics[category] = (existing * 0.9_f32) + (elapsed * 0.1_f32)
        else
          @metrics[category] = elapsed
        end
      end

      def get_metrics : Hash(String, Float32)
        @metrics.dup
      end

      def reset_metrics
        @metrics.clear
        @timings.clear
        @start_times.clear
      end

      def enable_monitoring
        @enabled = true
      end

      def disable_monitoring
        @enabled = false
      end
    end
  end
end
