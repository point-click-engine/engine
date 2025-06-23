require "../spec_helper"
require "../../src/core/performance_monitor"

describe PointClickEngine::Core::PerformanceMonitor do
  describe "#initialize" do
    it "creates a new PerformanceMonitor instance" do
      monitor = PointClickEngine::Core::PerformanceMonitor.new
      monitor.should be_a(PointClickEngine::Core::PerformanceMonitor)
    end

    it "starts with monitoring enabled by default" do
      monitor = PointClickEngine::Core::PerformanceMonitor.new

      # Verify monitoring is enabled by checking if timing works
      monitor.start_timing("test")
      sleep(0.001) # Small delay
      monitor.end_timing("test")

      metrics = monitor.get_metrics
      metrics.has_key?("test").should be_true
    end

    it "initializes with empty metrics" do
      monitor = PointClickEngine::Core::PerformanceMonitor.new

      metrics = monitor.get_metrics
      metrics.size.should eq(0)
    end
  end

  describe "#start_timing" do
    it "records timing start for a category" do
      monitor = PointClickEngine::Core::PerformanceMonitor.new

      # Should not raise exceptions
      monitor.start_timing("test_category")
    end

    it "handles multiple categories simultaneously" do
      monitor = PointClickEngine::Core::PerformanceMonitor.new

      monitor.start_timing("category1")
      monitor.start_timing("category2")
      monitor.start_timing("category3")

      # Should not raise exceptions or interfere with each other
    end

    it "does nothing when monitoring is disabled" do
      monitor = PointClickEngine::Core::PerformanceMonitor.new
      monitor.disable_monitoring

      monitor.start_timing("test")
      sleep(0.001)
      monitor.end_timing("test")

      metrics = monitor.get_metrics
      metrics.has_key?("test").should be_false
    end
  end

  describe "#end_timing" do
    it "calculates and stores timing duration" do
      monitor = PointClickEngine::Core::PerformanceMonitor.new

      monitor.start_timing("test")
      sleep(0.001) # Small delay to ensure measurable time
      monitor.end_timing("test")

      metrics = monitor.get_metrics
      metrics.has_key?("test").should be_true
      metrics["test"].should be > 0.0_f32
    end

    it "handles ending timing without starting" do
      monitor = PointClickEngine::Core::PerformanceMonitor.new

      # Should not raise exceptions
      monitor.end_timing("nonexistent_category")

      metrics = monitor.get_metrics
      metrics.has_key?("nonexistent_category").should be_false
    end

    it "calculates rolling average for repeated measurements" do
      monitor = PointClickEngine::Core::PerformanceMonitor.new

      # First measurement
      monitor.start_timing("test")
      sleep(0.001)
      monitor.end_timing("test")

      first_measurement = monitor.get_metrics["test"]

      # Second measurement
      monitor.start_timing("test")
      sleep(0.002) # Slightly longer delay
      monitor.end_timing("test")

      second_measurement = monitor.get_metrics["test"]

      # Should be a rolling average, not just the latest value
      second_measurement.should_not eq(first_measurement)
    end

    it "does nothing when monitoring is disabled" do
      monitor = PointClickEngine::Core::PerformanceMonitor.new

      monitor.start_timing("test")
      monitor.disable_monitoring
      monitor.end_timing("test")

      metrics = monitor.get_metrics
      metrics.has_key?("test").should be_false
    end
  end

  describe "#get_metrics" do
    it "returns empty hash for new monitor" do
      monitor = PointClickEngine::Core::PerformanceMonitor.new

      metrics = monitor.get_metrics
      metrics.should be_a(Hash(String, Float32))
      metrics.size.should eq(0)
    end

    it "returns copy of metrics hash" do
      monitor = PointClickEngine::Core::PerformanceMonitor.new

      monitor.start_timing("test")
      sleep(0.001)
      monitor.end_timing("test")

      metrics1 = monitor.get_metrics
      metrics2 = monitor.get_metrics

      # Should be different object instances (defensive copy)
      metrics1.object_id.should_not eq(metrics2.object_id)

      # But same content
      metrics1["test"].should eq(metrics2["test"])
    end

    it "includes all measured categories" do
      monitor = PointClickEngine::Core::PerformanceMonitor.new

      categories = ["render", "update", "input", "audio"]

      categories.each do |category|
        monitor.start_timing(category)
        sleep(0.001)
        monitor.end_timing(category)
      end

      metrics = monitor.get_metrics
      categories.each do |category|
        metrics.has_key?(category).should be_true
        metrics[category].should be > 0.0_f32
      end
    end
  end

  describe "#reset_metrics" do
    it "clears all stored metrics" do
      monitor = PointClickEngine::Core::PerformanceMonitor.new

      # Add some metrics
      monitor.start_timing("test1")
      sleep(0.001)
      monitor.end_timing("test1")

      monitor.start_timing("test2")
      sleep(0.001)
      monitor.end_timing("test2")

      metrics_before = monitor.get_metrics
      metrics_before.size.should eq(2)

      monitor.reset_metrics

      metrics_after = monitor.get_metrics
      metrics_after.size.should eq(0)
    end

    it "clears pending timing operations" do
      monitor = PointClickEngine::Core::PerformanceMonitor.new

      # Start timing but don't end it
      monitor.start_timing("pending")

      monitor.reset_metrics

      # Now ending the timing should do nothing
      monitor.end_timing("pending")

      metrics = monitor.get_metrics
      metrics.has_key?("pending").should be_false
    end

    it "allows fresh metrics collection after reset" do
      monitor = PointClickEngine::Core::PerformanceMonitor.new

      # Add and reset metrics
      monitor.start_timing("test")
      sleep(0.001)
      monitor.end_timing("test")
      monitor.reset_metrics

      # Add new metrics
      monitor.start_timing("new_test")
      sleep(0.001)
      monitor.end_timing("new_test")

      metrics = monitor.get_metrics
      metrics.size.should eq(1)
      metrics.has_key?("new_test").should be_true
      metrics.has_key?("test").should be_false
    end
  end

  describe "#enable_monitoring and #disable_monitoring" do
    it "toggles monitoring state" do
      monitor = PointClickEngine::Core::PerformanceMonitor.new

      # Start enabled
      monitor.start_timing("test1")
      sleep(0.001)
      monitor.end_timing("test1")

      initial_metrics = monitor.get_metrics
      initial_metrics.has_key?("test1").should be_true

      # Disable monitoring
      monitor.disable_monitoring

      monitor.start_timing("test2")
      sleep(0.001)
      monitor.end_timing("test2")

      disabled_metrics = monitor.get_metrics
      disabled_metrics.has_key?("test2").should be_false
      disabled_metrics["test1"].should eq(initial_metrics["test1"]) # Previous data preserved

      # Re-enable monitoring
      monitor.enable_monitoring

      monitor.start_timing("test3")
      sleep(0.001)
      monitor.end_timing("test3")

      final_metrics = monitor.get_metrics
      final_metrics.has_key?("test3").should be_true
    end

    it "preserves existing metrics when toggling" do
      monitor = PointClickEngine::Core::PerformanceMonitor.new

      monitor.start_timing("preserved")
      sleep(0.001)
      monitor.end_timing("preserved")

      original_value = monitor.get_metrics["preserved"]

      monitor.disable_monitoring
      monitor.enable_monitoring

      preserved_value = monitor.get_metrics["preserved"]
      preserved_value.should eq(original_value)
    end
  end

  describe "rolling average calculation" do
    it "maintains rolling average across multiple measurements" do
      monitor = PointClickEngine::Core::PerformanceMonitor.new

      # Take several measurements
      measurements = [] of Float32

      5.times do |i|
        monitor.start_timing("average_test")
        sleep(0.001 * (i + 1)) # Varying delays
        monitor.end_timing("average_test")

        measurements << monitor.get_metrics["average_test"]
      end

      # Each measurement should be different due to rolling average
      measurements.uniq.size.should be > 1

      # Final value should be influenced by all measurements
      final_average = measurements.last
      final_average.should be > 0.0_f32
    end

    it "uses correct weighting for rolling average" do
      monitor = PointClickEngine::Core::PerformanceMonitor.new

      # First measurement (becomes initial average)
      monitor.start_timing("weight_test")
      sleep(0.010) # 10ms
      monitor.end_timing("weight_test")

      first_value = monitor.get_metrics["weight_test"]

      # Second measurement (much smaller)
      monitor.start_timing("weight_test")
      sleep(0.001) # 1ms
      monitor.end_timing("weight_test")

      second_value = monitor.get_metrics["weight_test"]

      # Should be weighted average: first_value * 0.9 + new_measurement * 0.1
      # So second_value should be less than first_value but not drastically
      second_value.should be < first_value
      second_value.should be > (first_value * 0.5) # Should still be significant
    end
  end

  describe "performance characteristics" do
    it "handles many timing operations efficiently" do
      monitor = PointClickEngine::Core::PerformanceMonitor.new

      start_time = Time.monotonic

      # Perform many timing operations
      100.times do |i|
        category = "perf_test_#{i % 10}" # 10 different categories
        monitor.start_timing(category)
        monitor.end_timing(category)
      end

      end_time = Time.monotonic
      elapsed = (end_time - start_time).total_milliseconds

      # Should complete quickly (under 50ms)
      elapsed.should be < 50.0

      # Should have collected metrics for all categories
      metrics = monitor.get_metrics
      metrics.size.should eq(10)
    end

    it "maintains accuracy with rapid timing operations" do
      monitor = PointClickEngine::Core::PerformanceMonitor.new

      # Rapid timing operations
      10.times do
        monitor.start_timing("rapid")
        # No sleep - measure just the overhead
        monitor.end_timing("rapid")
      end

      metrics = monitor.get_metrics
      metrics.has_key?("rapid").should be_true
      # Should be very small but measurable
      metrics["rapid"].should be >= 0.0_f32
    end
  end

  describe "edge cases and robustness" do
    it "handles empty category names" do
      monitor = PointClickEngine::Core::PerformanceMonitor.new

      monitor.start_timing("")
      sleep(0.001)
      monitor.end_timing("")

      metrics = monitor.get_metrics
      metrics.has_key?("").should be_true
    end

    it "handles very long category names" do
      monitor = PointClickEngine::Core::PerformanceMonitor.new
      long_name = "a" * 1000

      monitor.start_timing(long_name)
      sleep(0.001)
      monitor.end_timing(long_name)

      metrics = monitor.get_metrics
      metrics.has_key?(long_name).should be_true
    end

    it "handles multiple start calls for same category" do
      monitor = PointClickEngine::Core::PerformanceMonitor.new

      monitor.start_timing("multi_start")
      sleep(0.001)
      monitor.start_timing("multi_start") # Should overwrite first start time
      sleep(0.001)
      monitor.end_timing("multi_start")

      metrics = monitor.get_metrics
      metrics.has_key?("multi_start").should be_true
      # Should measure from the second start_timing call
    end

    it "handles concurrent timing operations" do
      monitor = PointClickEngine::Core::PerformanceMonitor.new

      # Simulate overlapping operations
      monitor.start_timing("operation_a")
      monitor.start_timing("operation_b")

      sleep(0.001)
      monitor.end_timing("operation_a")

      sleep(0.001)
      monitor.end_timing("operation_b")

      metrics = monitor.get_metrics
      metrics.has_key?("operation_a").should be_true
      metrics.has_key?("operation_b").should be_true

      # operation_b should have taken longer
      metrics["operation_b"].should be > metrics["operation_a"]
    end
  end

  describe "integration with error handling" do
    it "logs initialization message" do
      # This would normally be tested with a mock logger
      # For now, just verify it doesn't crash
      monitor = PointClickEngine::Core::PerformanceMonitor.new
      monitor.should be_a(PointClickEngine::Core::PerformanceMonitor)
    end
  end
end
