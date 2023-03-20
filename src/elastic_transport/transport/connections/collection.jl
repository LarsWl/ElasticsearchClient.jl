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

function dead(collection::Collection)
  filter(conn -> conn.dead, collection.connections)
end
