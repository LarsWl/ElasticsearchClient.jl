using Mocking

using ..ElasticTransport

"""
Returns information about whether a particular alias exists.

- `name::Union{String,Vector{String}}`: A comma-separated list of alias names to return
- `index::Union{String,Vector{String}}`: A comma-separated list of index names to filter aliases
- `ignore_unavailable::Bool`: Whether specified concrete indices should be ignored when unavailable (missing or closed)
- `allow_no_indices::Bool`: Whether to ignore if a wildcard indices expression resolves into no concrete indices. (This includes `_all` string or when no indices have been specified)
- `expand_wildcards::String`: Whether to expand wildcard expression to concrete indices that are open, closed or both. (options: open, closed, hidden, none, all)
- `local::Bool`: Return local information, do not retrieve the state from master node (default: false)
- `headers::Dict`: Custom HTTP headers

See https://www.elastic.co/guide/en/elasticsearch/reference/current/indices-aliases.html

"""
function exists_alias(client::Client; index=nothing, name, headers=Dict(), auth_params=nothing, kwargs...)
  arguments = Dict(kwargs)

  method = HTTP_HEAD
  path = if !isnothing(index)
    "/$(_listify(index))/_alias/$(_listify(name))"
  else
    "/_alias/$(_listify(name))"
  end
  params = process_params(arguments)

  try
    response = Response(
      @mock perform_request(client, method, path; params=params, auth_params=auth_params, headers=headers, body=nothing)
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