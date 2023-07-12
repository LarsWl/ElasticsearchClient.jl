using Mocking

"""
Deletes documents matching the provided query.

- `index::Union{String, Vector{String}}`: A comma-separated list of index names to search; use `_all` or empty string to perform the operation on all indices
- `analyzer::String`: The analyzer to use for the query string
- `analyze_wildcard::Bool`: Specify whether wildcard and prefix queries should be analyzed (default: false)
- `default_operator::String`: The default operator for query string query (AND or OR) (options: AND, OR)
- `df::String`: The field to use as default where no field prefix is given in the query string
- `from::Integer`: Starting offset (default: 0)
- `ignore_unavailable::Bool`: Whether specified concrete indices should be ignored when unavailable (missing or closed)
- `allow_no_indices::Bool`: Whether to ignore if a wildcard indices expression resolves into no concrete indices. (This includes `_all` string or when no indices have been specified)
- `conflicts::String`: What to do when the delete by query hits version conflicts? (options: abort, proceed)
- `expand_wildcards::String`: Whether to expand wildcard expression to concrete indices that are open, closed or both. (options: open, closed, hidden, none, all)
- `lenient::Bool`: Specify whether format-based query failures (such as providing text to a numeric field) should be ignored
- `preference::String`: Specify the node or shard the operation should be performed on (default: random)
- `q::String`: Query in the Lucene query string syntax
- `routing::Union{String, Vector{String}}`: A comma-separated list of specific routing values
- `scroll::DateTime`: Specify how long a consistent view of the index should be maintained for scrolled search
- `search_type::String`: Search operation type (options: query_then_fetch, dfs_query_then_fetch)
- `search_timeout::DateTime`: Explicit timeout for each search request. Defaults to no timeout.
- `max_docs::Integer`: Maximum number of documents to process (default: all documents)
- `sort::Union{String, Vector{String}}`: A comma-separated list of <field>:<direction> pairs
- `terminate_after::Integer`: The maximum number of documents to collect for each shard, upon reaching which the query execution will terminate early.
- `stats::Union{String, Vector{String}}`: Specific 'tag' of the request for logging and statistical purposes
- `version::Bool`: Specify whether to return document version as part of a hit
- `request_cache::Bool`: Specify if request cache should be used for this request or not, defaults to index level setting
- `refresh::Bool`: Should the affected indexes be refreshed?
- `timeout::DateTime`: Time each individual bulk request should wait for shards that are unavailable.
- `wait_for_active_shards::String`: Sets the number of shard copies that must be active before proceeding with the delete by query operation. Defaults to 1, meaning the primary shard only. Set to `all` for all shard copies, otherwise set to any non-negative value less than or equal to the total number of copies for the shard (number of replicas + 1)
- `scroll_size::Integer`: Size on the scroll request powering the delete by query
- `wait_for_completion::Bool`: Should the request should block until the delete by query is complete.
- `requests_per_second::Integer`: The throttle for this request in sub-requests per second. -1 means no throttle.
- `slices::Union{Dict,String}`: The number of slices this task should be divided into. Defaults to 1, meaning the task isn't sliced into subtasks. Can be set to `auto`.
- `headers::Dict`: Custom HTTP headers
- `body::Dict`: The search definition using the Query DSL (*Required*)

See https://www.elastic.co/guide/en/elasticsearch/reference/current/docs-delete-by-query.html
"""
function delete_by_query(client::Client; body, index, headers=Dict(), auth_params=nothing, kwargs...)
  arguments = Dict(kwargs)

  method = HTTP_POST

  path = "/$(_listify(index))/_delete_by_query"
  params = process_params(arguments)

  Response(
    @mock perform_request(client, method, path; params=params, auth_params=auth_params, headers=headers, body=body)
  )
end