require "../spec_helper"
require "../../src/core/timer_manager"
require "../../src/core/events/events"

describe PointClickEngine::Core::TimerManager do
  describe "#initialize" do
    it "creates an empty timer manager" do
      manager = PointClickEngine::Core::TimerManager.new
      manager.timers.should be_empty
      manager.has_active_timers?.should be_false
      manager.active_timer_count.should eq(0)
    end

    it "accepts an optional event bus" do
      event_bus = PointClickEngine::Core::Events::EventBus.new
      manager = PointClickEngine::Core::TimerManager.new(event_bus)
      manager.event_bus.should eq(event_bus)
    end
  end

  describe "#add_timer" do
    it "adds a one-shot timer" do
      manager = PointClickEngine::Core::TimerManager.new
      timer_id = manager.add_timer(1.0f32)

      timer_id.should_not be_empty
      manager.timers.size.should eq(1)
      manager.has_active_timers?.should be_true
    end

    it "returns unique timer IDs" do
      manager = PointClickEngine::Core::TimerManager.new
      id1 = manager.add_timer(1.0f32)
      id2 = manager.add_timer(2.0f32)

      id1.should_not eq(id2)
      manager.timers.size.should eq(2)
    end

    it "stores callback code" do
      manager = PointClickEngine::Core::TimerManager.new
      timer_id = manager.add_timer(1.0f32, "print('hello')")

      timer = manager.timers.find { |t| t.id == timer_id }
      timer.should_not be_nil
      timer.not_nil!.callback_code.should eq("print('hello')")
    end
  end

  describe "#add_repeating_timer" do
    it "adds a repeating timer" do
      manager = PointClickEngine::Core::TimerManager.new
      timer_id = manager.add_repeating_timer(0.5f32)

      timer = manager.timers.find { |t| t.id == timer_id }
      timer.should_not be_nil
      timer.not_nil!.repeating.should be_true
    end
  end

  describe "#cancel_timer" do
    it "removes a timer by ID" do
      manager = PointClickEngine::Core::TimerManager.new
      timer_id = manager.add_timer(1.0f32)

      manager.timers.size.should eq(1)
      result = manager.cancel_timer(timer_id)

      result.should be_true
      manager.timers.size.should eq(0)
    end

    it "returns false for non-existent timer" do
      manager = PointClickEngine::Core::TimerManager.new
      result = manager.cancel_timer("nonexistent")
      result.should be_false
    end
  end

  describe "#cancel_all" do
    it "removes all timers" do
      manager = PointClickEngine::Core::TimerManager.new
      manager.add_timer(1.0f32)
      manager.add_timer(2.0f32)
      manager.add_timer(3.0f32)

      manager.timers.size.should eq(3)
      manager.cancel_all
      manager.timers.size.should eq(0)
    end
  end

  describe "#update" do
    it "fires timer when delay is reached" do
      event_bus = PointClickEngine::Core::Events::EventBus.new
      manager = PointClickEngine::Core::TimerManager.new(event_bus)

      fired_events = [] of PointClickEngine::Core::Events::TimerFiredEvent

      event_bus.subscribe(PointClickEngine::Core::Events::TimerFiredEvent) do |event|
        fired_events << event
      end

      timer_id = manager.add_timer(0.5f32, "test_callback")

      # Update but not enough time
      manager.update(0.3f32)
      event_bus.process
      fired_events.size.should eq(0)

      # Update past the delay
      manager.update(0.3f32)
      event_bus.process
      fired_events.size.should eq(1)
      fired_events[0].timer_id.should eq(timer_id)
      fired_events[0].callback_code.should eq("test_callback")
    end

    it "removes one-shot timer after firing" do
      manager = PointClickEngine::Core::TimerManager.new
      manager.add_timer(0.5f32)

      manager.timers.size.should eq(1)

      # Fire the timer
      manager.update(1.0f32)

      manager.timers.size.should eq(0)
    end

    it "keeps repeating timer after firing" do
      event_bus = PointClickEngine::Core::Events::EventBus.new
      manager = PointClickEngine::Core::TimerManager.new(event_bus)

      fire_count = 0
      event_bus.subscribe(PointClickEngine::Core::Events::TimerFiredEvent) do |event|
        fire_count += 1
      end

      manager.add_repeating_timer(0.5f32)

      # Fire multiple times
      manager.update(0.6f32)
      event_bus.process
      fire_count.should eq(1)
      manager.timers.size.should eq(1)

      manager.update(0.6f32)
      event_bus.process
      fire_count.should eq(2)
      manager.timers.size.should eq(1)
    end

    it "works without event bus" do
      manager = PointClickEngine::Core::TimerManager.new
      manager.add_timer(0.5f32)

      # Should not raise
      manager.update(1.0f32)
      manager.timers.size.should eq(0)
    end
  end

  describe PointClickEngine::Core::Timer do
    it "tracks elapsed time" do
      timer = PointClickEngine::Core::Timer.new("test", 1.0f32)
      timer.elapsed.should eq(0.0f32)

      timer.update(0.5f32)
      timer.elapsed.should eq(0.5f32)
    end

    it "returns true when fired" do
      timer = PointClickEngine::Core::Timer.new("test", 1.0f32)

      timer.update(0.5f32).should be_false
      timer.update(0.6f32).should be_true
    end

    it "marks as completed for one-shot" do
      timer = PointClickEngine::Core::Timer.new("test", 1.0f32)

      timer.completed?.should be_false
      timer.update(1.5f32)
      timer.completed?.should be_true
    end

    it "resets elapsed for repeating timer" do
      timer = PointClickEngine::Core::Timer.new("test", 1.0f32, repeating: true)

      timer.update(1.2f32)
      timer.elapsed.should be_close(0.2f32, 0.001)
      timer.completed?.should be_false
    end
  end
end
