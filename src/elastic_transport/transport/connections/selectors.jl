abstract type AbsrtactSelector end

struct RandomSelector <: AbsrtactSelector end
mutable struct RoundRobinSelector <: AbsrtactSelector
  lock::ReentrantLock
  current::Union{Nothing,Integer}
end

RoundRobinSelector() = RoundRobinSelector(ReentrantLock(), nothing)

function select(::RandomSelector, connections::Vector{Connection})
  rand(connections)
end

function select(selector::RoundRobinSelector, connections)
  lock(selector.lock) do 
    if !isnothing(selector.current) && selector.current < length(connections)
      selector.current += 1
    else
      selector.current = 1
    end

    connections[selector.current]
  end
end