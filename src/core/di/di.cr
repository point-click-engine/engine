# Dependency Injection Module
#
# Provides service registration and resolution for the engine.
# Works alongside the existing DependencyContainer for backwards compatibility.

require "./service_registry"
require "./services"

module PointClickEngine
  module Core
    # Re-export DI classes at the Core level for convenience
    # Usage: Core::ServiceRegistry, Core::Services, Core::ServiceLifetime
  end
end
