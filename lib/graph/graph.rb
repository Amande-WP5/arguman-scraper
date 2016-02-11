require "set"

class Graph
  def initialize
    @nodes  = Set.new
    @values = Hash.new(0.0)
  end

  def add_edge(from, to, value)
    @values[[from, to].minmax.join("_")] = value/5.0
    @nodes << from << to
  end

  def optimize
    loop do
      modif = false
      @nodes.to_a.combination(3).each do |perm|
        short_str = [perm[0], perm[2]].minmax.join("_")
        short_val = @values[short_str]
        long_str  = [perm[0], perm[1]].minmax.join("_")
        long_val = @values[long_str]
        long_str  = [perm[1], perm[2]].minmax.join("_")
        long_val *= @values[long_str]
        if short_val < long_val
          @values[short_str] = long_val
          modif = true
        end
      end
      break unless modif
    end
    return @values
  end
end
