require "./simple_resource_manager"

# Resource manager facade - delegates to simple implementation
module PointClickEngine::Core
  alias ResourceManager = SimpleResourceManager
end
