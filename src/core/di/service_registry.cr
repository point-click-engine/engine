# Service Registry for Dependency Injection
#
# Provides a more flexible DI container than DependencyContainer,
# with support for different service lifetimes and automatic resolution.
#
# This is designed to work alongside the existing DependencyContainer
# while providing additional features for testing and modularity.

require "../error_handling"
require "../dependency_container"

module PointClickEngine
  module Core
    # Service lifetime determines how instances are created and cached
    enum ServiceLifetime
      # Single instance shared across the entire application
      Singleton

      # New instance for each scope (e.g., per game session)
      Scoped

      # New instance each time the service is resolved
      Transient
    end

    # Abstract base for service factories
    abstract class ServiceFactory
      abstract def create(registry : ServiceRegistry) : Void*
    end

    # Typed service factory
    class TypedServiceFactory(T) < ServiceFactory
      @factory : Proc(ServiceRegistry, T)

      def initialize(&@factory : ServiceRegistry -> T)
      end

      def create(registry : ServiceRegistry) : Void*
        @factory.call(registry).as(Void*)
      end
    end

    # Describes how to create and manage a service
    class ServiceDescriptor
      getter interface_type : String
      getter factory : ServiceFactory
      getter lifetime : ServiceLifetime
      property instance : Void*?

      def initialize(@interface_type : String, @factory : ServiceFactory, @lifetime : ServiceLifetime, @instance : Void*? = nil)
      end
    end

    # Service registry with automatic resolution
    #
    # Example usage:
    # ```
    # registry = ServiceRegistry.new
    #
    # # Register with factory
    # registry.register(EventBus) do |r|
    #   EventBus.new
    # end
    #
    # # Register an existing instance
    # registry.register_instance(EventBus, my_event_bus)
    #
    # # Resolve services
    # bus = registry.resolve(EventBus)
    # ```
    class ServiceRegistry
      @services : Hash(String, ServiceDescriptor) = {} of String => ServiceDescriptor
      @scoped_instances : Hash(String, Void*) = {} of String => Void*

      def initialize
      end

      # Register a service with a factory
      def register(
        interface : T.class,
        lifetime : ServiceLifetime = ServiceLifetime::Singleton,
        &factory : ServiceRegistry -> T
      ) forall T
        typed_factory = TypedServiceFactory(T).new(&factory)
        @services[T.name] = ServiceDescriptor.new(T.name, typed_factory, lifetime)
      end

      # Register an existing instance directly
      def register_instance(interface : T.class, instance : T) forall T
        factory = TypedServiceFactory(T).new { |r| instance }
        @services[T.name] = ServiceDescriptor.new(
          T.name,
          factory,
          ServiceLifetime::Singleton,
          instance.as(Void*)
        )
      end

      # Resolve a service by its interface type
      def resolve(interface : T.class) : T forall T
        descriptor = @services[T.name]? || raise DependencyError.new("Service not registered: #{T.name}")

        case descriptor.lifetime
        when .singleton?
          if ptr = descriptor.instance
            ptr.as(T)
          else
            instance = descriptor.factory.create(self).as(T)
            descriptor.instance = instance.as(Void*)
            instance
          end
        when .scoped?
          if ptr = @scoped_instances[T.name]?
            ptr.as(T)
          else
            instance = descriptor.factory.create(self).as(T)
            @scoped_instances[T.name] = instance.as(Void*)
            instance
          end
        when .transient?
          descriptor.factory.create(self).as(T)
        else
          raise DependencyError.new("Unknown lifetime for #{T.name}")
        end
      end

      # Try to resolve a service, returning nil if not found
      def resolve?(interface : T.class) : T? forall T
        resolve(interface)
      rescue DependencyError
        nil
      end

      # Check if a service is registered
      def registered?(interface : T.class) : Bool forall T
        @services.has_key?(T.name)
      end

      # Get all registered service names
      def registered_services : Array(String)
        @services.keys
      end

      # Clear scoped instances (call at end of game session)
      def clear_scope
        @scoped_instances.clear
      end

      # Reset everything - clears all registrations
      def reset
        @services.clear
        @scoped_instances.clear
      end

      # Unregister a specific service
      def unregister(interface : T.class) forall T
        @services.delete(T.name)
        @scoped_instances.delete(T.name)
      end
    end
  end
end
