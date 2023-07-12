using Mocking

"""
Performs the refresh operation in one or more indices.

- `index::Union{String,Vector{String}}`: A comma-separated list of index names; use `_all` or empty string to perform the operation on all indices
- `ignore_unavailable::Bool`: Whether specified concrete indices should be ignored when unavailable (missing or closed)
- `allow_no_indices::Bool`: Whether to ignore if a wildcard indices expression resolves into no concrete indices. (This includes `_all` string or when no indices have been specified)
- `expand_wildcards::String`: Whether to expand wildcard expression to concrete indices that are open, closed or both. (options: open, closed, hidden, none, all)
- `headers::Dict`: Custom HTTP headers

See https://www.elastic.co/guide/en/elasticsearch/reference/current/indices-refresh.html
"""
function refresh(client::Client; index=nothing, headers=Dict(), auth_params=nothing, kwargs...)
  arguments = Dict(kwargs)
  
  method = HTTP_POST
  path = if !isnothing(index)
    "/$(_listify(index))/_refresh"
  else
    "/_refresh"
  end
  params = process_params(arguments)

  Response(
    @mock perform_request(client, method, path; params=params, auth_params=auth_params, headers=headers, body=nothing)
  )
end