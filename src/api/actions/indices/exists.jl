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
function exists(client::Client; index=nothing, headers=Dict(), auth_params=nothing, kwargs...)
  arguments = Dict(kwargs)

  method = HTTP_HEAD
  path = "/$(_listify(index))"

  options = extract_options(arguments)
  set_ignore_on_not_found!(options)
  params = process_params(arguments)

  response = Response(
    @mock perform_request(client, method, path; params=params, auth_params=auth_params, headers=headers, body=nothing, opts=options)
  )

  response.status == 200
end
