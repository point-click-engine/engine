require "../../spec_helper"
require "../../../src/core/di/di"

module PointClickEngine::Core
  # Test classes for service registry
  class TestService
    getter value : Int32

    def initialize(@value : Int32 = 0)
    end
  end

  class AnotherTestService
    getter name : String

    def initialize(@name : String = "default")
    end
  end

  class DependentService
    getter test_service : TestService

    def initialize(@test_service : TestService)
    end
  end

  describe ServiceRegistry do
    describe "#initialize" do
      it "creates an empty registry" do
        registry = ServiceRegistry.new
        registry.should_not be_nil
        registry.registered_services.should be_empty
      end
    end

    describe "#register and #resolve" do
      it "registers and resolves a singleton service" do
        registry = ServiceRegistry.new

        registry.register(TestService) do |r|
          TestService.new(42)
        end

        service = registry.resolve(TestService)
        service.should_not be_nil
        service.value.should eq(42)
      end

      it "returns same instance for singleton services" do
        registry = ServiceRegistry.new

        registry.register(TestService, ServiceLifetime::Singleton) do |r|
          TestService.new(rand(1000))
        end

        first = registry.resolve(TestService)
        second = registry.resolve(TestService)

        # Same instance (same value proves it)
        first.value.should eq(second.value)
        first.should be(second)
      end

      it "returns new instance for transient services" do
        registry = ServiceRegistry.new
        call_count = 0

        registry.register(TestService, ServiceLifetime::Transient) do |r|
          call_count += 1
          TestService.new(call_count)
        end

        first = registry.resolve(TestService)
        second = registry.resolve(TestService)

        # Different instances (different values)
        first.value.should eq(1)
        second.value.should eq(2)
      end

      it "caches scoped services within scope" do
        registry = ServiceRegistry.new
        call_count = 0

        registry.register(TestService, ServiceLifetime::Scoped) do |r|
          call_count += 1
          TestService.new(call_count)
        end

        first = registry.resolve(TestService)
        second = registry.resolve(TestService)

        # Same within scope
        first.value.should eq(1)
        second.value.should eq(1)

        # Clear scope
        registry.clear_scope

        # New instance after clearing scope
        third = registry.resolve(TestService)
        third.value.should eq(2)
      end
    end

    describe "#register_instance" do
      it "registers an existing instance" do
        registry = ServiceRegistry.new
        instance = TestService.new(999)

        registry.register_instance(TestService, instance)

        resolved = registry.resolve(TestService)
        resolved.should be(instance)
        resolved.value.should eq(999)
      end
    end

    describe "#resolve?" do
      it "returns nil for unregistered services" do
        registry = ServiceRegistry.new

        service = registry.resolve?(TestService)
        service.should be_nil
      end

      it "returns the service if registered" do
        registry = ServiceRegistry.new
        registry.register(TestService) { |r| TestService.new(10) }

        service = registry.resolve?(TestService)
        service.should_not be_nil
        service.not_nil!.value.should eq(10)
      end
    end

    describe "#resolve with missing service" do
      it "raises DependencyError for unregistered services" do
        registry = ServiceRegistry.new

        expect_raises(DependencyError, "Service not registered: PointClickEngine::Core::TestService") do
          registry.resolve(TestService)
        end
      end
    end

    describe "#registered?" do
      it "returns false for unregistered services" do
        registry = ServiceRegistry.new

        registry.registered?(TestService).should be_false
      end

      it "returns true for registered services" do
        registry = ServiceRegistry.new
        registry.register(TestService) { |r| TestService.new }

        registry.registered?(TestService).should be_true
      end
    end

    describe "#registered_services" do
      it "returns list of registered service names" do
        registry = ServiceRegistry.new

        registry.register(TestService) { |r| TestService.new }
        registry.register(AnotherTestService) { |r| AnotherTestService.new }

        services = registry.registered_services
        services.size.should eq(2)
        services.should contain("PointClickEngine::Core::TestService")
        services.should contain("PointClickEngine::Core::AnotherTestService")
      end
    end

    describe "#unregister" do
      it "removes a registered service" do
        registry = ServiceRegistry.new
        registry.register(TestService) { |r| TestService.new }

        registry.registered?(TestService).should be_true

        registry.unregister(TestService)

        registry.registered?(TestService).should be_false
      end
    end

    describe "#reset" do
      it "clears all registrations and scoped instances" do
        registry = ServiceRegistry.new

        registry.register(TestService) { |r| TestService.new }
        registry.register(AnotherTestService, ServiceLifetime::Scoped) { |r| AnotherTestService.new }

        # Resolve to create instances
        registry.resolve(TestService)
        registry.resolve(AnotherTestService)

        registry.reset

        registry.registered_services.should be_empty
        registry.registered?(TestService).should be_false
        registry.registered?(AnotherTestService).should be_false
      end
    end

    describe "dependency injection" do
      it "supports services that depend on other services" do
        registry = ServiceRegistry.new

        registry.register(TestService) do |r|
          TestService.new(100)
        end

        registry.register(DependentService) do |r|
          DependentService.new(r.resolve(TestService))
        end

        dependent = registry.resolve(DependentService)
        dependent.test_service.value.should eq(100)
      end

      it "shares singleton dependencies" do
        registry = ServiceRegistry.new

        registry.register(TestService, ServiceLifetime::Singleton) do |r|
          TestService.new(42)
        end

        registry.register(DependentService, ServiceLifetime::Transient) do |r|
          DependentService.new(r.resolve(TestService))
        end

        first = registry.resolve(DependentService)
        second = registry.resolve(DependentService)

        # Both should have the same TestService instance
        first.test_service.should be(second.test_service)
      end
    end

    describe "multiple services" do
      it "handles registering multiple different services" do
        registry = ServiceRegistry.new

        registry.register(TestService) { |r| TestService.new(1) }
        registry.register(AnotherTestService) { |r| AnotherTestService.new("test") }

        test_service = registry.resolve(TestService)
        another_service = registry.resolve(AnotherTestService)

        test_service.value.should eq(1)
        another_service.name.should eq("test")
      end

      it "overwrites existing registration when registering same type" do
        registry = ServiceRegistry.new

        registry.register(TestService) { |r| TestService.new(1) }
        registry.register(TestService) { |r| TestService.new(2) }

        service = registry.resolve(TestService)
        service.value.should eq(2)
      end
    end
  end

  describe ServiceLifetime do
    it "has correct enum values" do
      ServiceLifetime::Singleton.should_not be_nil
      ServiceLifetime::Scoped.should_not be_nil
      ServiceLifetime::Transient.should_not be_nil
    end
  end
end
