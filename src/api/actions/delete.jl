using Mocking

"""
Removes a document from the index.

- `id::String`: The document ID
- `index::String`: The name of the index
- `wait_for_active_shards::String`: Sets the number of shard copies that must be active before proceeding with the delete operation. Defaults to 1, meaning the primary shard only. Set to `all` for all shard copies, otherwise set to any non-negative value less than or equal to the total number of copies for the shard (number of replicas + 1)
- `refresh::String`: If `true` then refresh the affected shards to make this operation visible to search, if `wait_for` then wait for a refresh to make this operation visible to search, if `false` (the default) then do nothing with refreshes. (options: true, false, wait_for)
- `routing::String`: Specific routing value
- `timeout::DateTime`: Explicit operation timeout
- `if_seq_no::Integer`: only perform the delete operation if the last operation that has changed the document has the specified sequence number
- `if_primary_term::Integer`: only perform the delete operation if the last operation that has changed the document has the specified primary term
- `version::Integer`: Explicit version number for concurrency control
- `version_type::String`: Specific version type (options: internal, external, external_gte)
- `headers::Dict`: Custom HTTP headers

See https://www.elastic.co/guide/en/elasticsearch/reference/current/docs-delete.html
"""
function delete(client::Client; kwargs...)
  arguments = Dict(kwargs)

  !haskey(arguments, :id) && throw(ArgumentError("Required argument 'id' missing"))
  !haskey(arguments, :index) && throw(ArgumentError("Required argument 'index' missing"))

  headers = pop!(arguments, :headers, Dict())
  body = nothing

  id = pop!(arguments, :id)
  index = pop!(arguments, :index)

  method = HTTP_DELETE

  path = "/$(_listify(index))/_doc/$(_listify(id))"
  params = process_params(arguments)

  Response(
    @mock perform_request(client, method, path; params=params, headers=headers, body=body)
  )
end
