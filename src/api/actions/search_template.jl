using Mocking

"""
Allows to use the Mustache language to pre-render a search definition.

- `index::Union{String,Vector{String}}`: A comma-separated list of index names to search; use `_all` or empty string to perform the operation on all indices
- `ignore_unavailable::Bool`: Whether specified concrete indices should be ignored when unavailable (missing or closed)
- `ignore_throttled::Bool`: Whether specified concrete, expanded or aliased indices should be ignored when throttled
- `allow_no_indices::Bool`: Whether to ignore if a wildcard indices expression resolves into no concrete indices. (This includes `_all` string or when no indices have been specified)
- `expand_wildcards::String`: Whether to expand wildcard expression to concrete indices that are open, closed or both. (options: open, closed, hidden, none, all)
- `preference::String`: Specify the node or shard the operation should be performed on (default: random)
- `routing::Union{String,Vector{String}}`: A comma-separated list of specific routing values
- `scroll::DateTime`: Specify how long a consistent view of the index should be maintained for scrolled search
- `search_type::String`: Search operation type (options: query_then_fetch, dfs_query_then_fetch)
- `explain::Bool`: Specify whether to return detailed information about score computation as part of a hit
- `profile::Bool`: Specify whether to profile the query execution
- `typed_keys::Bool`: Specify whether aggregation and suggester names should be prefixed by their respective types in the response
- `rest_total_hits_as_int::Bool`: Indicates whether hits.total should be rendered as an integer or an object in the rest search response
- `ccs_minimize_roundtrips::Bool`: Indicates whether network round-trips should be minimized as part of cross-cluster search requests execution
- `headers::Dict`: Custom HTTP headers
- `body::Union{Dict,NamedTuple}`: The search definition template and its params (*Required*)

See https://www.elastic.co/guide/en/elasticsearch/reference/current/search-template.html
"""
function search_template(client::Client; body, index=nothing, headers=Dict(), auth_params=nothing, kwargs...)
  arguments = Dict(kwargs)

  method = HTTP_POST

  path = if !isnothing(index)
    "/$(_listify(index))/$(UNDERSCORE_SEARCH)/template"
  else
    "/$(UNDERSCORE_SEARCH)/template"
  end

  params = process_params(arguments)

  Response(
    @mock perform_request(client, method, path; params=params, auth_params=auth_params, headers=headers, body=body)
  )
end
