using Mocking

"""
Creates an index with optional settings and mappings.

- `index::String`: The name of the index
- `wait_for_active_shards::String`: Set the number of active shards to wait for before the operation returns.
- `timeout::DateTime`: Explicit operation timeout
- `master_timeout::DateTime`: Specify timeout for connection to master
- `headers::Dict`: Custom HTTP headers
- `body::Union{NamedTuple,Dict}`: The configuration for the index (`settings` and `mappings`)

See https://www.elastic.co/guide/en/elasticsearch/reference/current/indices-create-index.html
"""
function create(client::Client; kwargs...)
  arguments = Dict(kwargs)

  !haskey(arguments, :index) && throw(ArgumentError("Required argument `index` missing"))

  headers = pop!(arguments, :headers, Dict())
  body = pop!(arguments, :body, nothing)
  index = pop!(arguments, :index)

  method = HTTP_PUT
  path = "/$(_listify(index))"
  params = process_params(arguments)

  Response(
    @mock perform_request(client, method, path; params=params, headers=headers, body=body)
  )
end