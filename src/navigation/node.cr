module PointClickEngine
  module Navigation
    # Represents a pathfinding graph node for A* algorithm
    #
    # The Node class contains the essential data for pathfinding algorithms:
    # - Position coordinates (x, y)
    # - Cost calculations (g_cost, h_cost, f_cost)
    # - Parent reference for path reconstruction
    class Node
      # Grid coordinates
      property x : Int32
      property y : Int32

      # A* algorithm costs
      property g_cost : Float32 # Cost from start node
      property h_cost : Float32 # Heuristic cost to end node

      # Path reconstruction
      property parent : Node?

      def initialize(@x : Int32, @y : Int32, @g_cost = 0.0f32, @h_cost = 0.0f32, @parent = nil)
      end

      # F cost is the sum of G and H costs (A* evaluation function)
      def f_cost
        @g_cost + @h_cost
      end

      # Two nodes are equal if they have the same coordinates
      def ==(other : Node)
        @x == other.x && @y == other.y
      end

      # Hash function for using nodes in hash-based collections
      def hash
        {@x, @y}.hash
      end

      # String representation for debugging
      def to_s(io : IO) : Nil
        io << "Node(#{@x}, #{@y}, g:#{@g_cost}, h:#{@h_cost}, f:#{f_cost})"
      end

      # Creates a copy of this node with updated costs
      def with_costs(g_cost : Float32, h_cost : Float32, parent : Node? = nil) : Node
        Node.new(@x, @y, g_cost, h_cost, parent)
      end

      # Distance to another node (for debugging/validation)
      def distance_to(other : Node) : Float32
        dx = (@x - other.x).abs
        dy = (@y - other.y).abs
        Math.sqrt(dx * dx + dy * dy).to_f32
      end

      # Manhattan distance to another node
      def manhattan_distance_to(other : Node) : Int32
        (@x - other.x).abs + (@y - other.y).abs
      end

      # Check if this node is adjacent to another (including diagonals)
      def adjacent_to?(other : Node) : Bool
        dx = (@x - other.x).abs
        dy = (@y - other.y).abs
        dx <= 1 && dy <= 1 && !(dx == 0 && dy == 0)
      end

      # Check if this node is orthogonally adjacent (no diagonals)
      def orthogonally_adjacent_to?(other : Node) : Bool
        dx = (@x - other.x).abs
        dy = (@y - other.y).abs
        (dx == 1 && dy == 0) || (dx == 0 && dy == 1)
      end

      # Check if this node is diagonally adjacent
      def diagonally_adjacent_to?(other : Node) : Bool
        dx = (@x - other.x).abs
        dy = (@y - other.y).abs
        dx == 1 && dy == 1
      end
    end
  end
end
