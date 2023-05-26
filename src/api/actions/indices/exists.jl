using Mocking

using ..ElasticTransport

"""
Returns information about whether a particular index exists.

- `index::Union{String,Vector{String}}`: A comma-separated list of index names
- `local::Bool`: Return local information, do not retrieve the state from master node (default: false)
- `ignore_unavailable::Bool`: Ignore unavailable indexes (default: false)
- `allow_no_indices::Bool`: Ignore if a wildcard expression resolves to no concrete indices (default: false)
- `expand_wildcards::String`: Whether wildcard expressions should get expanded to open or closed indices (default: open) (options: open, closed, hidden, none, all)
- `flat_settings::Bool`: Return settings in flat format (default: false)
- `include_defaults::Bool`: Whether to return all default setting for each of the indices.
- `headers::Dict`: Custom HTTP headers

See https://www.elastic.co/guide/en/elasticsearch/reference/current/indices-exists.html

"""
function exists(client::Client; kwargs...)
  arguments = Dict(kwargs)

  !haskey(arguments, :index) && throw(ArgumentError("Required argument `index` missing"))

  headers = pop!(arguments, :headers, Dict())

  body = nothing
  
  index = pop!(arguments, :index)

  method = HTTP_HEAD
  path = "/$(_listify(index))"
  params = process_params(arguments)

  try
    response = Response(
      @mock perform_request(client, method, path; params=params, headers=headers, body=body)
    )
    response.status == 200 ? true : false
  catch exc
    if exc isa ElasticTransport.ServerException && exc.status == 404
      return false
    else
      throw(exc)
    end
  end
end