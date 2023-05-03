using JSON

function _listify(args...)
  join(map(_listify, args), ",")
end

function _listify(args::Vector)
  join(map(_listify, args), ",")
end

function _listify(arg::String)
  arg
end

function process_params(arguments::Dict)
  params = Dict()

  for (key, value) in collect(arguments)
    if value isa Vector || value isa Tuple
      params[key] = _listify(value)
    else
      params[key] = value
    end
  end

  params
end

function _bulkify(payload::Vector{<: AbstractDict})
  operations = ["index", "create", "delete", "update"]

  is_operation_data(data) = (string ∘ first ∘ keys)(data) in operations
  
  payload = reduce(payload, init=[]) do acc, data
    if is_operation_data(data)
      operation, operation_data = first(collect(data))
      meta = copy(operation_data)
      data = pop!(meta, :data, nothing) |> data -> pop!(meta, "data", data)

      push!(acc, Dict(operation => meta))
      !isnothing(data) && push!(acc, data)
      
      acc
    else
      push!(acc, data)
    end
  end .|> JSON.json

  _bulkify(payload)
end

function _bulkify(payload::Vector{String})
  if !isempty(payload)
    push!(payload, "")
  end

  join(payload, "\n")
end
