using Mocking

"""
Deletes an index.

- `index::Union{String,Vector{String}}`: A comma-separated list of indices to delete; use `_all` or `*` string to delete all indices
- `timeout::DateTime`: Explicit operation timeout
- `master_timeout::DateTime`: Specify timeout for connection to master
- `ignore_unavailable::Bool`: Ignore unavailable indexes (default: false)
- `allow_no_indices::Bool`: Ignore if a wildcard expression resolves to no concrete indices (default: false)
- `expand_wildcards::String`: Whether wildcard expressions should get expanded to open, closed, or hidden indices (options: open, closed, hidden, none, all)
- `headers::Dict`: Custom HTTP headers

See https://www.elastic.co/guide/en/elasticsearch/reference/current/indices-delete-index.html
"""
function delete(client::Client; kwargs...)
  arguments = Dict(kwargs)

  !haskey(arguments, :index) && throw(ArgumentError("Required argument 'index' missing"))

  headers = pop!(arguments, :headers, Dict())
  body = nothing

  index = pop!(arguments, :index)

  method = HTTP_DELETE
  path = "/$(_listify(index))"
  params = process_params(arguments)

  Response(
    @mock perform_request(client, method, path; params=params, headers=headers, body=body)
  )
end
