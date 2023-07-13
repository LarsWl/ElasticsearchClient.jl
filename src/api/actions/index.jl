using Mocking

"""
Creates or updates a document in an index.

- `id::String`: Document ID
- `index::String`: The name of the index
- `wait_for_active_shards::String`: Sets the number of shard copies that must be active before proceeding with the index operation. Defaults to 1, meaning the primary shard only. Set to `all` for all shard copies, otherwise set to any non-negative value less than or equal to the total number of copies for the shard (number of replicas + 1)
- `op_type::String`: Explicit operation type. Defaults to `index` for requests with an explicit document ID, and to `create`for requests without an explicit document ID (options: index, create)
- `refresh::String`: If `true` then refresh the affected shards to make this operation visible to search, if `wait_for` then wait for a refresh to make this operation visible to search, if `false` (the default) then do nothing with refreshes. (options: true, false, wait_for)
- `routing::String`: Specific routing value
- `timeout::DateTime`: Explicit operation timeout
- `version::Integer`: Explicit version number for concurrency control
- `version_type::String`: Specific version type (options: internal, external, external_gte)
- `if_seq_no::Integer`: only perform the index operation if the last operation that has changed the document has the specified sequence number
- `if_primary_term::Integer`: only perform the index operation if the last operation that has changed the document has the specified primary term
- `pipeline::String`: The pipeline id to preprocess incoming documents with
- `require_alias::Bool`: When true, requires destination to be an alias. Default is false
- `headers::Dict`: Custom HTTP headers
- `body::Union{NamedTuple,Dict}`: The document (*Required*)

See https://www.elastic.co/guide/en/elasticsearch/reference/current/docs-index_.html
"""
function index(client::Client; body, index, id=nothing, headers=Dict(), auth_params=nothing, kwargs...)
  arguments = Dict(kwargs)

  method = isnothing(id) ? HTTP_POST : HTTP_PUT

  path = if !isnothing(id)
    "/$(_listify(index))/_doc/$(_listify(id))"
  else
    "/$(_listify(index))/_doc"
  end
  params = process_params(arguments)

  Response(
    @mock perform_request(client, method, path; params=params, auth_params=auth_params, headers=headers, body=body)
  )
end
