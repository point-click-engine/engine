require "../../spec_helper"

module PointClickEngine::Core::Events
  # Test event types
  class TestEvent < GameEvent
    define_event_type "test:basic"

    getter value : Int32

    def initialize(@value : Int32 = 0)
      super()
    end
  end

  class AnotherTestEvent < GameEvent
    define_event_type "test:another"

    getter message : String

    def initialize(@message : String = "")
      super()
    end
  end

  describe EventBus do
    describe "#initialize" do
      it "creates an empty event bus" do
        bus = EventBus.new
        bus.should_not be_nil
        bus.pending?.should be_false
        bus.pending_count.should eq(0)
      end
    end

    describe "#subscribe and #publish_sync" do
      it "subscribes and handles events" do
        bus = EventBus.new
        received_value = 0

        bus.subscribe(TestEvent) do |event|
          received_value = event.value
        end

        bus.publish_sync(TestEvent.new(42))
        received_value.should eq(42)
      end

      it "only notifies handlers of matching event types" do
        bus = EventBus.new
        test_called = false
        another_called = false

        bus.subscribe(TestEvent) do |event|
          test_called = true
        end

        bus.subscribe(AnotherTestEvent) do |event|
          another_called = true
        end

        bus.publish_sync(TestEvent.new(1))

        test_called.should be_true
        another_called.should be_false
      end

      it "calls multiple handlers for same event type" do
        bus = EventBus.new
        call_count = 0

        3.times do
          bus.subscribe(TestEvent) do |event|
            call_count += 1
          end
        end

        bus.publish_sync(TestEvent.new(1))
        call_count.should eq(3)
      end
    end

    describe "#publish (queued)" do
      it "queues events for deferred processing" do
        bus = EventBus.new
        received_value = 0

        bus.subscribe(TestEvent) do |event|
          received_value = event.value
        end

        bus.publish(TestEvent.new(99))
        bus.pending?.should be_true
        bus.pending_count.should eq(1)
        received_value.should eq(0) # Not processed yet

        bus.process
        received_value.should eq(99)
        bus.pending?.should be_false
      end

      it "processes multiple queued events in order" do
        bus = EventBus.new
        values = [] of Int32

        bus.subscribe(TestEvent) do |event|
          values << event.value
        end

        bus.publish(TestEvent.new(1))
        bus.publish(TestEvent.new(2))
        bus.publish(TestEvent.new(3))

        bus.process

        values.should eq([1, 2, 3])
      end
    end

    describe "#process_one" do
      it "processes a single event from queue" do
        bus = EventBus.new
        values = [] of Int32

        bus.subscribe(TestEvent) do |event|
          values << event.value
        end

        bus.publish(TestEvent.new(1))
        bus.publish(TestEvent.new(2))

        bus.process_one.should be_true
        values.should eq([1])
        bus.pending_count.should eq(1)

        bus.process_one.should be_true
        values.should eq([1, 2])
        bus.pending_count.should eq(0)

        bus.process_one.should be_false
      end
    end

    describe "priority handling" do
      it "calls higher priority handlers first" do
        bus = EventBus.new
        call_order = [] of Int32

        bus.subscribe(TestEvent, HandlerPriority::Low) do |event|
          call_order << 1
        end

        bus.subscribe(TestEvent, HandlerPriority::High) do |event|
          call_order << 2
        end

        bus.subscribe(TestEvent, HandlerPriority::Normal) do |event|
          call_order << 3
        end

        bus.publish_sync(TestEvent.new)

        # High (2), Normal (3), Low (1)
        call_order.should eq([2, 3, 1])
      end

      it "maintains FIFO order within same priority" do
        bus = EventBus.new
        call_order = [] of Int32

        bus.subscribe(TestEvent, HandlerPriority::Normal) do |event|
          call_order << 1
        end

        bus.subscribe(TestEvent, HandlerPriority::Normal) do |event|
          call_order << 2
        end

        bus.subscribe(TestEvent, HandlerPriority::Normal) do |event|
          call_order << 3
        end

        bus.publish_sync(TestEvent.new)

        call_order.should eq([1, 2, 3])
      end
    end

    describe "#consume!" do
      it "stops propagation when event is consumed" do
        bus = EventBus.new
        call_order = [] of Int32

        bus.subscribe(TestEvent, HandlerPriority::High) do |event|
          call_order << 1
          event.consume!
        end

        bus.subscribe(TestEvent, HandlerPriority::Normal) do |event|
          call_order << 2
        end

        bus.publish_sync(TestEvent.new)

        # Only first handler called
        call_order.should eq([1])
      end
    end

    describe "#unsubscribe" do
      it "removes a handler by subscription ID" do
        bus = EventBus.new
        call_count = 0

        id = bus.subscribe(TestEvent) do |event|
          call_count += 1
        end

        bus.publish_sync(TestEvent.new)
        call_count.should eq(1)

        bus.unsubscribe(id).should be_true
        bus.publish_sync(TestEvent.new)
        call_count.should eq(1) # Not incremented
      end

      it "returns false for non-existent subscription" do
        bus = EventBus.new
        bus.unsubscribe(9999_u64).should be_false
      end
    end

    describe "#unsubscribe_all" do
      it "removes all handlers for a specific owner" do
        bus = EventBus.new
        call_count = 0

        bus.subscribe(TestEvent, owner: "owner1") do |event|
          call_count += 1
        end

        bus.subscribe(TestEvent, owner: "owner1") do |event|
          call_count += 1
        end

        bus.subscribe(TestEvent, owner: "owner2") do |event|
          call_count += 1
        end

        bus.unsubscribe_all("owner1")
        bus.publish_sync(TestEvent.new)

        call_count.should eq(1) # Only owner2's handler
      end
    end

    describe "#unsubscribe_all_for" do
      it "removes all handlers for a specific event type" do
        bus = EventBus.new
        test_count = 0
        another_count = 0

        bus.subscribe(TestEvent) do |event|
          test_count += 1
        end

        bus.subscribe(AnotherTestEvent) do |event|
          another_count += 1
        end

        bus.unsubscribe_all_for(TestEvent)

        bus.publish_sync(TestEvent.new)
        bus.publish_sync(AnotherTestEvent.new("hi"))

        test_count.should eq(0)
        another_count.should eq(1)
      end
    end

    describe "#has_handlers?" do
      it "returns true when handlers exist" do
        bus = EventBus.new

        bus.has_handlers?(TestEvent).should be_false

        bus.subscribe(TestEvent) { |e| }

        bus.has_handlers?(TestEvent).should be_true
        bus.has_handlers?(AnotherTestEvent).should be_false
      end
    end

    describe "#handler_count" do
      it "returns correct handler count" do
        bus = EventBus.new

        bus.handler_count(TestEvent).should eq(0)

        bus.subscribe(TestEvent) { |e| }
        bus.handler_count(TestEvent).should eq(1)

        bus.subscribe(TestEvent) { |e| }
        bus.handler_count(TestEvent).should eq(2)
      end
    end

    describe "#clear" do
      it "clears queue and handlers" do
        bus = EventBus.new

        bus.subscribe(TestEvent) { |e| }
        bus.publish(TestEvent.new)

        bus.pending?.should be_true
        bus.has_handlers?(TestEvent).should be_true

        bus.clear

        bus.pending?.should be_false
        bus.has_handlers?(TestEvent).should be_false
      end
    end

    describe "#stats" do
      it "tracks event statistics" do
        bus = EventBus.new
        bus.subscribe(TestEvent) { |e| }

        stats = bus.stats
        stats[:published].should eq(0_u64)
        stats[:processed].should eq(0_u64)
        stats[:pending].should eq(0)
        stats[:handlers].should eq(1)

        bus.publish(TestEvent.new)
        bus.publish_sync(TestEvent.new)

        stats = bus.stats
        stats[:published].should eq(2_u64)
        stats[:pending].should eq(1)

        bus.process

        stats = bus.stats
        stats[:processed].should eq(1_u64)
        stats[:pending].should eq(0)
      end
    end

    describe "error handling" do
      it "continues processing after handler error" do
        bus = EventBus.new
        call_count = 0

        bus.subscribe(TestEvent, HandlerPriority::High) do |event|
          call_count += 1
          raise "Intentional error"
        end

        bus.subscribe(TestEvent, HandlerPriority::Normal) do |event|
          call_count += 1
        end

        # Should not raise, and should continue to second handler
        bus.publish_sync(TestEvent.new)
        call_count.should eq(2)
      end
    end

    describe GameEvent do
      it "has correct event_type" do
        TestEvent.event_type.should eq("test:basic")
        AnotherTestEvent.event_type.should eq("test:another")
      end

      it "returns type via instance method" do
        event = TestEvent.new(5)
        event.type.should eq("test:basic")
      end

      it "tracks consumed state" do
        event = TestEvent.new
        event.consumed?.should be_false

        event.consume!
        event.consumed?.should be_true
      end

      it "has timestamp" do
        before = Time.utc
        event = TestEvent.new
        after = Time.utc

        event.timestamp.should be >= before
        event.timestamp.should be <= after
      end

      it "supports source property" do
        event = TestEvent.new
        event.source.should be_nil

        event.source = "TestSystem"
        event.source.should eq("TestSystem")
      end
    end

    describe HandlerPriority do
      it "has correct values" do
        HandlerPriority::Lowest.value.should eq(0)
        HandlerPriority::Low.value.should eq(25)
        HandlerPriority::Normal.value.should eq(50)
        HandlerPriority::High.value.should eq(75)
        HandlerPriority::Highest.value.should eq(100)
        HandlerPriority::System.value.should eq(200)
      end
    end
  end
end
