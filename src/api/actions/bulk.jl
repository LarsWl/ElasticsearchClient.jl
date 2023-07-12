"""
Allows to perform multiple index/update/delete operations in a single request.

- `index::String`: Default index for items which don't provide one
- `wait_for_active_shards::String`: Sets the number of shard copies that must be active before proceeding with the bulk operation. Defaults to 1, meaning the primary shard only. Set to `all` for all shard copies, otherwise set to any non-negative value less than or equal to the total number of copies for the shard (number of replicas + 1)
- `refresh::String`: If `true` then refresh the affected shards to make this operation visible to search, if `wait_for` then wait for a refresh to make this operation visible to search, if `false` (the default) then do nothing with refreshes. (options: true, false, wait_for)
- `routing::String`: Specific routing value
- `timeout::DateTime`: Explicit operation timeout
- `type::String`: Default document type for items which don't provide one
- `_source::Union{Vector{String}, String}`: True or false to return the _source field or not, or default list of fields to return, can be overridden on each sub-request
- `_source_excludes::Union{Vector{String}, String}`: Default list of fields to exclude from the returned _source field, can be overridden on each sub-request
- `_source_includes::Union{Vector{String}, String}`: Default list of fields to extract and return from the _source field, can be overridden on each sub-request
- `pipeline::String`: The pipeline id to preprocess incoming documents with
- `require_alias::Bool`: Sets require_alias for all incoming documents. Defaults to unset (false)
- `headers::Bool`: Custom HTTP headers
- `body::Union{String,Vector}`: The operation definition and data (action-data pairs), separated by newlines. Array of String or Dicts or NamedTuples

See https://www.elastic.co/guide/en/elasticsearch/reference/current/docs-bulk.html
"""
function bulk(client::Client; body, index=nothing, headers=Dict(), auth_params=nothing, kwargs...)
  arguments = Dict(kwargs)

  method = HTTP_POST

  path = if !isnothing(index)
    "/$(_listify(index))/_bulk"
  else
    "/_bulk"
  end
  params = process_params(arguments)

  payload = if body isa Vector
    _bulkify(body)
  else
    body
  end

  Response(
    @mock perform_request(client, method, path; params=params, auth_params=auth_params, headers=headers, body=payload)
  )
end