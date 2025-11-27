# Default Service Configuration
#
# Provides a global service registry with default engine services pre-configured.
# This module makes it easy to access common services without explicit injection.

require "./service_registry"
require "../events/events"

module PointClickEngine
  module Core
    # Global service configuration and access
    #
    # Example usage:
    # ```
    # # Initialize default services
    # Services.configure_defaults
    #
    # # Access services
    # bus = Services.event_bus
    # bus.publish(SomeEvent.new)
    #
    # # For testing, swap implementations
    # Services.registry.register_instance(EventBus, mock_bus)
    # ```
    module Services
      @@registry : ServiceRegistry = ServiceRegistry.new
      @@configured : Bool = false

      # Get the global service registry
      def self.registry : ServiceRegistry
        @@registry
      end

      # Configure default services
      # Call this once during engine initialization
      def self.configure_defaults
        return if @@configured

        # Event bus - central event system
        @@registry.register(Events::EventBus, ServiceLifetime::Singleton) do |r|
          Events::EventBus.new
        end

        @@configured = true
      end

      # Reset all services (primarily for testing)
      def self.reset
        @@registry.reset
        @@configured = false
      end

      # Check if services have been configured
      def self.configured? : Bool
        @@configured
      end

      # Convenience accessor for the event bus
      def self.event_bus : Events::EventBus
        configure_defaults unless @@configured
        @@registry.resolve(Events::EventBus)
      end

      # Clear scoped services (call between game sessions)
      def self.clear_scope
        @@registry.clear_scope
      end

      # Helper to register a custom service
      def self.register(interface : T.class, lifetime : ServiceLifetime = ServiceLifetime::Singleton, &factory : ServiceRegistry -> T) forall T
        @@registry.register(interface, lifetime, &factory)
      end

      # Helper to register an instance
      def self.register_instance(interface : T.class, instance : T) forall T
        @@registry.register_instance(interface, instance)
      end

      # Helper to resolve a service
      def self.resolve(interface : T.class) : T forall T
        @@registry.resolve(interface)
      end

      # Helper to try resolving a service
      def self.resolve?(interface : T.class) : T? forall T
        @@registry.resolve?(interface)
      end
    end
  end
end
