# Simple Dependency Injection Container for the Point & Click Engine
#
# A simplified approach without type erasure to avoid pointer corruption

require "./interfaces"
require "./error_handling"

module PointClickEngine
  module Core
    # Dependency-related error
    class DependencyError < Exception
    end

    # Simple dependency injection container
    #
    # Uses separate storage for each interface type to avoid pointer issues
    class SimpleDependencyContainer
      include ErrorHelpers

      # Storage for each interface type
      @resource_loaders = {} of String => IResourceLoader
      @scene_managers = {} of String => ISceneManager
      @input_managers = {} of String => IInputManager
      @render_managers = {} of String => IRenderManager
      @config_managers = {} of String => IConfigManager
      @performance_monitors = {} of String => IPerformanceMonitor

      def initialize
      end

      # Register a resource loader
      def register_resource_loader(instance : IResourceLoader)
        @resource_loaders[IResourceLoader.name] = instance
        ErrorLogger.debug("Registered resource loader")
      end

      # Register a scene manager
      def register_scene_manager(instance : ISceneManager)
        @scene_managers[ISceneManager.name] = instance
        ErrorLogger.debug("Registered scene manager")
      end

      # Register an input manager
      def register_input_manager(instance : IInputManager)
        @input_managers[IInputManager.name] = instance
        ErrorLogger.debug("Registered input manager")
      end

      # Register a render manager
      def register_render_manager(instance : IRenderManager)
        @render_managers[IRenderManager.name] = instance
        ErrorLogger.debug("Registered render manager")
      end

      # Register a config manager
      def register_config_manager(instance : IConfigManager)
        @config_managers[IConfigManager.name] = instance
        ErrorLogger.debug("Registered config manager")
      end

      # Register a performance monitor
      def register_performance_monitor(instance : IPerformanceMonitor)
        @performance_monitors[IPerformanceMonitor.name] = instance
        ErrorLogger.debug("Registered performance monitor")
      end

      # Resolve dependencies by type
      def resolve_resource_loader : IResourceLoader
        @resource_loaders[IResourceLoader.name]? || raise DependencyError.new("No resource loader registered")
      end

      def resolve_scene_manager : ISceneManager
        @scene_managers[ISceneManager.name]? || raise DependencyError.new("No scene manager registered")
      end

      def resolve_input_manager : IInputManager
        @input_managers[IInputManager.name]? || raise DependencyError.new("No input manager registered")
      end

      def resolve_render_manager : IRenderManager
        @render_managers[IRenderManager.name]? || raise DependencyError.new("No render manager registered")
      end

      def resolve_config_manager : IConfigManager
        @config_managers[IConfigManager.name]? || raise DependencyError.new("No config manager registered")
      end

      def resolve_performance_monitor : IPerformanceMonitor
        @performance_monitors[IPerformanceMonitor.name]? || raise DependencyError.new("No performance monitor registered")
      end
    end
  end
end
