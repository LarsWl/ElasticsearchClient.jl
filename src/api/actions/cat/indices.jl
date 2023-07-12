using Mocking

"""
Returns information about indices: number of primaries and replicas, document counts, disk size, ...

- `index::Union{String,Vector{String}}`: A comma-separated list of index names to limit the returned information
- `format::String`: a short version of the Accept header, e.g. json, yaml
- `bytes::String`: The unit in which to display byte values (options: b, k, kb, m, mb, g, gb, t, tb, p, pb)
- `master_timeout::DateTime`: Explicit operation timeout for connection to master node
- `h::Union{String,Vector{String}}`: Comma-separated list of column names to display
- `health::String`: A health status ("green", "yellow", or "red" to filter only indices matching the specified health status (options: green, yellow, red)
- `help::Bool`: Return help information
- `pri::Bool`: Set to true to return stats only for primary shards
- `s::Union{String,Vector{String}}`: Comma-separated list of column names or column aliases to sort by
- `time::String`: The unit in which to display time values (options: d, h, m, s, ms, micros, nanos)
- `v::Bool`: Verbose mode. Display column headers
- `include_unloaded_segments::Bool`: If set to true segment stats will include stats for segments that are not currently loaded into memory
- `expand_wildcards::String`: Whether to expand wildcard expression to concrete indices that are open, closed or both. (options: open, closed, hidden, none, all)
- `headers::Dict`: Custom HTTP headers

See https://www.elastic.co/guide/en/elasticsearch/reference/current/cat-indices.html
"""
function indices(client::Client; index=nothing, headers=Dict(), auth_params=nothing, kwargs...)
  arguments = Dict(kwargs)

  method = HTTP_GET

  path = if !isnothing(index)
    "/_cat/indices/$(_listify(index))"
  else
    "/_cat/indices"
  end

  params = process_params(arguments)

  Response(
    @mock perform_request(client, method, path; params=params, auth_params=auth_params, headers=headers, body=nothing)
  )
end
