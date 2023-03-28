DEFAULT_SELECTOR = RoundRobinSelector

struct Collection
  connections::Vector{Connection}
  selector::AbsrtactSelector
end

function Collection(;
  selector_type::Type=DEFAULT_SELECTOR,
  connections::Vector{Connection}=Connection[]
)
  Collection(
    connections,
    selector_type()
  )
end

function get_connection(collection::Collection)
  conn = select(collection.selector, collection.connections)
  if isnothing(conn)
    conn = collection.connections[last(findmin(c -> c.failures, collection.connections))]
  end

  conn
end

function remove!(collection::Collection, conn::Connection)
  index = findfirst(==(conn), collection.connections)

  if !isnothing(index)
    deleteat!(collection.connections, index)
  end
end

dead(collection::Collection) = filter(conn -> conn.dead, collection)

Base.length(collection::Collection) = length(collection.connections)
Base.push!(collection::Collection, conns::Connection...) = push!(collection.connections, conns...)
Base.filter(func::Function, collection::Collection) =
  Collection(filter(func, collection.connections), collection.selector)
Base.any(func::Function, collection::Collection) = any(func, collection.connections)
Base.foreach(func, collection::Collection) = foreach(func, collection.connections)

